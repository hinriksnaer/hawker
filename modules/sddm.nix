{ pkgs, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    extraPackages = [ pkgs.sddm-astronaut ];
    settings.Theme.ThemeDir = "${pkgs.sddm-astronaut}/share/sddm/themes";
  };

  # UWSM manages Hyprland as a systemd session (proper env vars, service ordering)
  programs.uwsm = {
    enable = true;
    waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/Hyprland";
    };
  };

  environment.etc."sddm.conf.d/theme.conf".text = ''
    [Theme]
    ThemeDir=${pkgs.sddm-astronaut}/share/sddm/themes
    Current=sddm-astronaut-theme
  '';

  # Override theme config with hyprpunk colors
  environment.etc."sddm/themes/sddm-astronaut-theme/theme.conf.user".text = ''
    [General]
    Background="Backgrounds/cyberpunk.png"
    CropBackground="true"
    DimBackground="0.3"
    FormPosition="center"
    PartialBlur="true"
    FullBlur="false"
    BlurMax="20"
    Blur="1.0"
    HaveFormBackground="true"
    RoundCorners="8"
    HideSystemButtons="false"
    ForceLastUser="true"
    PasswordFocus="true"

    HeaderText="HYPRPUNK"
    DateFormat="dddd, MMMM d"

    HeaderTextColor="#FF6A1F"
    DateTextColor="#E2E6F1"
    TimeTextColor="#1BC5C9"

    FormBackgroundColor="#0F1016"
    BackgroundColor="#0F1016"
    DimBackgroundColor="#0F1016"

    LoginFieldBackgroundColor="#272A34"
    PasswordFieldBackgroundColor="#272A34"
    LoginFieldTextColor="#E2E6F1"
    PasswordFieldTextColor="#E2E6F1"
    UserIconColor="#FF6A1F"
    PasswordIconColor="#1BC5C9"

    PlaceholderTextColor="#3D4555"
    WarningColor="#FF6A1F"

    LoginButtonTextColor="#0F1016"
    LoginButtonBackgroundColor="#FF6A1F"
    SystemButtonsIconsColor="#1BC5C9"
    SessionButtonTextColor="#1BC5C9"

    DropdownTextColor="#E2E6F1"
    DropdownSelectedBackgroundColor="#FF6A1F"
    DropdownBackgroundColor="#272A34"

    HighlightTextColor="#0F1016"
    HighlightBackgroundColor="#FF6A1F"
    HighlightBorderColor="#FF6A1F"

    HoverUserIconColor="#1BC5C9"
    HoverPasswordIconColor="#FF6A1F"
    HoverSystemButtonsIconsColor="#FF6A1F"
    HoverSessionButtonTextColor="#FF6A1F"
  '';
}
