#!/usr/bin/env bash
# Container entry script -- runs on every container start.
# Clones hawker repo, applies Home Manager config, runs project setup.
set -e

# ── Clone hawker repo if not present ──
if [ ! -d ~/hawker/.git ]; then
    echo "==> Cloning hawker repo..."
    tmp=$(mktemp -d)
    git clone "$HAWKER_REPO" "$tmp/hawker"
    rm -rf ~/hawker
    mv "$tmp/hawker" ~/hawker
    rm -rf "$tmp"
fi

# ── Apply Home Manager config ──
if [ -f ~/hawker/home/default.nix ]; then
    echo "==> Applying Home Manager config..."
    nix run ~/hawker#homeConfigurations."$USER".activationPackage \
        --extra-experimental-features "nix-command flakes" 2>&1 \
        || echo "  (home-manager failed, continuing)"
fi

# ── Project setup ──
# Order matters: pytorch must build torch before helion tries to import it.
ordered="pytorch helion"
for p in $ordered; do
    echo "${HAWKER_PROJECTS//,/ }" | grep -qw "$p" || continue
    s=~/hawker/projects/${p}/setup.sh
    [ -f "$s" ] && bash "$s"
done

# Run any remaining projects not in the ordered list
for p in ${HAWKER_PROJECTS//,/ }; do
    echo "$ordered" | grep -qw "$p" && continue
    s=~/hawker/projects/${p}/setup.sh
    [ -f "$s" ] && bash "$s"
done

exec fish
