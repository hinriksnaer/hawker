{ config, pkgs, ... }:

{
  # NVIDIA proprietary drivers
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Use NVIDIA as primary GPU
  services.xserver.videoDrivers = [ "nvidia" ];

  # Load NVIDIA kernel modules early at boot so DRM/KMS is ready for Hyprland
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  # Hardware acceleration with NVIDIA
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  # Wayland + NVIDIA environment
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
