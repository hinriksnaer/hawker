# Remote server profile -- non-NixOS host with Nix installed.
# Apply with: home-manager switch --flake ~/hawker#<user>@remote
{ pkgs, config, settings, hostname, ... }:

let
  username = settings.hosts.${hostname}.username;
  homeDir = "/home/${username}";
  reposDir = "${homeDir}/workspace/repos";
  hawkerRoot = "${homeDir}/hawker";
  cli = import ../../cli { inherit pkgs; hmProfile = "${username}@${hostname}"; };
in
{
  imports = [
    ../collections/terminal.nix
  ];

  home.username = username;
  home.homeDirectory = homeDir;
  home.stateVersion = "24.11";

  # hawker-hm-switch: pull latest + home-manager switch
  home.packages = [ cli.hawker-hm-switch ];

  # Auto-activate devshell when cd-ing into workspace/repos
  home.activation.setupDirenv = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p "${reposDir}"
    envrc="${reposDir}/.envrc"
    if [ ! -f "$envrc" ] || ! grep -q "use flake ${hawkerRoot}" "$envrc" 2>/dev/null; then
      echo "use flake ${hawkerRoot}" > "$envrc"
    fi
    ${pkgs.direnv}/bin/direnv allow "$envrc" 2>/dev/null || true
  '';
}
