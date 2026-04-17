{ ... }:

{
  imports = [
    # All terminal/dev tooling
    ./tooling.nix

    # Core tools -- enable from the start so opencode works on first boot
    ../modules/opencode.nix

    # Desktop environment
    # TODO: uncomment after tooling is verified
    ../modules/hyprland.nix
    ../modules/kitty.nix
    ../modules/rofi.nix
    ../modules/hyprlock.nix
    ../modules/waybar.nix
    ../modules/mako.nix
    ../modules/thunar.nix
    ../modules/proton-pass.nix

    # Fonts -- safe to enable early, unlikely to break
    ../modules/fonts.nix

    # Audio & multimedia
    # TODO: uncomment after desktop environment works
    # ../modules/audio.nix
    # ../modules/multimedia.nix

    # Applications
    # TODO: uncomment after audio/multimedia works
    # ../modules/flatpak.nix
    # ../modules/zen-browser.nix
    # ../modules/discord.nix
    # ../modules/obsidian.nix
  ];
}
