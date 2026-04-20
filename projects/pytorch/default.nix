{ pkgs, lib, config, ... }:

let
  pc = config.hawker.pytorch;
  nccl = pkgs.cudaPackages.nccl;
in
{
  imports = [ ../../modules/ai/cuda-dev.nix ];

  config = {
    environment.systemPackages = with pkgs; [
      nccl
      nccl.dev  # headers (nccl.h) -- Nix splits into separate output
      gfortran
      openblas
      libuv
      libpng
      libjpeg

      # Build acceleration (upstream recommended)
      ccache

      python3Packages.pyyaml
      python3Packages.typing-extensions
      python3Packages.setuptools
    ];

    environment.sessionVariables = {
      PYTORCH_REPO = pc.repo;
      PYTORCH_BRANCH = pc.branch;
      NCCL_ROOT = "${nccl}";
      NCCL_INCLUDE_DIR = "${nccl.dev}/include";
      NCCL_LIB_DIR = "${nccl}/lib";
      USE_CUDA = "1";
      USE_CUDNN = "1";
      CUDNN_ROOT = "${pkgs.cudaPackages.cudnn}";
      USE_NCCL = "1";
      USE_SYSTEM_NCCL = "1";
      USE_CUFILE = "OFF";     # cuFile (GPU Direct Storage) not in Nix CUDA packages
      USE_NVSHMEM = "OFF";  # pip nvshmem ABI incompatible with older SM targets
      USE_KINETO = "1";     # profiling (torch.profiler) -- needed for kernel benchmarking
      USE_FBGEMM = "0";     # Facebook GEMM -- not needed for compile/inductor work
      USE_NNPACK = "0";     # legacy neural network primitives
      USE_QNNPACK = "0";    # quantized neural network primitives
      USE_XNNPACK = "0";    # XNNPACK -- CPU inference optimization
      TORCH_CUDA_ARCH_LIST = pc.cudaArch;
      BUILD_TEST = if pc.buildTests then "1" else "0";
      MAX_JOBS = "64";
      CMAKE_C_COMPILER_LAUNCHER = "ccache";
      CMAKE_CXX_COMPILER_LAUNCHER = "ccache";
      CMAKE_CUDA_COMPILER_LAUNCHER = "ccache";
      CCACHE_DIR = "/home/${config.hawker.username}/.cache/ccache";
      CCACHE_MAXSIZE = "25G";
      USE_PRECOMPILED_HEADERS = "1";  # upstream recommended for faster rebuilds
    };
  };
}
