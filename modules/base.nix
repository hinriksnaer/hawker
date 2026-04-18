{ config, pkgs, ... }:

{
  # ── Nix settings ──
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    max-jobs = "auto";
  };

  nixpkgs.config.allowUnfree = true;

  # ── Boot ──
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Locale ──
  time.timeZone = "Atlantic/Reykjavik";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Users ──
  users.users.softmax = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "docker" ];
    shell = pkgs.fish;  # requires fish.nix in the same host config
  };

  security.sudo.wheelNeedsPassword = false;

  # ── Core system packages ──
  environment.systemPackages = with pkgs; [
    stow
    curl
    wget
    which
    coreutils
    findutils
    gnused
    gnugrep
    gawk
    util-linux
    procps
    git
  ];

  # ── System services ──
  services.dbus.enable = true;

  system.stateVersion = "24.11";
}
