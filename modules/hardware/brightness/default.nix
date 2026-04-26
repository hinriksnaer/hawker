{ pkgs, config, ... }:

{
  environment.systemPackages = with pkgs; [
    brightnessctl

    # Brightness control script with OSD notifications
    (writeScriptBin "brightness-control" ''
      #!${fish}/bin/fish
      ${builtins.readFile ./brightness-control.fish}
    '')
  ];

  # Allow brightnessctl to adjust backlight without root
  users.users.${config.hawker.username}.extraGroups = [ "video" ];
}
