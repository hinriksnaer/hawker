{ config, pkgs, lib, ... }:

{
  imports = [
    # Base system
    ../../modules/base.nix

    # Terminal tools (same as desktop)
    ../../components/terminal.nix

    # Helion (Python + PyTorch + CUDA + Triton + dev deps)
    ../../modules/helion.nix
  ];

  # Container-specific: no bootloader, no hardware
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  fileSystems."/" = { device = "none"; fsType = "tmpfs"; };

  networking.hostName = "hyprpunk-helion";

  environment.systemPackages = with pkgs; [
    openssh
    cacert
  ];

  system.stateVersion = "24.11";
}
