# hawker-container - manage GPU dev containers

IMAGE_NAME="hawker-dev"
FLAKE_REF="${HAWKER_FLAKE:-$HOME/hawker}"

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

NIX_CMD=""
if command -v nix &>/dev/null; then
    NIX_CMD="nix"
elif [ -x "$HOME/nix-portable" ]; then
    NIX_CMD="$HOME/nix-portable nix"
fi

# ── Container lifecycle ──

start_container() {
    local runtime
    runtime=$(detect_runtime)

    $runtime rm -f "$IMAGE_NAME" 2>/dev/null || true

    # Build and stream the layered image
    echo "==> Building container image..."
    local stream_script
    stream_script=$($NIX_CMD build --print-out-paths --no-link "${FLAKE_REF}#container")
    echo "==> Loading image..."
    "$stream_script" | $runtime load

    # GPU passthrough via NVIDIA CDI
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

    # SSH agent forwarding
    local ssh_args=()
    if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "$SSH_AUTH_SOCK" ]; then
        ssh_args+=(-v "$SSH_AUTH_SOCK:/tmp/ssh-agent.sock" -e "SSH_AUTH_SOCK=/tmp/ssh-agent.sock")
    fi

    # Persistent storage
    local user
    user=$($NIX_CMD eval --raw "${FLAKE_REF}#nixosConfigurations.container.config.hawker.username" 2>/dev/null) || user="dev"

    local repo_url
    repo_url=$(git -C "${FLAKE_REF}" remote get-url origin 2>/dev/null) || repo_url=""

    local storage
    storage=$($NIX_CMD eval --raw "${FLAKE_REF}#nixosConfigurations.container.config.hawker.container.storagePath" 2>/dev/null) || storage=""

    local vol_args=()
    if [ -n "$storage" ]; then
        mkdir -p "$storage"/{hawker,repos,ccache,vscode,config,nix}
        vol_args=(
            -v "$storage/hawker:/home/${user}/hawker"
            -v "$storage/repos:/home/${user}/repos"
            -v "$storage/ccache:/home/${user}/.cache/ccache"
            -v "$storage/vscode:/home/${user}/.vscode-server"
            -v "$storage/config:/home/${user}/.config"
            -v "$storage/nix:/nix"
        )
    else
        vol_args=(
            -v "${IMAGE_NAME}-hawker:/home/${user}/hawker"
            -v "${IMAGE_NAME}-repos:/home/${user}/repos"
            -v "${IMAGE_NAME}-ccache:/home/${user}/.cache/ccache"
            -v "${IMAGE_NAME}-vscode:/home/${user}/.vscode-server"
            -v "${IMAGE_NAME}-config:/home/${user}/.config"
            -v "${IMAGE_NAME}-nix:/nix"
        )
    fi

    echo "==> Starting $IMAGE_NAME..."
    $runtime run -it \
        --name "$IMAGE_NAME" \
        --hostname "$IMAGE_NAME" \
        -e "HAWKER_REPO=${repo_url}" \
        -v "${FLAKE_REF}:/mnt/hawker:ro" \
        "${vol_args[@]}" \
        "${ssh_args[@]}" \
        "${gpu_args[@]}" \
        "$IMAGE_NAME:latest"
}

enter_container() {
    local runtime
    runtime=$(detect_runtime)

    if $runtime container inspect "$IMAGE_NAME" &>/dev/null; then
        if [ "$($runtime inspect -f '{{.State.Running}}' "$IMAGE_NAME" 2>/dev/null)" = "true" ]; then
            exec $runtime exec -it --user dev "$IMAGE_NAME" fish
        fi
        $runtime start -ai "$IMAGE_NAME"
    else
        start_container
    fi
}

deploy_to_host() {
    local host=$1

    local remote_url
    remote_url=$(git -C "${FLAKE_REF}" remote get-url origin 2>/dev/null) || {
        echo "Error: cannot determine git remote URL from ${FLAKE_REF}" >&2
        exit 1
    }

    echo "==> Syncing repo to ${host}:~/hawker..."
    ssh -A "$host" "
        if [ -d ~/hawker/.git ]; then
            cd ~/hawker && git pull --ff-only
        else
            git clone '${remote_url}' ~/hawker
        fi
    "

    echo "==> Starting container on ${host}..."
    ssh -A -tt "$host" "cd ~/hawker && bash containers/hawker-container.sh enter"
}

# ── Commands ──

case "${1:-help}" in
    start)
        start_container
        ;;

    enter)
        if [ $# -ge 2 ]; then
            ssh -A -tt "$2" 'bash $HOME/hawker/containers/hawker-container.sh enter'
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
        runtime=$(detect_runtime)
        $runtime stop "${IMAGE_NAME}" 2>/dev/null || true
        $runtime rm "${IMAGE_NAME}" 2>/dev/null || true
        start_container
        ;;

    deploy)
        [ $# -lt 2 ] && echo "Usage: $0 deploy <host>" && exit 1
        deploy_to_host "$2"
        ;;

    code)
        if ! command -v code &>/dev/null; then
            # On a remote host without VSCode, print the URI for the local machine
            user=$($NIX_CMD eval --raw "${FLAKE_REF}#nixosConfigurations.container.config.hawker.username" 2>/dev/null) || user="dev"
            hex=$(printf '%s' "$IMAGE_NAME" | xxd -p | tr -d '\n')
            echo "VSCode is not installed on this host."
            echo "From your local machine, run:"
            echo "  code --folder-uri \"vscode-remote://attached-container+${hex}/home/${user}\""
            echo ""
            echo "Or use VSCode's command palette: Dev Containers > Attach to Running Container"
        else
            user=$($NIX_CMD eval --raw "${FLAKE_REF}#nixosConfigurations.container.config.hawker.username" 2>/dev/null) || user="dev"
            hex=$(printf '%s' "$IMAGE_NAME" | xxd -p | tr -d '\n')
            echo "==> Opening VSCode attached to $IMAGE_NAME..."
            code --folder-uri "vscode-remote://attached-container+${hex}/home/${user}"
        fi
        ;;

    stop)
        if [ $# -ge 2 ]; then
            ssh "$2" "podman stop ${IMAGE_NAME} 2>/dev/null || docker stop ${IMAGE_NAME} 2>/dev/null"
        else
            $(detect_runtime) stop "${IMAGE_NAME}" 2>/dev/null || true
        fi
        ;;

    reset)
        runtime=$(detect_runtime)
        storage=$($NIX_CMD eval --raw "${FLAKE_REF}#nixosConfigurations.container.config.hawker.container.storagePath" 2>/dev/null) || storage=""
        if [ $# -ge 2 ]; then
            echo "==> Resetting session state for ${IMAGE_NAME} on $2 (keeps repos + ccache)..."
            ssh "$2" "rt=\$(command -v podman || command -v docker); \$rt stop ${IMAGE_NAME} 2>/dev/null; \$rt rm ${IMAGE_NAME} 2>/dev/null; \$rt volume rm ${IMAGE_NAME}-hawker ${IMAGE_NAME}-vscode ${IMAGE_NAME}-config ${IMAGE_NAME}-nix 2>/dev/null; echo done"
        elif [ -n "$storage" ]; then
            echo "==> Resetting session state for $IMAGE_NAME (keeps repos + ccache)..."
            $runtime stop "$IMAGE_NAME" 2>/dev/null || true
            $runtime rm "$IMAGE_NAME" 2>/dev/null || true
            rm -rf "$storage"/{hawker,vscode,config,nix}
            echo "done — run 'hawker-container start' to recreate"
        else
            echo "==> Resetting session state for $IMAGE_NAME (keeps repos + ccache)..."
            $runtime stop "$IMAGE_NAME" 2>/dev/null || true
            $runtime rm "$IMAGE_NAME" 2>/dev/null || true
            $runtime volume rm "${IMAGE_NAME}-hawker" "${IMAGE_NAME}-vscode" "${IMAGE_NAME}-config" "${IMAGE_NAME}-nix" 2>/dev/null || true
            echo "done — run 'hawker-container start' to recreate"
        fi
        ;;

    clean)
        runtime=$(detect_runtime)
        storage=$($NIX_CMD eval --raw "${FLAKE_REF}#nixosConfigurations.container.config.hawker.container.storagePath" 2>/dev/null) || storage=""
        if [ $# -ge 2 ]; then
            echo "==> Cleaning ${IMAGE_NAME} on $2..."
            ssh "$2" "rt=\$(command -v podman || command -v docker); \$rt stop ${IMAGE_NAME} 2>/dev/null; \$rt rm ${IMAGE_NAME} 2>/dev/null; \$rt volume rm ${IMAGE_NAME}-hawker ${IMAGE_NAME}-repos ${IMAGE_NAME}-ccache ${IMAGE_NAME}-vscode ${IMAGE_NAME}-config ${IMAGE_NAME}-nix 2>/dev/null; \$rt rmi ${IMAGE_NAME}:latest 2>/dev/null; echo done"
        elif [ -n "$storage" ]; then
            echo "==> Cleaning local $IMAGE_NAME..."
            $runtime stop "$IMAGE_NAME" 2>/dev/null || true
            $runtime rm "$IMAGE_NAME" 2>/dev/null || true
            rm -rf "$storage"/{hawker,repos,ccache,vscode,config,nix}
            $runtime rmi "$IMAGE_NAME:latest" 2>/dev/null || true
            echo "done"
        else
            echo "==> Cleaning local $IMAGE_NAME..."
            $runtime stop "$IMAGE_NAME" 2>/dev/null || true
            $runtime rm "$IMAGE_NAME" 2>/dev/null || true
            $runtime volume rm "${IMAGE_NAME}-hawker" "${IMAGE_NAME}-repos" "${IMAGE_NAME}-ccache" "${IMAGE_NAME}-vscode" "${IMAGE_NAME}-config" "${IMAGE_NAME}-nix" 2>/dev/null || true
            $runtime rmi "$IMAGE_NAME:latest" 2>/dev/null || true
            echo "done"
        fi
        ;;

    status)
        if [ $# -ge 2 ]; then
            ssh "$2" "rt=\$(command -v podman || command -v docker); \$rt inspect -f '{{.State.Status}}' ${IMAGE_NAME} 2>/dev/null || echo 'not found'"
        else
            $(detect_runtime) inspect -f '{{.State.Status}}' "$IMAGE_NAME" 2>/dev/null || echo "not found"
        fi
        ;;

    help|*)
        echo "hawker-container - manage GPU dev containers"
        echo ""
        echo "Commands:"
        echo "  $0 start              Build image + start container"
        echo "  $0 enter [host]       Enter container (local or remote)"
        echo "  $0 update             Pull latest, upgrade CLI, rebuild container"
        echo "  $0 deploy <host>      Clone/pull repo on remote + start container"
        echo "  $0 code               Open VSCode attached to container"
        echo "  $0 stop [host]        Stop container"
        echo "  $0 reset [host]       Reset session state (keeps repos, ccache, image)"
        echo "  $0 clean [host]       Remove container, image, and volumes"
        echo "  $0 status [host]      Show container status"
        echo ""
        echo "Inside the container, use 'hawker-build' to build project sources."
        ;;
esac
