# Yazi -- terminal file manager with preview support.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    yazi
    file              # MIME detection
    ffmpegthumbnailer # video thumbnails
    poppler-utils     # PDF preview
    imagemagick       # image preview
  ];

  xdg.configFile."yazi" = {
    source = ../../../dotfiles/yazi/.config/yazi;
    recursive = true;
  };
}
