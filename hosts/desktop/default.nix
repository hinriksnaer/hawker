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
  ];

  networking.hostName = "hawker";
}
