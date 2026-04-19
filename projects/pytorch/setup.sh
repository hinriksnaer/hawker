#!/usr/bin/env bash
# PyTorch workspace setup -- runs once on first container entry
# Config comes from settings.nix via environment variables.
# Follows upstream CONTRIBUTING.md install instructions.
set -euo pipefail

REPOS="$HOME/repos"
WORKSPACE="$REPOS/pytorch"
VENV="$REPOS/.venv"
MARKER="$REPOS/.pytorch-setup-done"

if [ -f "$MARKER" ]; then
    exit 0
fi

echo "==> Setting up PyTorch workspace..."

if [ ! -d "$VENV" ]; then
    echo "==> Creating shared virtual environment..."
    uv venv "$VENV"
fi
source "$VENV/bin/activate"

if [ ! -d "$WORKSPACE" ]; then
    echo "==> Cloning ${PYTORCH_REPO} (${PYTORCH_BRANCH})..."
    git clone --recursive --branch "${PYTORCH_BRANCH}" "${PYTORCH_REPO}" "$WORKSPACE"
fi

cd "$WORKSPACE"

echo "==> Installing PyTorch dev dependencies..."
uv pip install -r requirements.txt
uv pip install pytest expecttest hypothesis pyrefly

# Remove pip-installed cmake/ninja -- they shadow the Nix-provided ones
# which are properly configured for this environment
uv pip uninstall cmake ninja 2>/dev/null || true

echo "==> Installing PyTorch in editable mode (compiles from source)..."
echo "    This takes 30-60 minutes on first build."
echo "    MAX_JOBS=${MAX_JOBS:-auto}"
pip install --no-build-isolation -v -e .

touch "$MARKER"
echo "==> PyTorch workspace ready"
