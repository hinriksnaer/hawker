{ ... }:

let
  hostSettings = (import ../../settings.nix { }).hawker.hosts.desktop;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../roles/core.nix
    ../../roles/desktop.nix
    ../../roles/hardware.nix
    ../../roles/apps.nix
    ../../roles/gaming.nix
    ../../modules/hardware/fancontrol.nix
  ];

  hawker.username = hostSettings.username;
  hawker.gpu = hostSettings.gpu;

  networking.hostName = "hawker";
}
