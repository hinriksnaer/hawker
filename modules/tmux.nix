# Tmux package + plugins. Config is in dotfiles/tmux/ (stow-managed).
# Plugins are Nix-managed -- this module generates a conf file with
# run-shell lines that the dotfile sources.
{ pkgs, ... }:

let
  plugins = with pkgs.tmuxPlugins; [
    sensible
    vim-tmux-navigator
    yank
    dotbar
  ];

  # Generate run-shell lines for each plugin's .tmux entry point
  pluginConf = pkgs.runCommand "tmux-plugin-conf" {} ''
    mkdir -p $out/etc
    : > $out/etc/tmux-plugins.conf
    for plugin in ${builtins.concatStringsSep " " (map (p: "${p}") plugins)}; do
      for f in "$plugin"/share/tmux-plugins/*/*.tmux; do
        [ -f "$f" ] && echo "run-shell '$f'" >> $out/etc/tmux-plugins.conf
      done
    done
  '';
in
{
  environment.systemPackages = [ pkgs.tmux pluginConf ] ++ plugins;
}
