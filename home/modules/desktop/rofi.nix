# Rofi application launcher (Wayland).
# Theme loaded at runtime via @theme directive (swapped by hawker-theme-set).
{ pkgs, config, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    extraConfig = {
      show-icons = true;
      icon-theme = "Papirus";
      display-drun = "Applications";
      display-run = "Run";
      display-window = "Windows";
      display-ssh = "SSH";
      drun-display-format = "{name}";
      modi = "drun,run,window";
      sidebar-mode = true;
      hover-select = true;
      me-select-entry = "";
      me-accept-entry = "MousePrimary";
      show-match = false;
    };

    # Theme file swapped at runtime by hawker-theme-set
    theme = "${config.home.homeDirectory}/.config/rofi/theme.rasi";
  };
}
