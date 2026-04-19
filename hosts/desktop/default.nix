{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Base system
    ../../modules/base.nix

    # Components
    ../../components/terminal.nix
    ../../components/ui.nix
    ../../components/apps.nix
    ../../components/media.nix

    # Hardware
    ../../modules/nvidia.nix
    ../../modules/networking.nix
    ../../modules/bluetooth.nix
    ../../modules/fancontrol.nix
  ];

  networking.hostName = "hawker";
}
