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

# Ensure pip is available (uv venv doesn't include it by default)
uv pip install pip 2>/dev/null || true

if [ ! -d "$WORKSPACE" ]; then
    echo "==> Cloning ${PYTORCH_REPO} (${PYTORCH_BRANCH})..."
    git clone --recursive --branch "${PYTORCH_BRANCH}" "${PYTORCH_REPO}" "$WORKSPACE"
fi

cd "$WORKSPACE"

# Install dev dependencies (upstream recommended method)
echo "==> Installing PyTorch dev dependencies..."
python -m pip install --group dev

# Remove pip-installed cmake/ninja -- they shadow the Nix-provided ones
# which are properly configured for this environment
python -m pip uninstall -y cmake ninja 2>/dev/null || true

# Build and install PyTorch in editable mode (upstream recommended method)
echo "==> Installing PyTorch in editable mode (compiles from source)..."
echo "    MAX_JOBS=${MAX_JOBS:-auto}, TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST:-auto}"
echo "    ccache: ${CMAKE_CXX_COMPILER_LAUNCHER:-none}"
python -m pip install --no-build-isolation -v -e .

touch "$MARKER"
echo "==> PyTorch workspace ready"
