{ lib, ... }:

{
  imports = [
    ./tmux.nix
  ];

  home.username = lib.mkDefault "hawker";
  home.homeDirectory = lib.mkDefault "/home/hawker";
  home.stateVersion = "24.11";
}
