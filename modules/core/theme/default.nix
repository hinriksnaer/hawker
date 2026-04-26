# Hawker theme API -- core theme scripts that work everywhere
# (terminal, container, desktop). Desktop-specific extensions
# (rofi pickers, wallpapers, hyprland theming) live in modules/desktop/theme/.
#
# Scripts are co-located in this directory. Nix wraps them at build time
# with runtime deps in PATH and HAWKER_PATH baked in.
{ pkgs, config, ... }:

let
  src = ./.;
  username = config.hawker.username;
  hawkerPath = "/home/${username}/.local/share/hawker";

  # Wrap a fish script with HAWKER_PATH set at build time
  mkFish = name: pkgs.writeScriptBin name ''
    #!${pkgs.fish}/bin/fish
    set -gx HAWKER_PATH "${hawkerPath}"
    ${builtins.readFile "${src}/${name}.fish"}
  '';

in
{
  # Set HAWKER_PATH globally so all shells and processes see it
  environment.sessionVariables.HAWKER_PATH = hawkerPath;

  environment.systemPackages = [
    (mkFish "hawker-theme-set")
    (mkFish "hawker-theme-set-terminal")
    (mkFish "hawker-theme-current")
    (mkFish "hawker-theme-list")
    (mkFish "hawker-theme-next")
    (mkFish "hawker-theme-prev")
    (mkFish "hawker-theme-refresh")
    (mkFish "hawker-theme-select-cli")
  ];
}
