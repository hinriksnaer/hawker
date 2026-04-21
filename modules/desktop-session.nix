{ pkgs, ... }:

{
  # Polkit agent for privilege escalation dialogs
  security.polkit.enable = true;

  # PAM realtime limits (for Hyprland compositor scheduling)
  security.pam.loginLimits = [
    { domain = "@users"; item = "rtprio"; type = "-"; value = "99"; }
    { domain = "@users"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  # dconf/GSettings support
  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    # Polkit
    polkit_gnome

    # Cursors
    adwaita-icon-theme
    hyprcursor

    # GSettings
    gsettings-desktop-schemas
    glib

    # XDG
    xdg-user-dirs
    xdg-utils

    # Desktop utilities
    networkmanagerapplet  # nm-applet tray icon
  ];

  environment.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Adwaita";
    HYPRCURSOR_SIZE = "24";
    GTK_THEME = "Adwaita:dark";
    TERMINAL = "kitty";
  };

  # Dark mode preference via dconf -- detected by Firefox, Electron apps,
  # and anything that queries the XDG settings portal or GSettings.
  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };
  }];
}
