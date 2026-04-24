# Tmux package + plugins. Config is in dotfiles/tmux/ (stow-managed).
# Plugins are Nix-managed -- this module generates /etc/tmux-plugins.conf
# with run-shell lines pointing to Nix store paths. The dotfile sources it.
{ pkgs, ... }:

let
  plugins = with pkgs.tmuxPlugins; [
    sensible
    vim-tmux-navigator
    yank
    dotbar
  ];

  # Generate run-shell lines for each plugin's .tmux entry point.
  # Uses "bash <script>" instead of direct execution because
  # streamLayeredImage may not preserve the execute bit on Nix store files.
  pluginConf = pkgs.runCommand "tmux-plugin-conf" {} (
    "mkdir -p $out/etc\n"
    + ": > $out/etc/tmux-plugins.conf\n"
    + builtins.concatStringsSep "\n" (map (p:
      ''for f in ${p}/share/tmux-plugins/*/*.tmux; do [ -f "$f" ] && echo "run-shell 'bash $f'" >> $out/etc/tmux-plugins.conf; done''
    ) plugins)
  );
in
{
  environment.systemPackages = [ pkgs.tmux pluginConf ] ++ plugins;
}
