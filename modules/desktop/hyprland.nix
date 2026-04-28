{ pkgs, config, lib, ... }:

{
  options.hawker.hyprlandHostConfig = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = "Path to a per-host Hyprland config override file (layout, monitors, cursor).";
  };

  config = {
    # Hyprland compositor with UWSM for proper systemd session management
    # See: https://wiki.nixos.org/wiki/Hyprland
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    # XDG portal for screen sharing, file dialogs, etc.
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      config.common.default = "*";
    };

    environment.systemPackages = with pkgs; [
      # Wallpaper (swaybg only -- hyprpaper conflicts)
      swaybg

      # Wayland compatibility
      xwayland
      qt5.qtwayland
      qt6.qtwayland

      # Hyprland extras
      hyprland-qtutils
      wlr-randr
      wlogout
    ];

    # Auto-start Hyprland via UWSM on TTY login
    programs.fish.interactiveShellInit = ''
      if uwsm check may-start
          exec uwsm start hyprland-uwsm.desktop
      end
    '';

    # Wayland environment variables
    # Note: GDK_BACKEND is intentionally omitted -- GTK auto-detects Wayland
    # under Hyprland, and forcing it breaks XWayland apps (e.g. Unity games).
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      MOZ_ENABLE_WAYLAND = "1";
      CLUTTER_BACKEND = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    # Deploy per-host Hyprland overrides (layout, monitors, cursor)
    system.activationScripts.hyprlandHostConfig = lib.mkIf (config.hawker.hyprlandHostConfig != null) {
      deps = [ "users" "groups" ];
      text = let
        username = config.hawker.username;
        hostConfig = config.hawker.hyprlandHostConfig;
      in ''
        HYPR_DIR="/home/${username}/.config/hypr/conf.d"
        mkdir -p "$HYPR_DIR"
        rm -f "$HYPR_DIR/host.conf"
        cp "${hostConfig}" "$HYPR_DIR/host.conf"
        chown ${username}:users "$HYPR_DIR/host.conf"
      '';
    };
  };
}
