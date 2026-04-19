{ ... }:

{
  imports = [
    # Compositor
    ../modules/desktop/hyprland.nix
    ../modules/desktop/sddm.nix
    ../modules/desktop/desktop-session.nix

    # Bar, launcher, notifications
    ../modules/desktop/waybar.nix
    ../modules/desktop/rofi.nix
    ../modules/desktop/mako.nix

    # Lock screen
    ../modules/desktop/hyprlock.nix

    # Utilities
    ../modules/desktop/screenshot.nix
    ../modules/desktop/cliphist.nix

    # Appearance
    ../modules/desktop/fonts.nix
  ];
}
