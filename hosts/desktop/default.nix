{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Base system
    ../../modules/core/base.nix

    # Components
    ../../components/terminal.nix
    ../../components/ui.nix
    ../../components/apps.nix
    ../../components/media.nix

    # Hardware
    ../../modules/hardware/nvidia.nix
    ../../modules/hardware/networking.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/fancontrol.nix
  ];

  networking.hostName = "hawker";
}
