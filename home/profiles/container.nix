# Container profile -- user "dev", terminal tools only.
{ settings, hostname, ... }:

let
  username = settings.hosts.${hostname}.username;
in
{
  imports = [
    ../modules/terminal/git.nix
    # ../modules/terminal/fish.nix     # add when ready
    # ../modules/terminal/tmux.nix     # add when ready
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";
}
