# Hyprlock screen locker.
# Theme colors loaded at runtime via source (swapped by hawker-theme-set).
{ ... }:

{
  programs.hyprlock = {
    enable = true;

    extraConfig = ''
      source = ~/.config/hypr/hyprlock-theme.conf
    '';

    settings = {
      background = [{
        monitor = "";
        color = "$color";
        blur_passes = 3;
      }];

      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        grace = 0;
      };

      input-field = [{
        monitor = "";
        size = "400, 60";
        position = "0, 0";
        halign = "center";
        valign = "center";

        inner_color = "$inner_color";
        outer_color = "$outer_color";
        outline_thickness = 3;

        font_family = "CaskaydiaMono Nerd Font";
        font_color = "$font_color";

        placeholder_text = "Enter Password";
        check_color = "$check_color";
        fail_text = "<i>$FAIL ($ATTEMPTS)</i>";
        fail_color = "$fail_color";

        rounding = 0;
        shadow_passes = 0;
        fade_on_empty = false;
      }];
    };
  };
}
