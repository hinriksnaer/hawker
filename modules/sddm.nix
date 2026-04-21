{ pkgs, config, lib, ... }:

let
  hasNvidia = config.hawker.gpu == "nvidia";
in
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    extraPackages = [ pkgs.sddm-astronaut ];
    settings.Theme = {
      ThemeDir = "${pkgs.sddm-astronaut}/share/sddm/themes";
      CursorTheme = "Adwaita";
      CursorSize = "24";
    };
    settings.General = {
      GreeterEnvironment = if hasNvidia then
        "WLR_NO_HARDWARE_CURSORS=1,LIBVA_DRIVER_NAME=nvidia,GBM_BACKEND=nvidia-drm,__GLX_VENDOR_LIBRARY_NAME=nvidia,XCURSOR_THEME=Adwaita,XCURSOR_SIZE=24"
      else
        "XCURSOR_THEME=Adwaita,XCURSOR_SIZE=24";
    };
  };

  # Default cursor theme (makes Adwaita available system-wide including SDDM)
  environment.etc."icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=Adwaita
  '';

  # Override theme config with hawker colors
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

    HeaderText="HAWKER"
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
