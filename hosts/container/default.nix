{ config, pkgs, lib, ... }:

let
  # Read projects list directly from settings.nix for import decisions.
  # Can't use config.hawker.projects here -- imports can't depend on config.
  rawSettings = import ../../settings.nix { };
  projectsList = rawSettings.hawker.container.projects or [];

  # Auto-discover projects: any directory in projects/ with a default.nix
  projectsDir = ../../projects;
  allProjectDirs = lib.filterAttrs (name: type:
    type == "directory" && builtins.pathExists (projectsDir + "/${name}/default.nix")
  ) (builtins.readDir projectsDir);
  allProjects = builtins.attrNames allProjectDirs;

  enabledProjects = builtins.filter (p: builtins.elem p allProjects) projectsList;
  enabledModules = map (p: projectsDir + "/${p}") enabledProjects;

  # Import all project options.nix so settings.nix can define values for
  # disabled projects without causing "option does not exist" errors.
  allProjectOptions = lib.mapAttrsToList
    (name: _: projectsDir + "/${name}/options.nix")
    (lib.filterAttrs (name: _:
      builtins.pathExists (projectsDir + "/${name}/options.nix")
    ) allProjectDirs);
in
{
  imports = [
    ../../modules/core
    ../../modules/terminal
  ] ++ enabledModules ++ allProjectOptions;

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
