# hawker-container - manage NixOS dev containers

IMAGE_NAME="hawker-dev"
BASE_IMAGE="ghcr.io/skiffos/docker-nixos:latest"
FLAKE_REF="${HAWKER_FLAKE:-$HOME/hawker}"
REPO_DIR="$FLAKE_REF"

# ── Helpers ──

detect_runtime() {
    if command -v podman &>/dev/null; then
        echo podman
    elif command -v docker &>/dev/null; then
        echo docker
    else
        echo "Error: podman or docker required" >&2
        exit 1
    fi
}

enter_container() {
    local runtime
    runtime=$(detect_runtime)

    # If container is running, attach
    if [ "$($runtime inspect -f '{{.State.Running}}' "$IMAGE_NAME" 2>/dev/null)" = "true" ]; then
        exec $runtime exec -it "$IMAGE_NAME" /run/current-system/sw/bin/bash -c "export PATH=/run/current-system/sw/bin:\$PATH && cd /home/hawker && exec fish 2>/dev/null || exec bash"
    fi

    # If container exists but stopped, start and attach
    if $runtime container inspect "$IMAGE_NAME" &>/dev/null; then
        $runtime start "$IMAGE_NAME"
        sleep 2  # wait for systemd
        exec $runtime exec -it "$IMAGE_NAME" /run/current-system/sw/bin/bash -c "export PATH=/run/current-system/sw/bin:\$PATH && cd /home/hawker && exec fish 2>/dev/null || exec bash"
    fi

    # No container exists, create one
    start_container
}

start_container() {
    local runtime
    runtime=$(detect_runtime)

    $runtime rm -f "$IMAGE_NAME" 2>/dev/null || true

    local mounts=()
    local extra_args=()

    # Required for systemd inside the container
    mounts+=(--tmpfs /run)
    mounts+=(-v /sys/fs/cgroup:/sys/fs/cgroup:rw)
    extra_args+=(--cgroupns=host)

    # Mount hawker repo
    mounts+=(-v "${REPO_DIR}:/home/hawker/hawker")

    # GPU passthrough via NVIDIA CDI
    local gpus
    gpus=$(nix eval --raw "${FLAKE_REF}#nixosConfigurations.container.config.hawker.container.gpus" 2>/dev/null) || gpus="all"
    if [ "$gpus" != "none" ]; then
        if [ "$gpus" = "all" ]; then
            extra_args+=(--device nvidia.com/gpu=all)
        else
            for idx in ${gpus//,/ }; do
                extra_args+=(--device "nvidia.com/gpu=${idx}")
            done
        fi
    fi

    # Forward SSH agent
    if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "$SSH_AUTH_SOCK" ]; then
        extra_args+=(--security-opt label=disable)
        mounts+=(-v "$SSH_AUTH_SOCK:/tmp/ssh-agent.sock")
        extra_args+=(-e "SSH_AUTH_SOCK=/tmp/ssh-agent.sock")
    fi

    echo "==> Starting $IMAGE_NAME..."
    $runtime run -d \
        --name "$IMAGE_NAME" \
        --hostname "$IMAGE_NAME" \
        "${mounts[@]}" \
        "${extra_args[@]}" \
        "$BASE_IMAGE"

    echo "==> Waiting for systemd..."
    sleep 3

    echo "==> Applying NixOS config..."
    $runtime exec "$IMAGE_NAME" /run/current-system/sw/bin/bash -c \
        "export PATH=/run/current-system/sw/bin:\$PATH && cd /home/hawker/hawker && nixos-rebuild switch --flake .#container 2>&1"

    echo "==> Entering container..."
    exec $runtime exec -it "$IMAGE_NAME" /run/current-system/sw/bin/bash -c "export PATH=/run/current-system/sw/bin:\$PATH && cd /home/hawker && exec fish 2>/dev/null || exec bash"
}

# ── Commands ──

case "${1:-help}" in
    start)
        start_container
        ;;

    enter)
        if [ $# -ge 2 ]; then
            ssh -A -tt "$2" 'bash $HOME/hawker/scripts/hawker-container.sh enter-local'
        else
            enter_container
        fi
        ;;

    rebuild)
        # Rebuild NixOS config inside running container
        echo "==> Rebuilding NixOS config..."
        $(detect_runtime) exec "$IMAGE_NAME" /run/current-system/sw/bin/bash -c \
            "export PATH=/run/current-system/sw/bin:\$PATH && cd /home/hawker/hawker && git pull && nixos-rebuild switch --flake .#container 2>&1"
        ;;

    deploy)
        [ $# -lt 2 ] && echo "Usage: $0 deploy <host>" && exit 1
        echo "==> Syncing repo to $2..."
        rsync -a --delete --exclude='.git' --chmod=Du+rwx,Fu+rw \
            "$REPO_DIR/" "${2}:~/hawker/"
        ssh "$2" "cd ~/hawker && git init -q 2>/dev/null; git add -A 2>/dev/null"
        echo "==> Starting container on $2..."
        ssh -A -tt "$2" 'bash $HOME/hawker/scripts/hawker-container.sh start'
        ;;

    stop)
        if [ $# -ge 2 ]; then
            ssh "$2" "podman stop ${IMAGE_NAME} 2>/dev/null || docker stop ${IMAGE_NAME} 2>/dev/null"
        else
            $(detect_runtime) stop "${IMAGE_NAME}" 2>/dev/null || true
        fi
        ;;

    clean)
        if [ $# -ge 2 ]; then
            ssh "$2" "podman stop ${IMAGE_NAME} 2>/dev/null; podman rm ${IMAGE_NAME} 2>/dev/null; echo done"
        else
            $(detect_runtime) stop "${IMAGE_NAME}" 2>/dev/null || true
            $(detect_runtime) rm "${IMAGE_NAME}" 2>/dev/null || true
        fi
        ;;

    enter-local)
        enter_container
        ;;

    status)
        if [ $# -ge 2 ]; then
            ssh "$2" "podman ps -a --filter name=${IMAGE_NAME} 2>/dev/null || docker ps -a --filter name=${IMAGE_NAME}"
        else
            $(detect_runtime) ps -a --filter "name=${IMAGE_NAME}"
        fi
        ;;

    help|*)
        echo "hawker-container - NixOS dev containers"
        echo ""
        echo "Commands:"
        echo "  $0 start              Create and start a new container"
        echo "  $0 enter [host]       Enter running container (local or remote)"
        echo "  $0 rebuild            Rebuild NixOS config inside container"
        echo "  $0 deploy <host>      Sync repo + start container on remote"
        echo "  $0 stop [host]        Stop container"
        echo "  $0 clean [host]       Remove container"
        echo "  $0 status [host]      Show container status"
        ;;
esac
