#!/usr/bin/env bash
# PyTorch workspace setup -- runs once on first container entry
# Config comes from settings.nix via environment variables.
# Follows upstream CONTRIBUTING.md install instructions.
set -euo pipefail

REPOS="${REPOS:-$HOME/workspace/repos}"
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
    git clone --branch "${PYTORCH_BRANCH}" "${PYTORCH_REPO}" "$WORKSPACE"
    cd "$WORKSPACE"
    git submodule sync
    git submodule update --init --recursive --depth 1
    cd "$REPOS"
fi

cd "$WORKSPACE"

# NixOS patch: replace PyTorch's vendored FindCUDAToolkit.cmake with a
# passthrough to CMake's standard module, which respects CMAKE_PREFIX_PATH
# (set by cuda-dev.nix). PyTorch's version resolves nvcc symlinks into
# individual Nix store packages that don't contain headers.
# We can't just delete the file because cmake's install step copies it.
# See: nixpkgs/pkgs/development/python-modules/torch/source/default.nix
cat > cmake/Modules/FindCUDAToolkit.cmake << 'NIXEOF'
# NixOS: delegate to CMake's built-in FindCUDAToolkit module.
set(_nixos_cmake_module_path "${CMAKE_MODULE_PATH}")
list(REMOVE_ITEM CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
find_package(CUDAToolkit ${CUDAToolkit_FIND_VERSION})
set(CMAKE_MODULE_PATH "${_nixos_cmake_module_path}")
unset(_nixos_cmake_module_path)
NIXEOF

# Install dev dependencies (upstream recommended method)
echo "==> Installing PyTorch dev dependencies..."
python -m pip install --group dev

# Remove pip-installed cmake/ninja -- they shadow the Nix-provided ones
# which are properly configured for this environment
python -m pip uninstall -y cmake ninja 2>/dev/null || true

# Point PyTorch at the Nix-provided cmake (its cmake.py searches for
# /usr/bin/cmake3 as a fallback which finds the host system's cmake)
export CMAKE="$(command -v cmake)"

# Build and install PyTorch in editable mode (upstream recommended method)
echo "==> Installing PyTorch in editable mode (compiles from source)..."
echo "    MAX_JOBS=${MAX_JOBS:-auto}, TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST:-auto}"
echo "    CMAKE=${CMAKE}"
echo "    ccache: ${CMAKE_CXX_COMPILER_LAUNCHER:-none}"
python -m pip install --no-build-isolation -v -e .

# triton is required for torch.compile/inductor but isn't a pytorch build dependency
python -m pip install triton

touch "$MARKER"
echo "==> PyTorch workspace ready"
