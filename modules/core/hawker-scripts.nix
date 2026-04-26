# Hawker CLI scripts -- non-theme utility scripts.
#
# Source files live in scripts/ at repo root. Nix wraps them at build time
# with runtime deps in PATH.
{ pkgs, config, ... }:

let
  src = ../../scripts;
  username = config.hawker.username;
  hawkerPath = "/home/${username}/.local/share/hawker";

  # Wrap a bash script with writeShellApplication (gets shellcheck + set -euo pipefail)
  mkBash = name: { runtimeInputs ? [] }: pkgs.writeShellApplication {
    inherit name runtimeInputs;
    text = builtins.readFile "${src}/${name}.sh";
    excludeShellChecks = [ "SC2029" "SC2016" ];
  };

  # Wrap a fish script with HAWKER_PATH set at build time
  mkFish = name: pkgs.writeScriptBin name ''
    #!${pkgs.fish}/bin/fish
    set -gx HAWKER_PATH "${hawkerPath}"
    ${builtins.readFile "${src}/${name}.fish"}
  '';

in
{
  environment.systemPackages = [
    # Bash scripts
    (mkBash "hawker-build" {
      runtimeInputs = with pkgs; [ coreutils ];
    })
    (mkBash "power-menu" {
      runtimeInputs = with pkgs; [ rofi systemd ];
    })

    # Fish scripts
    (mkFish "volume-control")
    (mkFish "brightness-control")
  ];
}
