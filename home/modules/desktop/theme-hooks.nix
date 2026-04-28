# Desktop theme hooks -- enables runtime theme switching for desktop apps.
# Deploys hook files to ~/.config/hawker/theme-hooks.d/ and creates
# empty theme include files so apps don't error on first boot.
{ config, ... }:

{
  # Deploy theme hook definitions
  xdg.configFile = {
    "hawker/theme-hooks.d/00-waybar".text = ''
      source=waybar.css
      target=~/.config/waybar/theme.css
      reload=pkill -SIGUSR2 -f waybar
    '';
    "hawker/theme-hooks.d/02-kitty".text = ''
      source=kitty.conf
      target=~/.config/kitty/theme.conf
      reload=pkill -SIGUSR1 -f kitty
    '';
    "hawker/theme-hooks.d/03a-rofi".text = ''
      source=rofi.rasi
      target=~/.config/rofi/theme.rasi
    '';
    "hawker/theme-hooks.d/04-hyprlock".text = ''
      source=hyprlock.conf
      target=~/.config/hypr/hyprlock-theme.conf
    '';
    "hawker/theme-hooks.d/06-mako".text = ''
      source=mako.ini
      target=~/.config/mako/theme.conf
      reload=pkill -f mako; sleep 0.3; setsid mako >/dev/null 2>&1 &
    '';
    "hawker/theme-hooks.d/07-hyprland".text = ''
      type=hyprland
      reload=hyprctl reload
    '';
  };

  # Create empty theme include files so apps don't error before first theme-set
  home.activation.desktopThemeFiles = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p "$HOME/.config/hypr/wallpapers"
    [ -e "$HOME/.config/kitty/theme.conf" ]         || touch "$HOME/.config/kitty/theme.conf"
    [ -e "$HOME/.config/rofi/theme.rasi" ]           || touch "$HOME/.config/rofi/theme.rasi"
    [ -e "$HOME/.config/waybar/theme.css" ]          || touch "$HOME/.config/waybar/theme.css"
    [ -e "$HOME/.config/hypr/active-theme.conf" ]    || touch "$HOME/.config/hypr/active-theme.conf"
    [ -e "$HOME/.config/hypr/hyprlock-theme.conf" ]  || touch "$HOME/.config/hypr/hyprlock-theme.conf"
    [ -e "$HOME/.config/mako/theme.conf" ]           || touch "$HOME/.config/mako/theme.conf"
  '';
}
