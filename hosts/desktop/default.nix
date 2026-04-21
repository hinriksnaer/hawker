{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/core.nix
    ../../profiles/terminal.nix
    ../../profiles/desktop.nix
    ../../profiles/hardware.nix
    ../../profiles/apps.nix
    ../../modules/fancontrol.nix
  ];

  hawker.gpu = "nvidia";

  networking.hostName = "hawker";
}
