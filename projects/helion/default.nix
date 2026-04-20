{ pkgs, lib, config, ... }:

let
  hc = config.hawker.container.projects.helion;
  has = backend: builtins.elem backend hc.backends;

  backendPackages = {
    cuda = [];
    cute = with pkgs; [ cudaPackages.cutlass ];
  };

  pipExtras = lib.concatStringsSep "," (
    lib.optional (has "cute") "cute-cu12"
  );

  selectedPackages = lib.concatMap (b: backendPackages.${b} or []) hc.backends;
in
{
  imports = [ ../../modules/ai/cuda-dev.nix ];

  config = {
    environment.systemPackages = with pkgs; [
      clang_20
    ] ++ selectedPackages;

    environment.sessionVariables = {
      HELION_REPO = hc.repo;
      HELION_BRANCH = hc.branch;
      HELION_TORCH_INDEX = hc.torchIndex;
      HELION_BACKENDS = builtins.concatStringsSep "," hc.backends;
      HELION_PIP_EXTRAS = if pipExtras != "" then "[${pipExtras}]" else "";
    };
  };
}
