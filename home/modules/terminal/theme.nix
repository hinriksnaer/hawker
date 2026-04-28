# Hawker theme CLI -- provides theme switching commands.
# These are the same scripts from modules/core/theme/ but installed
# via Home Manager so they work on non-NixOS hosts.
{ pkgs, config, ... }:

let
  hawkerPath = "${config.home.homeDirectory}/.local/share/hawker";
  themeSrc = ../../../modules/core/theme;

  mkFish = name: pkgs.writeScriptBin name ''
    #!${pkgs.fish}/bin/fish
    set -gx HAWKER_PATH "${hawkerPath}"
    ${builtins.readFile "${themeSrc}/${name}.fish"}
  '';
in
{
  home.packages = [
    (mkFish "hawker-theme-set")
    (mkFish "hawker-theme-set-terminal")
    (mkFish "hawker-theme-current")
    (mkFish "hawker-theme-list")
    (mkFish "hawker-theme-next")
    (mkFish "hawker-theme-prev")
    (mkFish "hawker-theme-refresh")
    (mkFish "hawker-theme")
  ];

  home.sessionVariables.HAWKER_PATH = hawkerPath;

  # Deploy themes to ~/.local/share/hawker/themes/
  xdg.dataFile."hawker/themes" = {
    source = ../../../dotfiles/themes;
    recursive = true;
  };

  # Ensure runtime config directory exists with a default theme
  home.activation.hawkerConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p "$HOME/.config/hawker"
    if [ ! -f "$HOME/.config/hawker/current-theme" ]; then
      echo "ayu-dark" > "$HOME/.config/hawker/current-theme"
    fi
  '';
}
