# Container profile -- user "dev", terminal tools.
{ settings, hostname, ... }:

let
  username = settings.hosts.${hostname}.username;
in
{
  imports = [
    ../collections/terminal.nix
    # ../collections/desktop.nix     # not needed in container
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";
}
