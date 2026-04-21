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
    ./hardware-configuration.nix

    ../../modules/core
    ../../modules/terminal
    ../../modules/desktop
    ../../modules/hardware
    ../../modules/apps
    ../../modules/desktop/proton-pass.nix

    # GPU drivers (must be explicit per-host)
    ../../modules/hardware/intel.nix
  ] ++ map projectDir (builtins.filter isEnabled allProjects);

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "hawker-laptop";
  networking.networkmanager.enable = true;

  # User
  users.users.${config.hawker.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "render" "audio" ];
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

  # Allow unfree packages (Proton Pass)
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    openssh
    cacert
    git
    vim
  ];

  system.stateVersion = "24.11";
}
