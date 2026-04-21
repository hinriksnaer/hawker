# tmux config is managed by Home Manager (home/tmux.nix).
# This module only ensures tmux is available system-wide.
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.tmux ];
}
