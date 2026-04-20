{ pkgs, ... }:

{
  imports = [
    ./tmux.nix
  ];

  home.stateVersion = "24.11";
}
