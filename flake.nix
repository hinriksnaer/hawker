{
  description = "hyprpunk - NixOS configuration with modular tooling and dotfile management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {

      # ── Individually importable modules ──
      nixosModules = {
        # Base
        base        = import ./modules/base.nix;

        # Shell & CLI
        fish        = import ./modules/fish.nix;
        cli-tools   = import ./modules/cli-tools.nix;

        # Editors
        neovim      = import ./modules/neovim.nix;

        # Terminal tools
        tmux        = import ./modules/tmux.nix;
        btop        = import ./modules/btop.nix;
        lazygit     = import ./modules/lazygit.nix;
        yazi        = import ./modules/yazi.nix;
        gh          = import ./modules/gh.nix;

        # Desktop
        hyprland    = import ./modules/hyprland.nix;
        kitty       = import ./modules/kitty.nix;
        rofi        = import ./modules/rofi.nix;
        hyprlock    = import ./modules/hyprlock.nix;
        waybar      = import ./modules/waybar.nix;
        mako        = import ./modules/mako.nix;
        thunar      = import ./modules/thunar.nix;
        fonts       = import ./modules/fonts.nix;
        audio       = import ./modules/audio.nix;
        multimedia  = import ./modules/multimedia.nix;
        firefox     = import ./modules/firefox.nix;
        discord     = import ./modules/discord.nix;
        obsidian    = import ./modules/obsidian.nix;

        # Session
        sddm            = import ./modules/sddm.nix;
        desktop-session = import ./modules/desktop-session.nix;
        screenshot      = import ./modules/screenshot.nix;
        cliphist        = import ./modules/cliphist.nix;

        # Hardware
        nvidia      = import ./modules/nvidia.nix;
        bluetooth   = import ./modules/bluetooth.nix;
        networking  = import ./modules/networking.nix;
        fancontrol  = import ./modules/fancontrol.nix;

        # Components (composable module collections)
        terminal    = import ./components/terminal.nix;
        ui          = import ./components/ui.nix;
        apps        = import ./components/apps.nix;
        media       = import ./components/media.nix;
      };

      # ── Machine configurations ──
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/desktop/default.nix
          ];
        };
      };

      # ── Container images ──
      packages.${system} = {
        container = import ./containers/default.nix { inherit pkgs; };
      };
    };
}
