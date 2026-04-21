{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Module groups (each default.nix auto-imports all modules in the dir)
    ../../modules/core
    ../../modules/terminal
    ../../modules/desktop
    ../../modules/hardware
    ../../modules/apps

    # GPU drivers (must be explicit per-host)
    ../../modules/hardware/nvidia.nix
  ];

  networking.hostName = "hawker";
}
