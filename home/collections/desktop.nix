# Desktop collection -- Hyprland desktop environment.
# Import this in desktop/laptop profiles alongside terminal.nix.
{ ... }:

{
  imports = [
    ../modules/desktop/hyprland.nix
    ../modules/desktop/kitty.nix
    ../modules/desktop/mako.nix
    ../modules/desktop/waybar.nix
    ../modules/desktop/rofi.nix
    ../modules/desktop/hyprlock.nix
    ../modules/desktop/vscode.nix
    ../modules/desktop/theme-hooks.nix
  ];
}
