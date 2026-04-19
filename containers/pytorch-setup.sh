#!/usr/bin/env bash
# PyTorch workspace setup -- runs once on first container entry
# Config: containers/pytorch/config.sh
# Follows upstream CONTRIBUTING.md install instructions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pytorch/config.sh"

REPOS="$HOME/repos"
WORKSPACE="$REPOS/pytorch"
VENV="$REPOS/.venv"
MARKER="$REPOS/.pytorch-setup-done"

if [ -f "$MARKER" ]; then
    exit 0
fi

echo "==> Setting up PyTorch workspace..."

# Shared venv (created by whichever project runs first)
if [ ! -d "$VENV" ]; then
    echo "==> Creating shared virtual environment..."
    uv venv "$VENV"
fi
source "$VENV/bin/activate"

if [ ! -d "$WORKSPACE" ]; then
    echo "==> Cloning $PYTORCH_REPO ($PYTORCH_BRANCH)..."
    git clone --recursive --branch "$PYTORCH_BRANCH" "$PYTORCH_REPO" "$WORKSPACE"
fi

cd "$WORKSPACE"

echo "==> Installing PyTorch dev dependencies..."
pip install --group dev

echo "==> Installing PyTorch in editable mode (compiles from source)..."
echo "    This takes 30-60 minutes on first build."
echo "    Set MAX_JOBS to control parallelism."
python -m pip install --no-build-isolation -v -e .

touch "$MARKER"
echo "==> PyTorch workspace ready"
