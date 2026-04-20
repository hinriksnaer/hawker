{ pkgs, lib, ... }:

{
  imports = [
    ./tmux.nix
  ];

  # On desktop, NixOS home-manager integration sets these automatically.
  # For standalone use (container), they're set via homeConfigurations in flake.nix.
  home.username = lib.mkDefault "hawker";
  home.homeDirectory = lib.mkDefault "/home/hawker";
  home.stateVersion = "24.11";
}
