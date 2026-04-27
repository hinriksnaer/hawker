# Laptop profile -- user "hgudmund", terminal + desktop tools.
{ settings, hostname, ... }:

let
  username = settings.hosts.${hostname}.username;
in
{
  imports = [
    ../collections/terminal.nix
    # ../collections/desktop.nix     # add when desktop modules exist
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";
}
