# Typed option declarations for the Helion project.
# Values are set in settings.nix under hawker.hosts.container.projects.helion.
{ lib, ... }:

{
  options.hawker.container.projects.helion = {
    enable = lib.mkEnableOption "Helion GPU kernel DSL";

    buildOrder = lib.mkOption {
      type = lib.types.int;
      default = 20;
      description = "Build priority (lower builds first). pytorch=10, helion=20.";
    };

    repo = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/pytorch/helion.git";
      description = "Helion git repository URL.";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Helion git branch.";
    };

    torchIndex = lib.mkOption {
      type = lib.types.str;
      default = "nightly/cu130";
      description = "PyTorch wheel index for helion (when pytorch project is not enabled).";
    };

    backends = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "cuda" "cute" ]);
      default = [ "cuda" ];
      description = "GPU backends to enable. Stackable, not mutually exclusive.";
    };
  };
}
