{ pkgs, ... }:

{
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

  # Wayland environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    GDK_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}
