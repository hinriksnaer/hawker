# Desktop theme extensions -- GUI pickers, wallpaper management,
# and desktop-specific theme application (hyprland, waybar, mako, etc.).
# Consumes the core theme API from modules/core/theme/.
{ pkgs, config, ... }:

let
  src = ./.;
  username = config.hawker.username;
  hawkerPath = "/home/${username}/.local/share/hawker";

  mkBash = name: { runtimeInputs ? [] }: pkgs.writeShellApplication {
    inherit name runtimeInputs;
    text = builtins.readFile "${src}/${name}.sh";
    excludeShellChecks = [ "SC2029" "SC2016" ];
  };

  mkFish = name: pkgs.writeScriptBin name ''
    #!${pkgs.fish}/bin/fish
    set -gx HAWKER_PATH "${hawkerPath}"
    ${builtins.readFile "${src}/${name}.fish"}
  '';

in
{
  environment.systemPackages = [
    # Wallpaper picker (bash, uses rofi)
    (mkBash "hawker-rofi-wallpaper-select" {
      runtimeInputs = with pkgs; [ rofi swaybg findutils coreutils ];
    })

    # Desktop theme scripts (fish)
    (mkFish "hawker-theme-set-desktop")
    (mkFish "hawker-rofi-theme-select")
    (mkFish "hawker-wallpaper-set")
    (mkFish "hawker-wallpaper-next")
  ];
}
