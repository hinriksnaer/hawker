{ pkgs, lib, config, settings, ... }:

let
  pytorchSettings = settings.pytorch or {};
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
      PYTORCH_REPO = pytorchSettings.repo or "https://github.com/pytorch/pytorch.git";
      PYTORCH_BRANCH = pytorchSettings.branch or "main";
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
      TORCH_CUDA_ARCH_LIST = "9.0";  # H200 only -- dramatically faster builds
      MAX_JOBS = "64";
      CMAKE_C_COMPILER_LAUNCHER = "ccache";
      CMAKE_CXX_COMPILER_LAUNCHER = "ccache";
      CMAKE_CUDA_COMPILER_LAUNCHER = "ccache";
      USE_PRECOMPILED_HEADERS = "1";  # upstream recommended for faster rebuilds
    };
  };
}
