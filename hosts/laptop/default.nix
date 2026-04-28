{ ... }:

let
  hostSettings = (import ../../settings.nix { }).hawker.hosts.laptop;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../roles/core.nix
    ../../roles/desktop.nix
    ../../roles/hardware.nix
    ../../roles/apps.nix
    ../../roles/gaming.nix
  ];

  hawker.username = hostSettings.username;
  hawker.gpu = hostSettings.gpu;
  hawker.hyprlandHostConfig = ./hyprland.conf;

  networking.hostName = "hawker-laptop";
}
