# Tmux package + plugins. Config is in dotfiles/tmux/ (stow-managed).
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tmux
    tmuxPlugins.sensible
    tmuxPlugins.vim-tmux-navigator
    tmuxPlugins.yank
    tmuxPlugins.dotbar
  ];
}
