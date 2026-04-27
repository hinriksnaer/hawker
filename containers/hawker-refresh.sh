# hawker-refresh - update hawker config from inside a running container
#
# On first run: clones the hawker repo (replacing the Nix store copy
# that has no .git). On subsequent runs: pulls latest changes.
# Then re-runs bootstrap to re-stow dotfiles and reapplies the theme.

HAWKER_DIR="$HOME/hawker"

if [ ! -d "$HAWKER_DIR" ]; then
    echo "Error: $HAWKER_DIR not found" >&2
    exit 1
fi

# First run: the image copy has no .git (Nix strips it).
# Clone the real repo so we can pull/commit/push.
if [ ! -d "$HAWKER_DIR/.git" ]; then
    if [ -z "${HAWKER_REPO:-}" ]; then
        echo "Error: HAWKER_REPO not set — can't clone. Was the container started with hawker-container?" >&2
        exit 1
    fi
    echo "==> Cloning hawker repo (first run)..."
    tmp=$(mktemp -d)
    git clone "$HAWKER_REPO" "$tmp/hawker"
    # Replace the Nix store copy with the real clone
    rm -rf "$HAWKER_DIR"
    mv "$tmp/hawker" "$HAWKER_DIR"
    rm -rf "$tmp"
else
    echo "==> Pulling latest changes..."
    git -C "$HAWKER_DIR" pull --ff-only || true
fi

# Re-run bootstrap to re-stow dotfiles and apply config
echo "==> Running bootstrap..."
bash "$HAWKER_DIR/bootstrap.sh"

# Reapply current theme
if command -v hawker-theme-refresh &>/dev/null; then
    echo "==> Refreshing theme..."
    hawker-theme-refresh
fi

echo "==> Done"
