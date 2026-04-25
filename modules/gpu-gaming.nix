# Gaming-specific GPU extensions.
# Separated from gpu.nix to keep base driver config clean for
# non-gaming workloads (AI containers, CUDA dev, etc.).
{ config, lib, pkgs, ... }:

let
  hasNvidia = config.hawker.gpu == "nvidia";
in
{
  # 32-bit driver support (Proton, Wine, most Steam games)
  hardware.graphics.enable32Bit = true;

  environment.systemPackages = with pkgs; [
    vulkan-tools  # vulkaninfo for debugging
  ];

  # Nvidia-specific gaming optimizations
  environment.sessionVariables = lib.mkIf hasNvidia {
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
  };
}
