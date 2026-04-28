# Hyprland window manager configuration.
# Theme colors loaded at runtime via source (swapped by hawker-theme-set).
# Per-host settings (monitor, layout) come from the profile via _module.args.
{ config, settings, hostname, ... }:

let
  hostSettings = settings.hosts.${hostname};
  isDesktop = hostname == "desktop";
  isLaptop = hostname == "laptop";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;  # NixOS system module installs Hyprland
    systemd.enable = false;  # UWSM or NixOS manages the session

    settings = {
      # ── Environment ──
      env = [
        "HAWKER_PATH,$HOME/.local/share/hawker"
      ];

      # ── Monitors ──
      monitor = if isDesktop
        then [ "HDMI-A-1, 7680x2160@120, auto, 1.5" ]
        else [ ", preferred, auto, 1" ];

      # ── Input ──
      input = {
        kb_layout = "us,is";
        kb_options = "compose:caps";
        follow_mouse = 1;
        mouse_refocus = false;
        sensitivity = 0;
      };

      # ── Appearance ──
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = if isDesktop then "master" else "dwindle";
        "col.active_border" = "rgba(ff6a1fee)";
        "col.inactive_border" = "rgba(595959aa)";
      };

      decoration = {
        rounding = 4;
        active_opacity = 1.0;
        inactive_opacity = 0.95;
        fullscreen_opacity = 1.0;
        dim_inactive = true;
        dim_strength = 0.15;

        shadow = {
          enabled = true;
          range = 2;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        blur = {
          enabled = true;
          size = 8;
          passes = 1;
          new_optimizations = true;
          xray = false;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
          "easeIn,0.42,0,1,1"
        ];
        animation = [
          "global, 1, 10, default"
          "border, 1, 3, easeOutQuint"
          "windows, 1, 5, easeOutQuint"
          "windowsIn, 1, 4, easeOutQuint, popin 87%"
          "windowsOut, 1, 2, linear, popin 87%"
          "windowsMove, 1, 7, easeOutQuint"
          "fadeIn, 1, 2, almostLinear"
          "fadeOut, 1, 2, almostLinear"
          "fade, 1, 3, quick"
          "layers, 1, 3, easeOutQuint"
          "layersIn, 1, 2, easeOutQuint, fade"
          "layersOut, 1, 2, easeOutQuint, fade"
          "fadeLayersIn, 1, 2, almostLinear"
          "fadeLayersOut, 1, 2, almostLinear"
          "workspaces, 0, 1, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        new_status = "slave";
        mfact = 0.5;
        orientation = "center";
        slave_count_for_center_master = 0;
        center_master_fallback = "right";
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        focus_on_activate = true;
        disable_autoreload = false;
        anr_missed_pings = 3;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
      };

      cursor = {
        no_hardware_cursors = true;
        hide_on_key_press = true;
      } // (if isDesktop then { default_monitor = "HDMI-A-1"; } else {});

      xwayland.force_zero_scaling = true;

      # ── Window rules ──
      windowrule = [
        "float, title:^(Open File|Save File|Open Folder)$"
        "float, class:^(pavucontrol|nm-connection-editor|blueman-manager|mpv|polkit-gnome-authentication-agent-1)$"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "opacity 0.95 0.85, class:^(kitty)$"
        "workspace 3, class:^(discord|Slack)$"
        "suppressevent maximize, class:.*"
      ];

      # ── Autostart ──
      exec-once = [
        "dbus-update-activation-environment --systemd --all"
        "nm-applet"
      ];

      # ── Keybinds ──
      "$mainMod" = "SUPER";

      bind = [
        # Emergency
        "CTRL ALT, BackSpace, exit,"

        # Applications
        "$mainMod, Return, exec, kitty"
        "$mainMod SHIFT, Return, togglespecialworkspace, emergency"
        "$mainMod, B, exec, firefox"
        "$mainMod, E, exec, kitty -e yazi"

        # Window management
        "$mainMod, Q, killactive,"
        "$mainMod SHIFT, E, exit,"
        "$mainMod, V, togglefloating,"
        "$mainMod, F, fullscreen,"
        "$mainMod, P, pseudo,"
        "$mainMod ALT, R, togglesplit,"
        ''$mainMod ALT, Space, exec, hyprctl keyword general:layout "$([ "$(hyprctl getoption general:layout -j | grep -o '"dwindle\|"master' | tr -d '"')" = "dwindle" ] && echo master || echo dwindle)"''

        # Focus (vim)
        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, j, movefocus, d"

        # Focus (arrows)
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Move windows
        "$mainMod ALT, h, movewindow, l"
        "$mainMod ALT, l, movewindow, r"
        "$mainMod ALT, k, movewindow, u"
        "$mainMod ALT, j, movewindow, d"

        # Resize windows
        "$mainMod CTRL, h, resizeactive, -50 0"
        "$mainMod CTRL, l, resizeactive, 50 0"
        "$mainMod CTRL, k, resizeactive, 0 -50"
        "$mainMod CTRL, j, resizeactive, 0 50"

        # Workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        "$mainMod, Tab, workspace, previous"
        "$mainMod SHIFT, L, workspace, e+1"
        "$mainMod SHIFT, H, workspace, e-1"

        # Move to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Move silently
        "$mainMod CTRL, 1, movetoworkspacesilent, 1"
        "$mainMod CTRL, 2, movetoworkspacesilent, 2"
        "$mainMod CTRL, 3, movetoworkspacesilent, 3"
        "$mainMod CTRL, 4, movetoworkspacesilent, 4"
        "$mainMod CTRL, 5, movetoworkspacesilent, 5"
        "$mainMod CTRL, 6, movetoworkspacesilent, 6"
        "$mainMod CTRL, 7, movetoworkspacesilent, 7"
        "$mainMod CTRL, 8, movetoworkspacesilent, 8"
        "$mainMod CTRL, 9, movetoworkspacesilent, 9"
        "$mainMod CTRL, 0, movetoworkspacesilent, 10"

        # Mouse
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Keyboard layout
        "$mainMod CTRL, Space, exec, hyprctl switchxkblayout all next"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };

    # Theme override (sourced last, colors overwrite defaults)
    extraConfig = ''
      source = ~/.config/hypr/active-theme.conf
    '';
  };
}
