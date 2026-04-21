{ config, lib, pkgs, ... }:

{
  # Intel integrated graphics for Wayland
  services.xserver.videoDrivers = [ "intel" ];

  # Load Intel GPU modules early for DRM/KMS
  boot.initrd.kernelModules = [ "intel_agp" "i915" ];

  boot.kernelModules = [ "intel_agp" "i915" ];

  # Intel GPU acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # VAAPI for video acceleration
    ];
  };

  users.users.${config.hawker.username}.extraGroups = [ "video" ];

  # Wayland + Intel environment
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    GBM_BACKEND = "i915";
  };
}
