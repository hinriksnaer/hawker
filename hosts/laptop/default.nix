{ ... }:

let
  hostSettings = (import ../../settings.nix { }).hawker.hosts.laptop;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../roles/core.nix
    ../../roles/terminal.nix
    ../../roles/desktop.nix
    ../../roles/hardware.nix
    ../../roles/apps.nix
  ];

  hawker.username = hostSettings.username;
  hawker.gpu = hostSettings.gpu;

  networking.hostName = "hawker-laptop";
}
