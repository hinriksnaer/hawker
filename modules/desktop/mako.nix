{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mako
    libnotify  # provides notify-send
  ];
}
