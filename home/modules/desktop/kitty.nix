# Kitty terminal emulator.
# Theme colors loaded at runtime via include (swapped by hawker-theme-set).
{ ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "CaskaydiaMono Nerd Font";
      size = 9.0;
    };

    settings = {
      # Window
      window_padding_width = 14;
      window_padding_height = 14;
      hide_window_decorations = "yes";
      show_window_resize_notification = "no";
      confirm_os_window_close = 0;

      # Aesthetics
      cursor_shape = "block";
      enable_audio_bell = "no";
      single_instance = "yes";
      allow_remote_control = "yes";

      # Tab bar
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
    };

    keybindings = {
      "ctrl+insert" = "copy_to_clipboard";
      "shift+insert" = "paste_from_clipboard";
    };

    # Theme colors loaded at runtime (symlinked by hawker-theme-set)
    extraConfig = ''
      include theme.conf
    '';
  };
}
