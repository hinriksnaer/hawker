{ pkgs, lib, config, settings, ... }:

let
  pytorchSettings = settings.pytorch or {};
in
{
  imports = [ ../../modules/ai/cuda-dev.nix ];

  config = {
    environment.systemPackages = with pkgs; [
      cudaPackages.nccl
      gfortran
      openblas
      libuv
      libpng
      libjpeg

      python3Packages.pyyaml
      python3Packages.typing-extensions
      python3Packages.setuptools
    ];

    environment.sessionVariables = {
      PYTORCH_REPO = pytorchSettings.repo or "https://github.com/pytorch/pytorch.git";
      PYTORCH_BRANCH = pytorchSettings.branch or "main";
      NCCL_ROOT = "${pkgs.cudaPackages.nccl}";
      USE_CUDA = "1";
      USE_CUDNN = "1";
      USE_NCCL = "1";
      USE_SYSTEM_NCCL = "1";
      MAX_JOBS = "16";
    };
  };
}
