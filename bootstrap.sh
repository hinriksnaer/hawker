#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
HAWKER_DATA="$HOME/.local/share/hawker"

echo "==> Deploying dotfiles via stow (--no-folding)..."

# Stow each module's dotfiles into $HOME
# --no-folding ensures individual file symlinks, not folder symlinks
# This prevents runtime writes (theme switcher, plugins) from leaking into the repo
for dir in "$DOTFILES_DIR"/*/; do
    module=$(basename "$dir")

    # themes: deployed separately to ~/.local/share/hawker/themes/
    # btop: rewrites its config on exit -- copied below
    # opencode: tui.json gets rewritten by theme switcher -- copied below
    # git: generated from settings.nix values below, not stowed
    if [ "$module" = "themes" ] || [ "$module" = "rust" ] || [ "$module" = "btop" ] || [ "$module" = "git" ]; then
        continue
    fi

    echo "  stow: $module"
    stow -d "$DOTFILES_DIR" -t "$HOME" --no-folding --restow "$module" 2>&1 | grep -v "BUG" || true
done

# Deploy themes to ~/.local/share/hawker/themes/
echo "==> Deploying themes to $HAWKER_DATA/themes/..."
mkdir -p "$HAWKER_DATA"
if [ -L "$HAWKER_DATA/themes" ]; then
    rm "$HAWKER_DATA/themes"
fi
ln -snf "$DOTFILES_DIR/themes" "$HAWKER_DATA/themes"

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

# Git config -- generated from settings.nix if nix is available, else uses defaults
echo "==> Setting up git config..."
if [ ! -f "$HOME/.gitconfig" ]; then
    GIT_NAME=""
    GIT_EMAIL=""
    if command -v nix >/dev/null 2>&1 && [ -f "$SCRIPT_DIR/settings.nix" ]; then
        GIT_NAME=$(nix eval --raw --file "$SCRIPT_DIR/settings.nix" git.name 2>/dev/null || true)
        GIT_EMAIL=$(nix eval --raw --file "$SCRIPT_DIR/settings.nix" git.email 2>/dev/null || true)
    fi
    GIT_NAME="${GIT_NAME:-$(whoami 2>/dev/null || echo user)}"
    GIT_EMAIL="${GIT_EMAIL:-$(whoami 2>/dev/null || echo user)@$(hostname 2>/dev/null || echo localhost)}"
    cat > "$HOME/.gitconfig" <<EOF
[user]
    name = $GIT_NAME
    email = $GIT_EMAIL

[core]
    editor = nvim

[init]
    defaultBranch = main

[pull]
    rebase = false
EOF
fi

# SSH config -- points at external drive keys (not stored in repo).
# Only created on the desktop (where /mnt/games exists), not in containers.
if [ -d /mnt/games/.ssh ]; then
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
fi

# Create runtime files (not managed by stow -- written by theme switcher)
echo "==> Creating runtime config files..."
mkdir -p "$HOME/.config/hawker/current"
mkdir -p "$HOME/.config/hypr/wallpapers"
touch "$HOME/.config/hypr/active-theme.conf"
touch "$HOME/.config/hypr/active-mode.conf"

# ── One-time plugin installs ──

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
if command -v hawker-theme-set &>/dev/null && [ ! -L "$HOME/.config/hawker/current/theme" ]; then
    echo "==> Setting default theme (torrentz-hydra)..."
    export HAWKER_PATH="$HAWKER_DATA"
    fish -c "hawker-theme-set torrentz-hydra" 2>/dev/null || true
fi

echo ""
echo "==> Bootstrap complete!"
echo ""
echo "Launch Hyprland:"
echo "  start-hyprland    (from TTY)"
echo "  or reboot into SDDM"
