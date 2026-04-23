{ ... }:

let
  hostSettings = (import ../../settings.nix { }).hawker.hosts.desktop;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../roles/core.nix
    ../../roles/terminal.nix
    ../../roles/desktop.nix
    ../../roles/hardware.nix
    ../../roles/apps.nix
    ../../modules/fancontrol.nix
  ];

  hawker.username = hostSettings.username;
  hawker.gpu = hostSettings.gpu;

  networking.hostName = "hawker";
}
