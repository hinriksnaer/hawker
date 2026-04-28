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

  # Deploy yazi config files individually -- theme.toml is excluded because
  # hawker-theme-set-terminal writes it at runtime (can't write to nix store symlinks).
  xdg.configFile = {
    "yazi/yazi.toml".source = ../../../dotfiles/yazi/.config/yazi/yazi.toml;
    "yazi/keymap.toml".source = ../../../dotfiles/yazi/.config/yazi/keymap.toml;
    "yazi/init.lua".source = ../../../dotfiles/yazi/.config/yazi/init.lua;
    "yazi/theme-map.conf".source = ../../../dotfiles/yazi/.config/yazi/theme-map.conf;
  };
}
