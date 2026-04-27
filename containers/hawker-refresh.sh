# hawker-refresh - pull latest config and reapply inside a running container
#
# The initial clone is handled by the container entrypoint (from /mnt/hawker).
# This script pulls updates, applies Home Manager, re-stows dotfiles, and
# refreshes the theme.

HAWKER_DIR="$HOME/hawker"

if [ ! -d "$HAWKER_DIR/.git" ]; then
    echo "Error: $HAWKER_DIR is not a git repo. Was the container started with hawker-container?" >&2
    exit 1
fi

echo "==> Pulling latest changes..."
git -C "$HAWKER_DIR" pull --ff-only || true

# Apply Home Manager configuration
if command -v home-manager &>/dev/null; then
    echo "==> Applying Home Manager configuration..."
    home-manager switch --flake "$HAWKER_DIR#dev" 2>&1 || true
fi

# Re-run bootstrap to re-stow dotfiles
echo "==> Running bootstrap..."
bash "$HAWKER_DIR/bootstrap.sh"

# Reapply current theme
if command -v hawker-theme-refresh &>/dev/null; then
    echo "==> Refreshing theme..."
    hawker-theme-refresh
fi

echo "==> Done"
