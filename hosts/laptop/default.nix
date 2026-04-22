{ config, pkgs, ... }:

let
  hostSettings = (import ../../settings.nix { }).hawker.hosts.laptop;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/core.nix
    ../../profiles/terminal.nix
    ../../profiles/desktop.nix
    ../../profiles/hardware.nix
    ../../profiles/apps.nix
  ];

  hawker.username = hostSettings.username;
  hawker.gpu = hostSettings.gpu;

  networking.hostName = "hawker-laptop";
}
