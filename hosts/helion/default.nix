{ config, pkgs, lib, ... }:

{
  imports = [
    # Base system
    ../../modules/base.nix

    # Terminal tools (same as desktop)
    ../../components/terminal.nix

    # Helion
    ../../modules/helion.nix
  ];

  # Backend selection (cuda, rocm, cpu when added)
  helion.backend = "cuda";

  # Container-specific: no bootloader, no hardware
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  fileSystems."/" = { device = "none"; fsType = "tmpfs"; };

  networking.hostName = "hawker-helion";

  environment.systemPackages = with pkgs; [
    openssh
    cacert
  ];

  system.stateVersion = "24.11";
}
