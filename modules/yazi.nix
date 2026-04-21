{ pkgs, ... }:

{
  programs.yazi.enable = true;

  environment.systemPackages = with pkgs; [
    # Yazi preview dependencies
    file
    ffmpegthumbnailer
    poppler-utils
    imagemagick
  ];
}
