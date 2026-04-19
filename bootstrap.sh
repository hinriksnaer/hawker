#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
HYPRPUNK_DATA="$HOME/.local/share/hyprpunk"

echo "==> Deploying dotfiles via stow (--no-folding)..."

# Stow each module's dotfiles into $HOME
# --no-folding ensures individual file symlinks, not folder symlinks
# This prevents runtime writes (theme switcher, plugins) from leaking into the repo
for dir in "$DOTFILES_DIR"/*/; do
    module=$(basename "$dir")

    # themes: deployed separately to ~/.local/share/hyprpunk/themes/
    # btop: rewrites its config on exit -- copied below
    # opencode: tui.json gets rewritten by theme switcher -- copied below
    if [ "$module" = "themes" ] || [ "$module" = "rust" ] || [ "$module" = "btop" ]; then
        continue
    fi

    echo "  stow: $module"
    stow -d "$DOTFILES_DIR" -t "$HOME" --no-folding --restow "$module" 2>&1 | grep -v "BUG" || true
done

# Deploy themes to ~/.local/share/hyprpunk/themes/
echo "==> Deploying themes to $HYPRPUNK_DATA/themes/..."
mkdir -p "$HYPRPUNK_DATA"
if [ -L "$HYPRPUNK_DATA/themes" ]; then
    rm "$HYPRPUNK_DATA/themes"
fi
ln -snf "$DOTFILES_DIR/themes" "$HYPRPUNK_DATA/themes"

# Copy btop config (btop rewrites its config on exit, can't be a symlink)
echo "==> Copying btop config..."
mkdir -p "$HOME/.config/btop/themes"
cp "$DOTFILES_DIR/btop/.config/btop/btop.conf" "$HOME/.config/btop/btop.conf"

# Set up opencode themes (symlink each theme's opencode.json into opencode themes dir)
echo "==> Deploying opencode themes..."
mkdir -p "$HOME/.config/opencode/themes"
for theme_dir in "$DOTFILES_DIR"/themes/*/; do
    theme=$(basename "$theme_dir")
    if [ -f "$theme_dir/opencode.json" ]; then
        ln -sf "$theme_dir/opencode.json" "$HOME/.config/opencode/themes/$theme.json"
    fi
done

# Copy opencode tui.json (theme switcher rewrites it, can't be a symlink)
echo "==> Copying opencode tui.json..."
echo '{"$schema":"https://opencode.ai/tui.json","theme":"torrentz-hydra"}' > "$HOME/.config/opencode/tui.json"

# SSH config -- points at external drive keys (not stored in repo)
echo "==> Setting up SSH config..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/config" ]; then
    cat > "$HOME/.ssh/config" <<'EOF'
# SSH keys and host configs from external drive (GAMES)
Include /mnt/games/.ssh/config

# Override identity file path to point at the drive
Host *
    IdentityFile /mnt/games/.ssh/id_ed25519
EOF
    chmod 600 "$HOME/.ssh/config"
fi

# Create runtime files (not managed by stow -- written by theme switcher)
echo "==> Creating runtime config files..."
mkdir -p "$HOME/.config/hyprpunk/current"
mkdir -p "$HOME/.config/hypr/wallpapers"
touch "$HOME/.config/hypr/active-theme.conf"
touch "$HOME/.config/hypr/active-mode.conf"

# ── One-time plugin installs ──

# Fisher (fish plugin manager)
if command -v fish &>/dev/null; then
    echo "==> Installing Fisher and fish plugins..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null || true
    if [ -f "$DOTFILES_DIR/fish/.config/fish/fish_plugins" ]; then
        fish -c "fisher update" 2>/dev/null || true
    fi
fi

# TPM (tmux plugin manager)
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "==> Installing TPM (tmux plugin manager)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" 2>/dev/null || true
fi
if [ -d "$TPM_DIR" ]; then
    "$TPM_DIR/bin/install_plugins" 2>/dev/null || true
fi

# Yazi plugins
if command -v yazi &>/dev/null; then
    echo "==> Installing yazi plugins..."
    ya pack -i 2>/dev/null || true
fi

# Set default theme (torrentz-hydra)
if command -v hyprpunk-theme-set &>/dev/null && [ ! -L "$HOME/.config/hyprpunk/current/theme" ]; then
    echo "==> Setting default theme (torrentz-hydra)..."
    export HYPRPUNK_PATH="$HYPRPUNK_DATA"
    fish -c "hyprpunk-theme-set torrentz-hydra" 2>/dev/null || true
fi

echo ""
echo "==> Bootstrap complete!"
echo ""
echo "Launch Hyprland:"
echo "  start-hyprland    (from TTY)"
echo "  or reboot into SDDM"
