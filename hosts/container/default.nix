{ config, pkgs, lib, ... }:

let
  # Read projects list directly from settings.nix for import decisions.
  # Can't use config.hawker.projects here -- imports can't depend on config.
  rawSettings = import ../../settings.nix { };
  projectsList = rawSettings.hawker.projects or [];

  # Auto-discover projects: any directory in projects/ with a default.nix
  projectsDir = ../../projects;
  allProjects = builtins.attrNames (
    lib.filterAttrs (name: type:
      type == "directory" && builtins.pathExists (projectsDir + "/${name}/default.nix")
    ) (builtins.readDir projectsDir)
  );

  enabledProjects = builtins.filter (p: builtins.elem p allProjects) projectsList;
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
