# NixOS configuration for docker-nixos container.
# Docker workarounds are handled by the docker-nixos base image via extendModules.
# This file only defines what's specific to the hawker dev environment.
{ config, pkgs, lib, ... }:

let
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
    ../../profiles/core.nix
    ../../profiles/terminal.nix
  ] ++ map projectDir (builtins.filter isEnabled allProjects);

  # Container user -- override the host username so base.nix and all
  # modules that reference config.hawker.username use "dev".
  hawker.username = lib.mkForce "dev";

  # Container user additions (base.nix creates the user, we add uid + groups)
  users.users.dev = {
    uid = lib.mkForce 1000;
    extraGroups = [ "video" "render" ];
  };

  # Nix
  nix.settings = {
    trusted-users = [ "root" "dev" ];
  };
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    openssh
    cacert
    git
  ];

  # ── Container-specific overrides ──
  # Security wrappers -- docker-nixos base handles the mount workaround
  # sudo needs setuid wrappers to work inside the container

  # Services that fail in unprivileged containers
  services.nscd.enable = false;
  system.nssModules = lib.mkForce [];
  systemd.oomd.enable = false;
  documentation.man.cache.enable = false;
  systemd.services.mandb.enable = false;

  # btopConfig runs before user creation; skip in containers
  system.activationScripts.btopConfig = lib.mkForce "";

  # Environment variables for CUDA/CDI
  environment.sessionVariables = {
    LD_LIBRARY_PATH = "/usr/lib64:${pkgs.stdenv.cc.cc.lib}/lib";
    TRITON_LIBCUDA_PATH = "/usr/lib64";
  };

  system.stateVersion = lib.mkForce "24.11";
}
