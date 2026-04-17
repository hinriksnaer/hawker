{ pkgs, ... }:

{
  # Polkit agent for privilege escalation dialogs
  security.polkit.enable = true;

  # Realtime scheduling (prevents "Failed to change process scheduling strategy")
  security.rtkit.enable = true;
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
    networkmanagerapplet
  ];

  environment.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Adwaita";
    HYPRCURSOR_SIZE = "24";
  };
}
