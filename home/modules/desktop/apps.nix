# Desktop applications and utilities.
# Single-package apps that don't need NixOS-level configuration.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Applications
    firefox
    discord
    slack
    obsidian

    # Screenshot
    grim
    slurp

    # Clipboard
    cliphist
    wl-clipboard
  ];
}
