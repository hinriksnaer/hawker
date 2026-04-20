#!/usr/bin/env bash
# Container entry script.
# Starts as root to fix ownership, then re-execs as the user.
set -e

HAWKER_USER="${HAWKER_USER:-hawker}"
USER_HOME="/home/${HAWKER_USER}"

# ── First run as root: fix ownership, then switch to user ──
if [ "$(id -u)" = "0" ]; then
    # Only chown writable Nix paths (not entire store -- too slow)
    chown -R 1000:1000 "$USER_HOME" 2>/dev/null || true
    chown 1000:1000 /nix/store 2>/dev/null || true
    mkdir -p /nix/store/.links
    chown 1000:1000 /nix/store/.links 2>/dev/null || true
    chown -R 1000:1000 /nix/var 2>/dev/null || true

    # Re-exec this script as the user, passing env vars through
    exec su "$HAWKER_USER" -s /bin/bash -c "
        export HOME='$USER_HOME'
        export USER='$HAWKER_USER'
        export HAWKER_REPO='${HAWKER_REPO:-}'
        export HAWKER_PROJECTS='${HAWKER_PROJECTS:-}'
        export HAWKER_USER='$HAWKER_USER'
        exec bash $0
    "
fi

# ── Everything below runs as the user ──
cd "$HOME"

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
    nix run ~/hawker#homeConfigurations."${HAWKER_USER}".activationPackage \
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
