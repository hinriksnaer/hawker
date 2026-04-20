{ config, pkgs, lib, ... }:

let
  # Auto-discover project option declarations so settings.nix can set
  # project values without importing the full project modules (which
  # pull in CUDA packages). Only options.nix is imported -- no config.
  projectsDir = ../../projects;
  projectOptions = lib.mapAttrsToList
    (name: _: projectsDir + "/${name}/options.nix")
    (lib.filterAttrs (name: type:
      type == "directory"
      && builtins.pathExists (projectsDir + "/${name}/options.nix")
    ) (builtins.readDir projectsDir));
in
{
  imports = [
    ./hardware-configuration.nix

    # Module groups (each default.nix auto-imports all modules in the dir)
    ../../modules/core
    ../../modules/terminal
    ../../modules/desktop
    ../../modules/hardware
    ../../modules/apps
  ] ++ projectOptions;

  networking.hostName = "hawker";
}
