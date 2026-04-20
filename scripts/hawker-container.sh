# hawker-container - manage dev environments locally and on remote hosts

IMAGE_NAME="hawker-dev"
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


push_to() {
    local host="$1"

    echo "==> Syncing repo to $host..."
    rsync -a --delete --exclude='.git' --chmod=Du+rwx,Fu+rw \
        "$REPO_DIR/" "${host}:~/hawker/"

    # Flakes require a git repo. Init one on the remote and stage all files
    # so Nix can see them (doesn't need commits, just git add).
    ssh "$host" "cd ~/hawker && git init -q 2>/dev/null; git add -A 2>/dev/null" 

    echo "==> Building container on $host..."
    ssh "$host" "cd ~/hawker && nix build .#container --no-link --print-build-logs"

    local stream_script
    stream_script=$(ssh "$host" "cd ~/hawker && nix build .#container --no-link --print-out-paths")

    echo "==> Loading image on $host..."
    ssh "$host" "$stream_script | podman load 2>/dev/null || $stream_script | docker load"
}

enter_container() {
    local runtime
    runtime=$(detect_runtime)

    # If container is running, attach to it
    if [ "$($runtime inspect -f '{{.State.Running}}' "$IMAGE_NAME" 2>/dev/null)" = "true" ]; then
        exec $runtime exec -it "$IMAGE_NAME" fish
    fi

    # If container exists but is stopped, start it and attach
    if $runtime container inspect "$IMAGE_NAME" &>/dev/null; then
        $runtime start "$IMAGE_NAME"
        exec $runtime exec -it "$IMAGE_NAME" fish
    fi

    # No container exists, create one
    start_container
}

start_container() {
    local runtime
    runtime=$(detect_runtime)

    $runtime rm -f "$IMAGE_NAME" 2>/dev/null || true

    local mounts=()
    local env_args=(-e "TERM=xterm-256color")
    local extra_args=()

    # GPU passthrough via NVIDIA CDI.
    # CDI handles device files AND driver libraries when properly configured.
    # Regenerate CDI spec: sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
    # Read GPU config from the flake (HAWKER_GPUS is inside the image, not on the host).
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
        # Don't set CUDA_VISIBLE_DEVICES -- CDI handles device isolation.
        # When CDI passes GPU 4, it appears as device 0 inside the container,
        # so CUDA_VISIBLE_DEVICES=4 would hide it.
    fi

    # Forward SSH agent socket
    if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "$SSH_AUTH_SOCK" ]; then
        mounts+=(-v "$SSH_AUTH_SOCK:/tmp/ssh-agent.sock")
        env_args+=(-e "SSH_AUTH_SOCK=/tmp/ssh-agent.sock")
    fi

    # Persistent volumes
    mounts+=(-v "${IMAGE_NAME}-repos:/home/${HAWKER_USER:-$USER}/repos")
    mounts+=(-v "${IMAGE_NAME}-ccache:/home/${HAWKER_USER:-$USER}/.cache/ccache")
    mounts+=(-v "${IMAGE_NAME}-gcloud:/home/${HAWKER_USER:-$USER}/.config/gcloud")
    mounts+=(-v "${IMAGE_NAME}-hawker:/home/${HAWKER_USER:-$USER}/hawker")
    mounts+=(-v "${IMAGE_NAME}-nix:/home/${HAWKER_USER:-$USER}/.local/state/nix")

    # Hawker repo URL for cloning inside the container
    local hawker_repo
    hawker_repo=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null) || hawker_repo="https://github.com/hinriksnaer/hawker.git"
    env_args+=(-e "HAWKER_REPO=${hawker_repo}")

    exec $runtime run -it \
        --name "$IMAGE_NAME" \
        --hostname "$IMAGE_NAME" \
        "${mounts[@]}" \
        "${env_args[@]}" \
        "${extra_args[@]}" \
        "$IMAGE_NAME:latest" \
        bash ~/hawker/scripts/container-entry.sh
}

# ── Commands ──

case "${1:-help}" in
    deploy)
        [ $# -lt 2 ] && echo "Usage: $0 deploy <host>" && exit 1
        push_to "$2"
        echo "==> Entering container..."
        ssh -A -tt "$2" 'bash $HOME/hawker/scripts/hawker-container.sh start-local'
        ;;

    enter)
        if [ $# -ge 2 ]; then
            ssh -A -tt "$2" 'bash $HOME/hawker/scripts/hawker-container.sh enter-local'
        else
            enter_container
        fi
        ;;

    push)
        [ $# -lt 2 ] && echo "Usage: $0 push <host>" && exit 1
        push_to "$2"
        echo "==> Done. Enter with: $0 enter $2"
        ;;

    run)
        # Local: build, load, run
        stream_script=$(nix build "${FLAKE_REF}#container" --no-link --print-out-paths)
        echo "==> Loading $IMAGE_NAME..."
        "$stream_script" | $(detect_runtime) load
        echo "==> Starting $IMAGE_NAME..."
        start_container
        ;;

    start-local)
        start_container
        ;;

    enter-local)
        enter_container
        ;;

    status)
        if [ $# -ge 2 ]; then
            echo "==> Checking $2..."
            ssh "$2" "nix --version 2>/dev/null && echo 'Nix: available' || echo 'Nix: not installed'"
            ssh "$2" "podman --version 2>/dev/null || docker --version 2>/dev/null || echo 'No container runtime'"
            ssh "$2" "nvidia-smi --query-gpu=gpu_name --format=csv,noheader 2>/dev/null || echo 'No GPUs detected'"
        else
            nix --version
            podman --version 2>/dev/null || docker --version 2>/dev/null || echo 'No container runtime'
            nvidia-smi --query-gpu=gpu_name --format=csv,noheader 2>/dev/null || echo 'No GPUs detected'
        fi
        ;;

    stop)
        if [ $# -ge 2 ]; then
            ssh "$2" "podman stop ${IMAGE_NAME} 2>/dev/null; podman rm ${IMAGE_NAME} 2>/dev/null || docker stop ${IMAGE_NAME} 2>/dev/null; docker rm ${IMAGE_NAME} 2>/dev/null"
        else
            $(detect_runtime) stop "${IMAGE_NAME}" 2>/dev/null || true
            $(detect_runtime) rm "${IMAGE_NAME}" 2>/dev/null || true
        fi
        ;;

    clean)
        # Remove persistent volumes (repos, ccache, setup markers)
        if [ $# -ge 2 ]; then
            echo "==> Cleaning ${IMAGE_NAME} on $2..."
            # shellcheck disable=SC2029
            ssh "$2" "podman stop ${IMAGE_NAME} 2>/dev/null; podman rm ${IMAGE_NAME} 2>/dev/null; podman volume rm ${IMAGE_NAME}-repos ${IMAGE_NAME}-ccache ${IMAGE_NAME}-gcloud ${IMAGE_NAME}-hawker ${IMAGE_NAME}-nix 2>/dev/null; podman rmi ${IMAGE_NAME}:latest 2>/dev/null; echo done"
        else
            echo "==> Cleaning local $IMAGE_NAME..."
            $(detect_runtime) stop "$IMAGE_NAME" 2>/dev/null || true
            $(detect_runtime) rm "$IMAGE_NAME" 2>/dev/null || true
            $(detect_runtime) volume rm "${IMAGE_NAME}-repos" "${IMAGE_NAME}-ccache" "${IMAGE_NAME}-gcloud" "${IMAGE_NAME}-hawker" "${IMAGE_NAME}-nix" 2>/dev/null || true
            $(detect_runtime) rmi "$IMAGE_NAME:latest" 2>/dev/null || true
            echo "done"
        fi
        ;;

    help|*)
        echo "hawker-container - manage dev environments"
        echo ""
        echo "Commands:"
        echo "  $0 deploy <host>       Build + push + enter container on remote"
        echo "  $0 enter [host]        Enter container (local or remote)"
        echo "  $0 push <host>         Build + push without entering"
        echo "  $0 run                 Build + run container locally"
        echo "  $0 status [host]       Check Nix/GPU availability"
        echo "  $0 stop [host]         Stop running container"
        echo "  $0 clean [host]        Remove container, image, and repos volume"
        echo ""
        echo "Examples:"
        echo "  $0 deploy my-gpu-host   Deploy to remote host"
        echo "  $0 enter my-gpu-host   Enter existing container"
        echo "  $0 clean my-gpu-host   Fresh start (removes repos/venvs)"
        ;;
esac
