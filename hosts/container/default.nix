# NixOS configuration for docker-nixos container.
# Applied via: nixos-rebuild switch --flake ~/hawker#container
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

  # Container-specific
  boot.isContainer = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  fileSystems."/" = { device = "none"; fsType = "tmpfs"; };

  networking.hostName = "hawker-dev";
  networking.useHostResolvConf = lib.mkForce false;

  # User
  users.users.${config.hawker.username} = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "video" "render" ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Nix
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" config.hawker.username ];
  };
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    openssh
    cacert
    git
  ];

  # Environment variables for CUDA/CDI
  environment.sessionVariables = {
    LD_LIBRARY_PATH = "/usr/lib64:${pkgs.stdenv.cc.cc.lib}/lib";
    TRITON_LIBCUDA_PATH = "/usr/lib64";
  };

  system.stateVersion = "24.11";
}
