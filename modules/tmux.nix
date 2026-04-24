# Tmux — full config including plugins, all managed by Nix.
# The module generates /etc/tmux.conf with plugin run-shell lines
# using bash to handle streamLayeredImage permission issues.
{ pkgs, ... }:

let
  plugins = with pkgs.tmuxPlugins; [
    sensible
    vim-tmux-navigator
    yank
    dotbar
  ];

  pluginRunLines = builtins.concatStringsSep "\n" (map (p:
    ''run-shell "bash ${p}/share/tmux-plugins/${p.pluginName}/${p.pluginName}.tmux"''
  ) plugins);

  tmuxConf = pkgs.writeTextDir "etc/tmux.conf" ''
    set-option -sa terminal-overrides ",xterm*:Tc"
    set -g mouse on
    set -g escape-time 0
    set -g history-limit 50000
    set -g focus-events on

    unbind C-b
    set -g prefix C-Space
    bind C-Space send-prefix

    # Vim style pane selection
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R

    # Pane resizing (prefix + H/J/K/L, repeatable)
    bind -r H resize-pane -L 5
    bind -r J resize-pane -D 5
    bind -r K resize-pane -U 5
    bind -r L resize-pane -R 5

    # Start windows and panes at 1, not 0
    set -g base-index 1
    set -g pane-base-index 1
    set-window-option -g pane-base-index 1
    set-option -g renumber-windows on

    # Shift arrow to switch windows
    bind -n S-Left  previous-window
    bind -n S-Right next-window

    # Shift Alt vim keys to switch windows
    bind -n M-H previous-window
    bind -n M-L next-window

    # Dotbar theme
    set -g @tmux-dotbar-position top
    set -g @tmux-dotbar-fg "colour8"
    set -g @tmux-dotbar-bg "default"
    set -g @tmux-dotbar-fg-current "colour7"
    set -g @tmux-dotbar-fg-session "colour8"
    set -g @tmux-dotbar-fg-prefix "colour14"

    # vi-mode
    set-window-option -g mode-keys vi
    bind-key -T copy-mode-vi v send-keys -X begin-selection
    bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
    bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

    # Splits in current path
    bind '"' split-window -v -c "#{pane_current_path}"
    bind % split-window -h -c "#{pane_current_path}"

    # Plugins (Nix-managed, loaded via bash to handle permissions)
    ${pluginRunLines}
  '';
in
{
  environment.systemPackages = [ pkgs.tmux tmuxConf ] ++ plugins;
}
