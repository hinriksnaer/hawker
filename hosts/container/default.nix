{ config, pkgs, lib, ... }:

let
  # Read project enable flags from settings.nix for import decisions.
  # Can't use config here -- imports can't depend on config.
  rawSettings = import ../../settings.nix { };
  rawProjects = rawSettings.hawker.container.projects or {};

  # Auto-discover projects: any directory in projects/ with a default.nix
  projectsDir = ../../projects;
  allProjects = builtins.attrNames (
    lib.filterAttrs (name: type:
      type == "directory" && builtins.pathExists (projectsDir + "/${name}/default.nix")
    ) (builtins.readDir projectsDir)
  );

  # Import projects where enable = true
  enabledProjects = builtins.filter
    (p: (rawProjects.${p}.enable or false) == true)
    allProjects;
  enabledModules = map (p: projectsDir + "/${p}") enabledProjects;
in
{
  imports = [
    ../../modules/core
    ../../modules/terminal
  ] ++ enabledModules;

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
