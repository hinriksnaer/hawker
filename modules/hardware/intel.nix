{ config, lib, pkgs, ... }:

{
  # Intel integrated graphics - use modesetting driver for modern Wayland
  services.xserver.videoDrivers = [ "modesetting" ];

  # Load Intel GPU modules early for DRM/KMS
  boot.initrd.kernelModules = [ "i915" ];

  boot.kernelModules = [ "i915" ];

  # Intel GPU acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver   # VA-API (iHD) userspace
      vpl-gpu-rt           # oneVPL (QSV) runtime
    ];
  };

  # Ensure firmware is available for GPU init
  hardware.enableRedistributableFirmware = true;
  boot.kernelParams = [ "i915.enable_guc=3" ];

  users.users.${config.hawker.username}.extraGroups = [ "video" "render" ];

  # Wayland + Intel environment
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
