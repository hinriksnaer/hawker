{ ... }:

let
  hostSettings = (import ../../settings.nix { }).hawker.hosts.desktop;
in
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

  hawker.username = hostSettings.username;
  hawker.gpu = hostSettings.gpu;

  networking.hostName = "hawker";
}
