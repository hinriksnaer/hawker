# hawker-refresh - update hawker config from inside a running container
#
# Pulls latest changes, re-runs bootstrap to re-stow dotfiles,
# and reapplies the current theme.

HAWKER_DIR="$HOME/hawker"

if [ ! -d "$HAWKER_DIR" ]; then
    echo "Error: $HAWKER_DIR not found" >&2
    exit 1
fi

# Pull latest changes if it's a git repo
if [ -d "$HAWKER_DIR/.git" ]; then
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
