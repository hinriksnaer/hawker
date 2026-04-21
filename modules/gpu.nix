# GPU driver configuration, dispatched by hawker.gpu option.
# Centralises driver selection, kernel modules, VAAPI, session variables,
# and SDDM greeter hints so that per-host configs only need to set one option.
{ config, lib, pkgs, ... }:

let
  cfg = config.hawker;
  gpu = cfg.gpu;
  hasNvidia = gpu == "nvidia";
  hasIntel  = gpu == "intel";
  hasAmd    = gpu == "amd";
in
{
  config = lib.mkMerge [

    # ── NVIDIA ──────────────────────────────────────────────────────────
    (lib.mkIf hasNvidia {
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      services.xserver.videoDrivers = [ "nvidia" ];

      boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [ nvidia-vaapi-driver ];
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };

      # NVIDIA container toolkit for podman / docker
      hardware.nvidia-container-toolkit.enable = true;
    })

    # ── Intel ───────────────────────────────────────────────────────────
    (lib.mkIf hasIntel {
      services.xserver.videoDrivers = [ "modesetting" ];

      boot.initrd.kernelModules = [ "i915" ];
      boot.kernelModules = [ "i915" ];
      boot.kernelParams = [ "i915.enable_guc=3" ];

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver   # VA-API (iHD) userspace
          vpl-gpu-rt           # oneVPL (QSV) runtime
        ];
      };

      hardware.enableRedistributableFirmware = true;

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "iHD";
      };
    })

    # ── AMD (placeholder) ──────────────────────────────────────────────
    (lib.mkIf hasAmd {
      services.xserver.videoDrivers = [ "amdgpu" ];

      boot.initrd.kernelModules = [ "amdgpu" ];

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [ amdvlk ];
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "radeonsi";
      };
    })

    # ── Common (all GPUs) ──────────────────────────────────────────────
    {
      users.users.${cfg.username}.extraGroups =
        [ "video" ] ++ lib.optional (hasIntel || hasAmd) "render";

      # Suppress nvidia-container-toolkit assertion on non-nvidia hosts
      hardware.nvidia-container-toolkit.suppressNvidiaDriverAssertion = !hasNvidia;
    }
  ];
}
