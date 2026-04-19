# Hawker CLI scripts -- wrapped with writeShellApplication (bash)
# or writeScriptBin (fish) for explicit dependencies and shellcheck.
#
# Source files live in scripts/ at repo root. Nix wraps them at build time
# with runtime deps in PATH and HAWKER_PATH baked in.
{ pkgs, settings, ... }:

let
  src = ../../scripts;
  username = settings.username;
  hawkerPath = "/home/${username}/.local/share/hawker";

  # Wrap a bash script with writeShellApplication (gets shellcheck + set -euo pipefail)
  mkBash = name: { runtimeInputs ? [] }: pkgs.writeShellApplication {
    inherit name runtimeInputs;
    text = builtins.readFile "${src}/${name}.sh";
  };

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
    # Bash scripts with explicit deps
    (mkBash "hawker-container" {
      runtimeInputs = with pkgs; [ rsync openssh git nix coreutils ];
    })
    (mkBash "hawker-rofi-wallpaper-select" {
      runtimeInputs = with pkgs; [ rofi-wayland swaybg findutils coreutils ];
    })
    (mkBash "power-menu" {
      runtimeInputs = with pkgs; [ rofi-wayland systemd ];
    })

    # Fish scripts (HAWKER_PATH injected at build time)
    (mkFish "hawker-theme-set")
    (mkFish "hawker-theme-set-terminal")
    (mkFish "hawker-theme-set-desktop")
    (mkFish "hawker-theme-current")
    (mkFish "hawker-theme-list")
    (mkFish "hawker-theme-next")
    (mkFish "hawker-theme-prev")
    (mkFish "hawker-theme-refresh")
    (mkFish "hawker-theme-select-cli")
    (mkFish "hawker-rofi-theme-select")
    (mkFish "hawker-wallpaper-set")
    (mkFish "hawker-wallpaper-next")
    (mkFish "hawker-set-yazi-theme")
    (mkFish "volume-control")
  ];
}
