# Remote server profile -- non-NixOS host with Nix installed.
# Apply with: home-manager switch --flake ~/hawker#remote
{ pkgs, config, settings, hostname, ... }:

let
  username = settings.hosts.${hostname}.username;
  homeDir = "/home/${username}";
  reposDir = "${homeDir}/workspace/repos";
  hawkerRoot = "${homeDir}/hawker";
in
{
  imports = [
    ../collections/terminal.nix
    ../modules/desktop/vscode.nix
  ];

  home.username = username;
  home.homeDirectory = homeDir;
  home.stateVersion = "24.11";

  # hawker commands
  home.packages = [
    (pkgs.writeShellScriptBin "hawker-setup" (builtins.readFile ../../projects/hawker-setup.sh))
    (pkgs.writeShellScriptBin "hawker-refresh" (builtins.readFile ../../projects/hawker-refresh.sh))
  ];

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
