{ lib, ... }:

{
  options.hawker.helion = {
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
