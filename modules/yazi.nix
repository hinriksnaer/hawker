{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    yazi

    # Yazi preview dependencies
    file
    ffmpegthumbnailer
    poppler-utils
    imagemagick
  ];
}
