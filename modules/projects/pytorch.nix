{ pkgs, lib, config, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      # Python (may already be pulled by helion -- NixOS deduplicates)
      python3
      python3Packages.pip
      python3Packages.virtualenv
      uv

      # CUDA (deduplicated if helion is also enabled)
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      cudaPackages.nccl

      # Build tools for compiling pytorch from source
      cmake
      ninja
      gcc
      gnumake
      pkg-config
      gfortran

      # Libraries pytorch links against
      openblas
      zlib
      libuv
      libpng
      libjpeg

      # Python build deps
      python3Packages.pyyaml
      python3Packages.typing-extensions
      python3Packages.setuptools
    ];

    environment.sessionVariables = {
      CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
      NCCL_ROOT = "${pkgs.cudaPackages.nccl}";
      USE_CUDA = "1";
      USE_CUDNN = "1";
      USE_NCCL = "1";
      USE_SYSTEM_NCCL = "1";
      MAX_JOBS = "16";
    };
  };
}
