# Central CLI packaging. All scripts use writeShellApplication for
# consistent shellcheck validation, set -euo pipefail, and runtimeInputs.
#
# hmProfile: the homeConfigurations key (e.g. "hgudmund@remote").
#            Required for hawker-hm-switch. Pass null when not needed.
{ pkgs, hmProfile ? null }:

{
  # NixOS hosts: nixos-rebuild switch
  hawker-switch = pkgs.writeShellApplication {
    name = "hawker-switch";
    runtimeInputs = with pkgs; [ coreutils hostname ];
    text = builtins.readFile ./hawker-switch.sh;
  };

  # Non-NixOS hosts: git pull + home-manager switch
  hawker-hm-switch = assert hmProfile != null;
    pkgs.writeShellApplication {
      name = "hawker-hm-switch";
      runtimeInputs = with pkgs; [ git ];
      text = ''
        HAWKER_ROOT="''${HAWKER_ROOT:-$HOME/hawker}"
        echo ":: pulling latest config"
        git -C "$HAWKER_ROOT" pull --ff-only
        echo ":: applying Home Manager (${hmProfile})"
        home-manager switch --flake "$HAWKER_ROOT#${hmProfile}" "$@"
        echo ":: done — run 'direnv reload' to pick up devshell changes"
      '';
    };

  # Devshell: project setup/build/status/update/clean
  hawker-dev = pkgs.writeShellApplication {
    name = "hawker-dev";
    text = builtins.readFile ./hawker-dev.sh;
    excludeShellChecks = [ "SC2086" "SC2155" ];
  };
}
