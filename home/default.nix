# Root home-manager module.
# home.username and home.homeDirectory are set automatically by the
# NixOS home-manager module from the user key (home-manager.users.<name>).
{ ... }:

{
  imports = [
    ./fish.nix
    ./tmux.nix
  ];

  home.stateVersion = "24.11";
}
