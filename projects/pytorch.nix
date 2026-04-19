{ pkgs, lib, config, ... }:

{
  imports = [ ../modules/ai/cuda-dev.nix ];

  config = {
    environment.systemPackages = with pkgs; [
      # PyTorch-specific deps
      cudaPackages.nccl
      gfortran
      openblas
      libuv
      libpng
      libjpeg

      # Python build deps
      python3Packages.pyyaml
      python3Packages.typing-extensions
      python3Packages.setuptools
    ];

    environment.sessionVariables = {
      NCCL_ROOT = "${pkgs.cudaPackages.nccl}";
      USE_CUDA = "1";
      USE_CUDNN = "1";
      USE_NCCL = "1";
      USE_SYSTEM_NCCL = "1";
      MAX_JOBS = "16";
    };
  };
}
