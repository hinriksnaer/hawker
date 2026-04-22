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

    # Build and load the pinned image from the flake
    echo "==> Building container image..."
    nix build "${FLAKE_REF}#container"
    echo "==> Loading image..."
    $runtime load < "${FLAKE_REF}/result"

    echo "==> Starting $IMAGE_NAME..."
    $runtime run -d \
        --name "$IMAGE_NAME" \
        --hostname "$IMAGE_NAME" \
        --privileged \
        --tmpfs /run \
        -v "${FLAKE_REF}:/config" \
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
    exec $runtime exec -it --user dev -w /home/dev "$IMAGE_NAME" "$NIXOS_BIN/bash" -l
}

enter_container() {
    local runtime
    runtime=$(detect_runtime)

    if [ "$($runtime inspect -f '{{.State.Running}}' "$IMAGE_NAME" 2>/dev/null)" = "true" ]; then
        exec $runtime exec -it --user dev -w /home/dev "$IMAGE_NAME" "$NIXOS_BIN/bash" -l
    fi

    if $runtime container inspect "$IMAGE_NAME" &>/dev/null; then
        $runtime start "$IMAGE_NAME"
        wait_for_systemd "$runtime"
        exec $runtime exec -it --user dev -w /home/dev "$IMAGE_NAME" "$NIXOS_BIN/bash" -l
    fi

    start_container
}

# ── Commands ──

case "${1:-help}" in
    start)
        start_container
        ;;

    enter)
        enter_container
        ;;

    rebuild)
        echo "==> Rebuilding NixOS config inside container..."
        $(detect_runtime) exec -it --user dev -w /home/dev "$IMAGE_NAME" \
            "$NIXOS_BIN/bash" -c "export PATH=$NIXOS_BIN:\$PATH && sudo nixos-rebuild switch --flake /build#container"
        ;;

    stop)
        $(detect_runtime) stop "${IMAGE_NAME}" 2>/dev/null || true
        ;;

    clean)
        $(detect_runtime) stop "${IMAGE_NAME}" 2>/dev/null || true
        $(detect_runtime) rm "${IMAGE_NAME}" 2>/dev/null || true
        ;;

    status)
        $(detect_runtime) ps -a --filter "name=${IMAGE_NAME}"
        ;;

    help|*)
        echo "hawker-container - NixOS dev containers"
        echo ""
        echo "Commands:"
        echo "  $0 start       Build image, create and start container"
        echo "  $0 enter       Enter running container as dev"
        echo "  $0 rebuild     Rebuild NixOS config inside container"
        echo "  $0 stop        Stop container"
        echo "  $0 clean       Stop and remove container"
        echo "  $0 status      Show container status"
        ;;
esac
