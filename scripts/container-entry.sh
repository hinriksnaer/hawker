#!/usr/bin/env bash
# Container entry script -- runs on every container start.
# Clones hawker repo, runs bootstrap, applies Home Manager, runs project setup.
set -e

# ── Clone hawker repo if not present ──
if [ ! -d ~/hawker/.git ]; then
    echo "==> Cloning hawker repo..."
    git clone "$HAWKER_REPO" ~/hawker
fi

# ── Bootstrap (stow dotfiles) ──
if [ ! -f ~/repos/.bootstrap-done ] && [ -f ~/hawker/bootstrap.sh ]; then
    echo "==> Running bootstrap..."
    mkdir -p ~/repos
    bash ~/hawker/bootstrap.sh || echo "  (bootstrap failed, continuing)"
    touch ~/repos/.bootstrap-done
fi

# ── Home Manager ──
if command -v nix &>/dev/null && [ -f ~/hawker/home/default.nix ]; then
    echo "==> Applying Home Manager config..."
    nix run ~/hawker#homeConfigurations."$USER".activationPackage \
        --extra-experimental-features "nix-command flakes" 2>&1 \
        || echo "  (home-manager failed, continuing)"
fi

# ── Project setup ──
ordered="pytorch helion"
for p in $ordered; do
    echo "${HAWKER_PROJECTS//,/ }" | grep -qw "$p" || continue
    s=~/hawker/projects/${p}/setup.sh
    [ -f "$s" ] && bash "$s"
done

for p in ${HAWKER_PROJECTS//,/ }; do
    echo "$ordered" | grep -qw "$p" && continue
    s=~/hawker/projects/${p}/setup.sh
    [ -f "$s" ] && bash "$s"
done

exec fish
