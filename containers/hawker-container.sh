# hawker-container - manage NixOS dev containers

IMAGE_NAME="hawker-dev"
IMAGE_TAG="docker-nixos:latest"
FLAKE_REF="${HAWKER_FLAKE:-$HOME/hawker}"
NIXOS_BIN=/run/current-system/sw/bin

# Find nix binary (supports nix-portable on hosts without /nix)
NIX_CMD=""
if command -v nix &>/dev/null; then
    NIX_CMD="nix"
elif [ -x "$HOME/nix-portable" ]; then
    NIX_CMD="$HOME/nix-portable nix"
fi

# ── Helpers ──

wait_for_systemd() {
    local runtime=$1
    echo "==> Waiting for systemd..."
    for _ in $(seq 1 30); do
        local status
        status=$($runtime exec "$IMAGE_NAME" "$NIXOS_BIN/systemctl" is-system-running 2>/dev/null || true)
        if [ "$status" = "running" ] || [ "$status" = "degraded" ]; then
            return 0
        fi
        sleep 1
    done
    echo "  (systemd not fully ready, proceeding anyway)"
}

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

start_container() {
    local runtime
    runtime=$(detect_runtime)

    $runtime rm -f "$IMAGE_NAME" 2>/dev/null || true

    # Build and load the pinned docker-nixos image from the flake
    echo "==> Building container image..."
    local image_path
    image_path=$($NIX_CMD build --print-out-paths --no-link "${FLAKE_REF}#container")
    echo "==> Loading image..."
    # Try direct path (works on real Nix), then nix-portable store, then existing image
    if ! $runtime load < "$image_path" 2>/dev/null; then
        local np_path="${image_path/\/nix\/store/$HOME/.nix-portable/nix/store}"
        if [ -f "$np_path" ]; then
            $runtime load < "$np_path"
        elif $runtime image exists "$IMAGE_TAG" 2>/dev/null; then
            echo "  (using previously loaded image)"
        else
            echo "Error: cannot load image. Use 'hawker-container deploy <host>' to stream it." >&2
            exit 1
        fi
    fi

    # GPU passthrough via NVIDIA CDI.
    # CDI mounts only NVIDIA driver libs (libcuda, libnvidia-ml, nvidia-smi, etc.)
    # at standard paths (/usr/lib64, /usr/bin). CUDA toolkit, cuDNN, NCCL are
    # Nix-managed inside the container (cuda-dev.nix).
    local gpu_args=()
    local gpu_passthrough
    gpu_passthrough=$($NIX_CMD eval --raw "${FLAKE_REF}#nixosConfigurations.container.config.hawker.container.gpuPassthrough" 2>/dev/null) || gpu_passthrough="none"
    if [ "$gpu_passthrough" != "none" ]; then
        if [ "$gpu_passthrough" = "all" ]; then
            gpu_args+=(--device nvidia.com/gpu=all)
        else
            for idx in ${gpu_passthrough//,/ }; do
                gpu_args+=(--device "nvidia.com/gpu=${idx}")
            done
        fi
        echo "==> GPU passthrough: $gpu_passthrough"
    fi

    # Ensure persistent directories exist on host
    mkdir -p "$HOME/repos" "$HOME/.cache/ccache" "$HOME/nix-container"

    echo "==> Starting $IMAGE_NAME..."
    $runtime run -d \
        --name "$IMAGE_NAME" \
        --hostname "$IMAGE_NAME" \
        --cap-add SYS_ADMIN \
        --tmpfs /run \
        -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
        --cgroupns=host \
        -v "${FLAKE_REF}:/config" \
        -v "$HOME/nix-container:/nix" \
        -v "$HOME/repos:/home/dev/repos" \
        -v "$HOME/.cache/ccache:/home/dev/.cache/ccache" \
        -v "$HOME/.ssh:/home/dev/.ssh:ro" \
        "${gpu_args[@]}" \
        "$IMAGE_TAG"

    wait_for_systemd "$runtime"

    # Stream nixos-rebuild progress from create-switch-script
    echo "==> Applying NixOS config (create-switch-script)..."
    if $runtime exec "$IMAGE_NAME" "$NIXOS_BIN/bash" -c \
        "export PATH=$NIXOS_BIN:\$PATH
         journalctl -u create-switch-script -f -n 0 &
         JPID=\$!
         while systemctl is-active create-switch-script >/dev/null 2>&1; do sleep 1; done
         sleep 1; kill \$JPID 2>/dev/null
         ! systemctl is-failed create-switch-script >/dev/null 2>&1"; then
        echo "==> NixOS config applied."
    else
        echo "==> create-switch-script failed."
    fi

    echo "==> Container ready."
    exec $runtime exec -it --user dev -w /home/dev "$IMAGE_NAME" "$NIXOS_BIN/fish" -l
}

enter_container() {
    local runtime
    runtime=$(detect_runtime)

    if [ "$($runtime inspect -f '{{.State.Running}}' "$IMAGE_NAME" 2>/dev/null)" = "true" ]; then
        exec $runtime exec -it --user dev -w /home/dev "$IMAGE_NAME" "$NIXOS_BIN/fish" -l
    fi

    if $runtime container inspect "$IMAGE_NAME" &>/dev/null; then
        $runtime start "$IMAGE_NAME"
        wait_for_systemd "$runtime"
        exec $runtime exec -it --user dev -w /home/dev "$IMAGE_NAME" "$NIXOS_BIN/fish" -l
    fi

    start_container
}

deploy_to_host() {
    local host=$1

    # Get the remote URL from local git config
    local remote_url
    remote_url=$(git -C "${FLAKE_REF}" remote get-url origin 2>/dev/null) || {
        echo "Error: cannot determine git remote URL from ${FLAKE_REF}" >&2
        exit 1
    }

    # Clone or pull the repo on the remote host (uses SSH agent forwarding)
    echo "==> Syncing repo to ${host}:~/hawker..."
    ssh -A "$host" "
        if [ -d ~/hawker/.git ]; then
            cd ~/hawker && git pull --ff-only
        else
            git clone '${remote_url}' ~/hawker
        fi
    "

    # Start the container on the remote (nix build + podman run happens there)
    echo "==> Starting container on ${host}..."
    ssh -A -tt "$host" "cd ~/hawker && bash containers/hawker-container.sh start"
}

# ── Commands ──

case "${1:-help}" in
    start)
        start_container
        ;;

    enter)
        if [ $# -ge 2 ]; then
            ssh -A -tt "$2" "bash ~/hawker/containers/hawker-container.sh enter"
        else
            enter_container
        fi
        ;;

    update)
        echo "==> Pulling latest changes..."
        git -C "${FLAKE_REF}" pull --ff-only

        echo "==> Upgrading hawker-container CLI..."
        $NIX_CMD profile upgrade hawker-container 2>/dev/null || true

        echo "==> Rebuilding container..."
        $(detect_runtime) stop "${IMAGE_NAME}" 2>/dev/null || true
        $(detect_runtime) rm "${IMAGE_NAME}" 2>/dev/null || true
        start_container
        ;;

    rebuild)
        if [ $# -ge 2 ]; then
            ssh -A -tt "$2" "bash ~/hawker/containers/hawker-container.sh rebuild"
        else
            echo "==> Rebuilding NixOS config inside container..."
            $(detect_runtime) exec -it --user dev -w /home/dev "$IMAGE_NAME" \
                "$NIXOS_BIN/bash" -c "export PATH=$NIXOS_BIN:\$PATH && sudo nixos-rebuild switch --flake /build#container"
        fi
        ;;

    deploy)
        [ $# -lt 2 ] && echo "Usage: $0 deploy <host>" && exit 1
        deploy_to_host "$2"
        ;;

    stop)
        if [ $# -ge 2 ]; then
            ssh "$2" "podman stop ${IMAGE_NAME} 2>/dev/null || docker stop ${IMAGE_NAME} 2>/dev/null || true"
        else
            $(detect_runtime) stop "${IMAGE_NAME}" 2>/dev/null || true
        fi
        ;;

    clean)
        if [ $# -ge 2 ]; then
            ssh "$2" "podman stop ${IMAGE_NAME} 2>/dev/null; podman rm ${IMAGE_NAME} 2>/dev/null; docker stop ${IMAGE_NAME} 2>/dev/null; docker rm ${IMAGE_NAME} 2>/dev/null; echo done"
        else
            $(detect_runtime) stop "${IMAGE_NAME}" 2>/dev/null || true
            $(detect_runtime) rm "${IMAGE_NAME}" 2>/dev/null || true
        fi
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
        echo "  $0 start              Build image, create and start container"
        echo "  $0 enter [host]       Enter running container (local or remote)"
        echo "  $0 update             Pull latest, upgrade CLI, rebuild container"
        echo "  $0 rebuild [host]     Rebuild NixOS config inside container (no restart)"
        echo "  $0 deploy <host>      Clone/pull repo on remote + start container"
        echo "  $0 stop [host]        Stop container"
        echo "  $0 clean [host]       Stop and remove container"
        echo "  $0 status [host]      Show container status"
        echo ""
        echo "Inside the container, use 'hawker-build' to build project sources."
        ;;
esac
