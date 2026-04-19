{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    yazi
    file
    ffmpegthumbnailer
    poppler-utils
    imagemagick
  ];
}
