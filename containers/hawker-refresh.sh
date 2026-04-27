# hawker-refresh - pull latest config and reapply inside a running container
#
# Pulls from /mnt/hawker (host bind mount, no SSH needed), applies
# Home Manager, re-stows dotfiles, and refreshes the theme.

HAWKER_DIR="$HOME/hawker"

if [ ! -d "$HAWKER_DIR/.git" ]; then
    echo "Error: $HAWKER_DIR is not a git repo. Was the container started with hawker-container?" >&2
    exit 1
fi

# Pull latest from host's bind-mounted repo
echo "==> Pulling latest from host..."
if [ -d /mnt/hawker ]; then
    git -C "$HAWKER_DIR" fetch /mnt/hawker main
    git -C "$HAWKER_DIR" merge --ff-only FETCH_HEAD || true
else
    echo "Warning: /mnt/hawker not mounted, trying origin..."
    git -C "$HAWKER_DIR" pull --ff-only || true
fi

# Clean stale Nix store symlinks (from build-time homeDir)
find "$HOME/.config" -type l -lname '/nix/store/*' -delete 2>/dev/null || true
find "$HOME/.local" -type l -lname '/nix/store/*' -delete 2>/dev/null || true

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
