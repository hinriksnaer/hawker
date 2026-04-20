# Minimal NixOS config for testing systemd-nspawn on RHEL
{ pkgs, lib, ... }:

{
  boot.isContainer = true;

  # No bootloader in containers
  boot.loader.grub.enable = false;

  # Basic networking
  networking.hostName = "hawker-test";

  # User
  users.users.hawker = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.bash;
    password = "test";
  };

  # Minimal packages
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # Allow password login for testing
  services.getty.autologinUser = "hawker";

  system.stateVersion = "24.11";
}
