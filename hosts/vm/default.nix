# NixOS configuration for KVM VM on GPU servers.
# Full NixOS with nixos-rebuild, home-manager, and GPU via VFIO passthrough.
{ config, pkgs, lib, ... }:

let
  # Which projects to import.
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
    ./hardware-configuration.nix

    ../../modules/core
    ../../modules/terminal
  ] ++ map projectDir (builtins.filter isEnabled allProjects);

  # Boot (KVM VM with UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # NVIDIA GPU (passed through via VFIO on the host)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false;
    modesetting.enable = false;  # headless GPU server
  };
  hardware.graphics.enable = true;

  # Networking
  networking.hostName = "hawker-dev";
  networking.networkmanager.enable = true;

  # User
  users.users.${config.hawker.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "render" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" config.hawker.username ];
      max-jobs = "auto";
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree (NVIDIA, CUDA)
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    openssh
    cacert
    git
    vim
  ];

  system.stateVersion = "24.11";
}
