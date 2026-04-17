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
    ../../components/dev.nix
    ../../components/media.nix

    # Core tools
    ../../modules/opencode.nix

    # Hardware
    ../../modules/nvidia.nix
    ../../modules/networking.nix
    ../../modules/bluetooth.nix
    ../../modules/fancontrol.nix
  ];

  networking.hostName = "hyprpunk";
}
