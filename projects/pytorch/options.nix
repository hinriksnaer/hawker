# Typed option declarations for the PyTorch project.
# Values are set in settings.nix under hawker.hosts.container.projects.pytorch.
{ lib, ... }:

{
  options.hawker.container.projects.pytorch = {
    enable = lib.mkEnableOption "PyTorch (build from source)";

    buildOrder = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Build priority (lower builds first). pytorch=10, helion=20.";
    };

    repo = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/pytorch/pytorch.git";
      description = "PyTorch git repository URL.";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "PyTorch git branch.";
    };

    cudaArch = lib.mkOption {
      type = lib.types.str;
      default = "9.0";
      description = "CUDA architectures to compile for (e.g. '9.0' for H200, '8.0;9.0' for A100+H200).";
    };

    buildTests = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Build pytorch test binaries (slower build, only needed for running C++ tests).";
    };
  };
}
