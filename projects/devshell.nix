# Shared CUDA development shell.
# Provides the same environment as cuda-dev.nix but as a mkShell
# for use with `nix develop`. Works on any host with Nix + NVIDIA drivers.
#
# Usage: nix develop ~/workspace/hawker
#    or: cd into a project dir with .envrc → direnv auto-enters
{ pkgs, settings }:

let
  inherit (pkgs) cudaPackages;
  cudaToolkit = cudaPackages.cudatoolkit;
  cudnn = cudaPackages.cudnn;
  cudaGcc = cudaPackages.backendStdenv.cc;

  # Project settings
  hostSettings = settings.hosts.remote or {};
  projectSettings = hostSettings.projects or {};
  cudaVisibleDevices = hostSettings.cudaVisibleDevices or "";

  # Helion config
  helionCfg = projectSettings.helion or {};
  helionBackends = helionCfg.backends or [ "cuda" ];
  hasCute = builtins.elem "cute" helionBackends;
  helionPipExtras = let
    extras = pkgs.lib.optional hasCute "cute-cu12";
    joined = builtins.concatStringsSep "," extras;
  in if joined != "" then "[${joined}]" else "";

  # PyTorch config
  pytorchCfg = projectSettings.pytorch or {};
  cudaArch = pytorchCfg.cudaArch or "9.0";
  maxJobs = toString (pytorchCfg.maxJobs or 32);
  buildTests = if (pytorchCfg.buildTests or false) then "1" else "0";

  # Enabled projects (from settings)
  enabledProjects = builtins.filter (name:
    (projectSettings.${name} or {}).enable or false
  ) [ "pytorch" "helion" "vllm" ];
  enabledProjectsStr = builtins.concatStringsSep " " enabledProjects;

  # Workspace paths
  repos = "$HOME/workspace/repos";
  venv = "${repos}/.venv";
in
pkgs.mkShell {
  name = "hawker-dev";

  packages = with pkgs; [
    # Python
    python3
    python3Packages.pip
    python3Packages.virtualenv
    uv

    # CUDA toolkit + cuDNN
    cudaToolkit
    cudnn
    cudnn.include
    cudnn.lib

    # Build tools -- GCC 14 (CUDA 12.9 requires <=14)
    cmake
    ninja
    cudaGcc
    gnumake
    pkg-config
    zlib
    glibc.bin
    ccache

    # Helion
    clang_20
  ] ++ pkgs.lib.optional hasCute cudaPackages.cutlass
    # PyTorch build deps
    ++ (with pkgs; [
    gfortran
    openblas
    libuv
    libpng
    libjpeg
    python3Packages.pyyaml
    python3Packages.typing-extensions
    python3Packages.setuptools
  ]);

  # CUDA binary cache
  NIX_CONFIG = "extra-substituters = https://cache.nixos-cuda.org\nextra-trusted-public-keys = cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=";

  shellHook = ''
    export HAWKER_ROOT="''${HAWKER_ROOT:-$HOME/hawker}"
    export HAWKER_ENABLED_PROJECTS="${enabledProjectsStr}"

    # CUDA environment
    export CUDA_HOME="${cudaToolkit}"
    export CUDA_PATH="${cudaToolkit}"
    export CMAKE_PREFIX_PATH="${cudaToolkit}:${pkgs.python3}"
    export CUDNN_INCLUDE_DIR="${cudnn.include}/include"
    export CUDNN_LIB_DIR="${cudnn.lib}/lib"
    export CUDNN_INCLUDE_PATH="${cudnn.include}/include"
    export CUDNN_LIBRARY_PATH="${cudnn.lib}/lib"
    export CPATH="${cudaToolkit}/include:${cudnn.include}/include"
    ${pkgs.lib.optionalString (cudaVisibleDevices != "") ''export CUDA_VISIBLE_DEVICES="${cudaVisibleDevices}"''}

    # Runtime libraries for pip-installed packages (PyTorch needs libstdc++)
    export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${cudaToolkit}/lib:${cudnn.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    # PyTorch build flags
    export USE_CUDA=1
    export USE_CUDNN=1
    export USE_NCCL=1
    export USE_SYSTEM_NCCL=0
    export LIBRARY_PATH="${cudaToolkit}/lib"
    export USE_CUFILE=OFF
    export USE_NVSHMEM=OFF
    export USE_KINETO=1
    export USE_FBGEMM=0
    export USE_NNPACK=0
    export USE_QNNPACK=0
    export USE_XNNPACK=0
    export TORCH_CUDA_ARCH_LIST="${cudaArch}"
    export BUILD_TEST="${buildTests}"
    export MAX_JOBS="${maxJobs}"
    export USE_PRECOMPILED_HEADERS=1

    # ccache
    export CMAKE_C_COMPILER_LAUNCHER=ccache
    export CMAKE_CXX_COMPILER_LAUNCHER=ccache
    export CMAKE_CUDA_COMPILER_LAUNCHER=ccache
    export CCACHE_DIR="$HOME/.cache/ccache"
    export CCACHE_MAXSIZE=25G
    export CCACHE_NOHASHDIR=true

    # Helion
    export HELION_REPO="${helionCfg.repo or "https://github.com/pytorch/helion.git"}"
    export HELION_BRANCH="${helionCfg.branch or "main"}"
    export HELION_TORCH_INDEX="${helionCfg.torchIndex or "nightly/cu130"}"
    export HELION_BACKENDS="${builtins.concatStringsSep "," helionBackends}"
    export HELION_PIP_EXTRAS="${helionPipExtras}"

    # PyTorch
    export PYTORCH_REPO="${pytorchCfg.repo or "https://github.com/pytorch/pytorch.git"}"
    export PYTORCH_BRANCH="${pytorchCfg.branch or "viable/strict"}"

    # vLLM
    export VLLM_REPO="${(projectSettings.vllm or {}).repo or "https://github.com/vllm-project/vllm.git"}"
    export VLLM_BRANCH="${(projectSettings.vllm or {}).branch or "main"}"
    export VLLM_TARGET_DEVICE=cuda
    export VLLM_TORCH_INDEX="${(projectSettings.vllm or {}).torchIndex or "nightly/cu130"}"

    # Activate shared venv if it exists
    if [ -f "${venv}/bin/activate" ]; then
      source "${venv}/bin/activate"
      # Ensure debugpy is available for neovim DAP
      python -c "import debugpy" 2>/dev/null || uv pip install debugpy -q
    fi
  '';
}
