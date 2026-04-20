{ config, pkgs, lib, ... }:

let
  # Which projects to import. Read directly from settings.nix because
  # NixOS imports can't depend on config (evaluated before config merges).
  settings = (import ../../settings.nix { }).hawker.container.projects or {};
  isEnabled = name: (settings.${name}.enable or false) == true;
  projectDir = name: ../../projects + "/${name}";
  hasProject = name: builtins.pathExists (projectDir name + "/default.nix");

  allProjects = builtins.attrNames (
    lib.filterAttrs (n: t: t == "directory" && hasProject n)
      (builtins.readDir ../../projects)
  );
in
{
  imports = [
    ../../modules/core
    ../../modules/terminal
  ] ++ map projectDir (builtins.filter isEnabled allProjects);

  # Container-specific: no bootloader, no hardware
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  fileSystems."/" = { device = "none"; fsType = "tmpfs"; };

  networking.hostName = "hawker-dev";

  environment.systemPackages = with pkgs; [
    openssh
    cacert
  ];

  system.stateVersion = "24.11";
}
