# Remote server profile -- non-NixOS host with Nix installed.
# Apply with: home-manager switch --flake ~/workspace/hawker#remote
{ pkgs, settings, hostname, ... }:

let
  username = settings.hosts.${hostname}.username;
in
{
  imports = [
    ../collections/terminal.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";

  # hawker commands
  home.packages = [
    (pkgs.writeShellScriptBin "hawker-setup" (builtins.readFile ../../projects/hawker-setup.sh))
    (pkgs.writeShellScriptBin "hawker-refresh" (builtins.readFile ../../projects/hawker-refresh.sh))
  ];
}
