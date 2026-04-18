{ ... }:

{
  imports = [
    # Compositor
    ../modules/hyprland.nix
    ../modules/sddm.nix
    ../modules/desktop-session.nix

    # Bar, launcher, notifications
    ../modules/waybar.nix
    ../modules/rofi.nix
    ../modules/mako.nix

    # Lock screen
    ../modules/hyprlock.nix

    # Utilities
    ../modules/screenshot.nix
    ../modules/cliphist.nix

    # Appearance
    ../modules/fonts.nix
  ];
}
