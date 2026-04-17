{ pkgs, ... }:

{
  # Enable Hyprland compositor
  programs.hyprland = {
    enable = true;
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
    # Wayland utilities
    hyprpaper
    swaybg
    grim
    slurp
    wl-clipboard
    cliphist
    wlr-randr
    wlogout

    # Wayland compatibility
    xwayland
    qt5.qtwayland
    qt6.qtwayland

    # Desktop utilities
    pavucontrol
    playerctl
    networkmanagerapplet
    polkit_gnome

    # Cursor themes
    adwaita-icon-theme
    hyprcursor

    # Hyprland utilities (hyprland-dialog for ANR manager)
    hyprland-qtutils

    # GSettings schemas
    gsettings-desktop-schemas
    glib

    # XDG utilities
    xdg-user-dirs
    xdg-utils
  ];

  # Wayland environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Adwaita";
    HYPRCURSOR_SIZE = "24";

  };

  # dconf/GSettings support (compiles schemas and wires XDG_DATA_DIRS)
  programs.dconf.enable = true;

  # Realtime scheduling for Hyprland (fixes "Failed to change process scheduling strategy")
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@users"; item = "rtprio"; type = "-"; value = "99"; }
    { domain = "@users"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Polkit agent for privilege escalation dialogs
  security.polkit.enable = true;
}
