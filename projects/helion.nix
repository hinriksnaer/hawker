{ pkgs, lib, config, ... }:

let
  cfg = config.helion;
  has = backend: builtins.elem backend cfg.backends;

  backendPackages = {
    cuda = []; # cudatoolkit + cudnn already in cuda-dev.nix
    cute = with pkgs; [ cudaPackages.cutlass ];
    # rocm = with pkgs; [ rocmPackages.clr rocmPackages.rocm-smi ];
    # cpu = [];
  };

  pipExtras = lib.concatStringsSep "," (
    lib.optional (has "cute") "cute-cu12"
  );

  selectedPackages = lib.concatMap (b: backendPackages.${b} or []) cfg.backends;
in
{
  imports = [ ../modules/ai/cuda-dev.nix ];

  options.helion = {
    backends = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "cuda" "cute" /* "rocm" "cpu" */ ]);
      default = [ "cuda" ];
      description = "Hardware backends to enable (not mutually exclusive)";
    };
  };

  config = {
    environment.systemPackages = with pkgs; [
      # Helion-specific build tools
      clang_20
    ] ++ selectedPackages;

    environment.sessionVariables = {
      HELION_BACKENDS = builtins.concatStringsSep "," cfg.backends;
      HELION_PIP_EXTRAS = if pipExtras != "" then "[${pipExtras}]" else "";
    };
  };
}
