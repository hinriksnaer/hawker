#!/usr/bin/env bash
# Helion workspace setup -- runs once on first container entry
# Config: projects/helion/config.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helion/config.sh"

REPOS="$HOME/repos"
WORKSPACE="$REPOS/helion"
VENV="$REPOS/.venv"
MARKER="$REPOS/.helion-setup-done"

if [ -f "$MARKER" ]; then
    exit 0
fi

echo "==> Setting up Helion workspace..."

# Shared venv for all projects (helion, pytorch, etc.)
if [ ! -d "$VENV" ]; then
    echo "==> Creating shared virtual environment..."
    uv venv "$VENV"
fi
source "$VENV/bin/activate"

if [ ! -d "$WORKSPACE" ]; then
    echo "==> Cloning $HELION_REPO ($HELION_BRANCH)..."
    git clone --branch "$HELION_BRANCH" "$HELION_REPO" "$WORKSPACE"
fi

cd "$WORKSPACE"

echo "==> Installing PyTorch ($TORCH_INDEX)..."
uv pip install --pre torch triton \
    --index-url "https://download.pytorch.org/whl/$TORCH_INDEX" \
    --extra-index-url https://pypi.org/simple

EXTRAS="dev"
if [ -n "${HELION_PIP_EXTRAS:-}" ]; then
    EXTRAS="dev,${HELION_PIP_EXTRAS#[}"
    EXTRAS="${EXTRAS%]}"
fi
echo "==> Installing Helion (editable, extras: $EXTRAS)..."
SETUPTOOLS_SCM_PRETEND_VERSION_FOR_HELION=0.0+dev \
    uv pip install -e ".[$EXTRAS]"

uv pip install pyrefly ruff

touch "$MARKER"
echo "==> Helion workspace ready"
