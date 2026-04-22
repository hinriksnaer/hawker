# hawker-container - manage NixOS dev containers

IMAGE_NAME="hawker-dev"
IMAGE_TAG="docker-nixos:latest"
FLAKE_REF="${HAWKER_FLAKE:-$HOME/hawker}"
NIXOS_BIN=/run/current-system/sw/bin

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

    # Build and load the pinned image (local only -- deploy handles remote)
    if command -v nix &>/dev/null; then
        echo "==> Building container image..."
        nix build "${FLAKE_REF}#container"
        echo "==> Loading image..."
        $runtime load < "${FLAKE_REF}/result"
    else
        # On remote hosts without Nix, image must be pre-loaded via deploy
        if ! $runtime image exists "$IMAGE_TAG" 2>/dev/null; then
            echo "Error: image $IMAGE_TAG not found. Run 'hawker-container deploy <host>' from a Nix-enabled machine first." >&2
            exit 1
        fi
    fi

    # GPU passthrough: --privileged provides all /dev/nvidia* device nodes.
    # We mount only the host's driver runtime libs (libcuda.so, libnvidia-ml.so, etc.)
    # at /usr/lib64/host-nvidia. CUDA toolkit, cuDNN, NCCL are Nix-managed (cuda-dev.nix).
    local gpu_args=()
    local gpu_passthrough
    gpu_passthrough=$(nix eval --raw "${FLAKE_REF}#nixosConfigurations.container.config.hawker.container.gpuPassthrough" 2>/dev/null) || gpu_passthrough="none"
    if [ "$gpu_passthrough" != "none" ]; then
        # Mount host driver libs at /usr/lib64/host-nvidia (LD_LIBRARY_PATH already includes this)
        for lib_dir in /usr/lib64 /usr/lib/x86_64-linux-gnu; do
            if [ -f "${lib_dir}/libcuda.so" ] || [ -f "${lib_dir}/libcuda.so.1" ]; then
                gpu_args+=(-v "${lib_dir}:/usr/lib64/host-nvidia:ro")
                break
            fi
        done

        # Mount nvidia-smi
        local nvidia_smi
        nvidia_smi=$(command -v nvidia-smi 2>/dev/null) || true
        if [ -n "$nvidia_smi" ]; then
            gpu_args+=(-v "$(readlink -f "$nvidia_smi"):/usr/bin/nvidia-smi:ro")
        fi

        echo "==> GPU passthrough: $gpu_passthrough"
    fi

    echo "==> Starting $IMAGE_NAME..."
    $runtime run -d \
        --name "$IMAGE_NAME" \
        --hostname "$IMAGE_NAME" \
        --privileged \
        --tmpfs /run \
        -v "${FLAKE_REF}:/config" \
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

    # Build the image locally (requires Nix)
    echo "==> Building container image locally..."
    nix build "${FLAKE_REF}#container"

    # Sync repo to remote (for /config bind mount)
    echo "==> Syncing repo to ${host}:~/hawker..."
    rsync -a --delete --exclude='.git' --exclude='result' --chmod=Du+rwx,Fu+rw \
        "${FLAKE_REF}/" "${host}:~/hawker/"
    ssh "$host" "cd ~/hawker && git init -q 2>/dev/null; git add -A 2>/dev/null"

    # Copy and load the image on the remote
    echo "==> Loading container image on ${host}..."
    ssh "$host" "command -v podman >/dev/null && echo podman || echo docker" | {
        read -r remote_runtime
        cat "${FLAKE_REF}/result" | ssh "$host" "${remote_runtime} load"
    }

    # Start the container on the remote
    echo "==> Starting container on ${host}..."
    ssh -A -tt "$host" "cd ~/hawker && bash scripts/hawker-container.sh start"
}

# ── Commands ──

case "${1:-help}" in
    start)
        start_container
        ;;

    enter)
        if [ $# -ge 2 ]; then
            ssh -A -tt "$2" "bash ~/hawker/scripts/hawker-container.sh enter"
        else
            enter_container
        fi
        ;;

    rebuild)
        if [ $# -ge 2 ]; then
            ssh -A -tt "$2" "bash ~/hawker/scripts/hawker-container.sh rebuild"
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
        echo "  $0 rebuild [host]     Rebuild NixOS config inside container"
        echo "  $0 deploy <host>      Build image locally, sync + start on remote"
        echo "  $0 stop [host]        Stop container"
        echo "  $0 clean [host]       Stop and remove container"
        echo "  $0 status [host]      Show container status"
        ;;
esac
