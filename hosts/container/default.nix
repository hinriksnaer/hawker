{ config, pkgs, lib, ... }:

{
  imports = [
    # Base system (core packages, nix settings, locale)
    ../../modules/base.nix

    # Terminal component (same tools as desktop)
    ../../components/terminal.nix
  ];

  # Container-specific: no bootloader, no hardware
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  fileSystems."/" = { device = "none"; fsType = "tmpfs"; };

  # Container doesn't need a display manager or desktop
  networking.hostName = "hawker-dev";

  # SSH for remote access
  environment.systemPackages = with pkgs; [
    openssh
    cacert
  ];

  system.stateVersion = "24.11";
}
