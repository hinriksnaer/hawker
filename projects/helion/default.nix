{ pkgs, lib, config, settings, ... }:

let
  cfg = config.helion;
  helionSettings = settings.helion or {};
  has = backend: builtins.elem backend cfg.backends;

  backendPackages = {
    cuda = [];
    cute = with pkgs; [ cudaPackages.cutlass ];
  };

  pipExtras = lib.concatStringsSep "," (
    lib.optional (has "cute") "cute-cu12"
  );

  selectedPackages = lib.concatMap (b: backendPackages.${b} or []) cfg.backends;
in
{
  imports = [ ../../modules/ai/cuda-dev.nix ];

  options.helion = {
    backends = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "cuda" "cute" ]);
      default = [ "cuda" ];
      description = "Hardware backends to enable (not mutually exclusive)";
    };
  };

  config = {
    environment.systemPackages = with pkgs; [
      clang_20
    ] ++ selectedPackages;

    environment.sessionVariables = {
      HELION_REPO = helionSettings.repo or "https://github.com/pytorch/helion.git";
      HELION_BRANCH = helionSettings.branch or "main";
      HELION_TORCH_INDEX = helionSettings.torchIndex or "nightly/cu130";
      HELION_BACKENDS = builtins.concatStringsSep "," cfg.backends;
      HELION_PIP_EXTRAS = if pipExtras != "" then "[${pipExtras}]" else "";
    };
  };
}
