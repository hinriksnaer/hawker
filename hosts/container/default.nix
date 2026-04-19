{ config, pkgs, lib, settings, ... }:

let
  # Map project names to their NixOS modules
  projectModules = {
    helion  = ../../projects/helion.nix;
    pytorch = ../../projects/pytorch.nix;
  };

  # Import modules for each enabled project
  enabledModules = builtins.filter (m: m != null)
    (map (p: projectModules.${p} or null) (settings.projects or []));
in
{
  imports = [
    # Base system (core packages, nix settings, locale)
    ../../modules/core/base.nix

    # Terminal tools (headless -- no kitty/Wayland deps)
    ../../components/terminal-headless.nix
  ] ++ enabledModules;

  # Helion backends from settings (only applies if helion module is imported)
  helion.backends = lib.mkIf (builtins.elem "helion" (settings.projects or []))
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
