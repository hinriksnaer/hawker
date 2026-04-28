# Lazygit -- terminal UI for git.
{ pkgs, ... }:

{
  home.packages = [ pkgs.lazygit ];

  xdg.configFile."lazygit/config.yml" = {
    source = ../../../dotfiles/lazygit/.config/lazygit/config.yml;
  };
}
