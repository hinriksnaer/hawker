#!/usr/bin/env bash
# Bootstrap: deploy dotfiles via stow and create runtime directories.
# Everything else (git config, btop config, opencode themes, tmux plugins,
# yazi plugins, dark mode) is handled by NixOS modules and activation scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
HAWKER_DATA="$HOME/.local/share/hawker"

# ── Stow dotfiles ──
echo "==> Deploying dotfiles via stow (--no-folding)..."
for dir in "$DOTFILES_DIR"/*/; do
    module=$(basename "$dir")

    # Skip: themes (symlinked separately), btop (NixOS activation),
    # neovim/fish (managed by Home Manager)
    if [ "$module" = "themes" ] || [ "$module" = "btop" ] || [ "$module" = "neovim" ] || [ "$module" = "fish" ]; then
        continue
    fi

    echo "  stow: $module"
    stow -d "$DOTFILES_DIR" -t "$HOME" --no-folding --adopt --restow "$module" 2>&1 | grep -v "BUG" || true
done

# ── Theme directory ──
echo "==> Deploying themes to $HAWKER_DATA/themes/..."
mkdir -p "$HAWKER_DATA"
if [ -L "$HAWKER_DATA/themes" ]; then
    rm "$HAWKER_DATA/themes"
fi
ln -snf "$DOTFILES_DIR/themes" "$HAWKER_DATA/themes"

# ── Runtime directories ──
echo "==> Creating runtime config files..."
mkdir -p "$HOME/.config/hawker"
mkdir -p "$HOME/.config/hypr/wallpapers"
touch "$HOME/.config/hypr/active-theme.conf"

# ── SSH config (desktop only) ──
if [ -d /mnt/games/.ssh ]; then
    echo "==> Setting up SSH config..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    if [ ! -f "$HOME/.ssh/config" ]; then
        cat > "$HOME/.ssh/config" <<'EOF'
Include /mnt/games/.ssh/config

Host *
    IdentityFile /mnt/games/.ssh/id_ed25519
EOF
        chmod 600 "$HOME/.ssh/config"
    fi
fi

# ── Apply default theme if none is set ──
if [ ! -f "$HOME/.config/hawker/current-theme" ]; then
    DEFAULT_THEME=$(nix eval --raw ".#nixosConfigurations.desktop.config.hawker.defaultTheme" 2>/dev/null) || DEFAULT_THEME="ayu-dark"
    echo "==> Applying default theme: $DEFAULT_THEME"
    hawker-theme-set "$DEFAULT_THEME" || echo "  (theme set failed -- run hawker-theme-set manually)"
fi

echo ""
echo "==> Bootstrap complete!"
