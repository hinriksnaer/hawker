{ pkgs, config, ... }:

{
  environment.systemPackages = with pkgs; [
    brightnessctl
  ];

  # Allow brightnessctl to adjust backlight without root
  users.users.${config.hawker.username}.extraGroups = [ "video" ];
}
