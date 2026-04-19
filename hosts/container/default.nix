{ config, pkgs, lib, settings, ... }:

let
  # Auto-discover projects: any directory in projects/ with a default.nix
  projectsDir = ../../projects;
  allProjects = builtins.attrNames (
    lib.filterAttrs (name: type:
      type == "directory" && builtins.pathExists (projectsDir + "/${name}/default.nix")
    ) (builtins.readDir projectsDir)
  );

  # Only import projects listed in settings.projects
  enabledProjects = builtins.filter (p: builtins.elem p allProjects) (settings.projects or []);
  enabledModules = map (p: projectsDir + "/${p}") enabledProjects;
in
{
  imports = [
    ../../modules/core/base.nix
    ../../components/terminal-headless.nix
  ] ++ enabledModules;

  # Helion backends from settings (only applies if helion is enabled)
  helion.backends = lib.mkIf (builtins.elem "helion" enabledProjects)
    (settings.helion.backends or [ "cuda" ]);

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
