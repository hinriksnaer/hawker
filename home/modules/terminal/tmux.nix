# Tmux configuration -- shared across all profiles.
{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 50000;
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      yank
      {
        plugin = dotbar;
        # Dotbar settings must be set BEFORE the plugin runs
        extraConfig = ''
          set -g @tmux-dotbar-position top
          set -g @tmux-dotbar-fg "colour8"
          set -g @tmux-dotbar-bg "default"
          set -g @tmux-dotbar-fg-current "colour7"
          set -g @tmux-dotbar-fg-session "colour8"
          set -g @tmux-dotbar-fg-prefix "colour14"
        '';
      }
    ];

    extraConfig = ''
      set -g focus-events on
      set-option -sa terminal-overrides ",xterm*:Tc,tmux*:Tc"

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

      # Pane base index
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      # Shift arrow to switch windows
      bind -n S-Left  previous-window
      bind -n S-Right next-window

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # vi-mode copy
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Splits in current path
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';
  };
}
