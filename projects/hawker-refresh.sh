#!/usr/bin/env bash
# hawker-refresh -- pull latest config and apply Home Manager
set -euo pipefail

HAWKER_ROOT="${HAWKER_ROOT:-$HOME/workspace/hawker}"

if [ ! -d "$HAWKER_ROOT/.git" ]; then
    if [ -d "$HOME/hawker/.git" ]; then
        HAWKER_ROOT="$HOME/hawker"
    else
        echo "Error: hawker repo not found" >&2
        exit 1
    fi
fi

echo "==> Pulling latest changes..."
git -C "$HAWKER_ROOT" pull --ff-only || true

echo "==> Applying Home Manager..."
if [ -f /etc/NIXOS ]; then
    echo "  NixOS detected -- use hawker-switch instead"
else
    home-manager switch -b backup --flake "$HAWKER_ROOT#${HM_PROFILE:-remote}" 2>&1 || true
fi

echo "==> Done"
