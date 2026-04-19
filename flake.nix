{
  description = "hawker - NixOS configuration. Chuck the system anywhere.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      settings = import ./settings.nix;
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

        # Projects
        helion      = import ./projects/helion.nix;
        pytorch     = import ./projects/pytorch.nix;

        # Components (composable module collections)
        terminal          = import ./components/terminal.nix;
        terminal-headless = import ./components/terminal-headless.nix;
        ui          = import ./components/ui.nix;
        apps        = import ./components/apps.nix;
        media       = import ./components/media.nix;
      };

      # ── Machine configurations ──
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit settings; };
          modules = [
            ./hosts/desktop/default.nix
          ];
        };

        container = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit settings; };
          modules = [
            ./hosts/container/default.nix
          ];
        };
      };

      # ── Checks (run via `nix flake check`) ──
      checks.${system} = let
        scriptTests = import ./tests { inherit pkgs; src = self; };
      in scriptTests // {
        # NixOS VM integration test (requires KVM)
        vm-integration = import ./tests/vm-test.nix { inherit pkgs settings; };

        # Container image builds end-to-end
        container-build = self.packages.${system}.container;
      };

      # ── Dev shell (native Nix on any Linux host) ──
      devShells.${system}.default = let
        containerConfig = self.nixosConfigurations.container.config;
        containerPackages = containerConfig.environment.systemPackages;
        sessionVars = containerConfig.environment.sessionVariables;
        projects = builtins.concatStringsSep "," (settings.projects or []);
      in pkgs.mkShell {
        packages = containerPackages;

        shellHook = ''
          export HAWKER_PATH="$HOME/.local/share/hawker"
          export HAWKER_USER="${settings.username}"
          export HAWKER_PROJECTS="${projects}"

          # Project-specific env vars from NixOS module evaluation
          ${builtins.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") sessionVars
          )}

          # Non-NixOS hosts: expose host NVIDIA driver to Nix binaries.
          # libcuda.so lives in the host's /usr/lib64, not in the Nix store.
          if [ -d /usr/lib64 ] && [ ! -f /etc/NIXOS ]; then
            export LD_LIBRARY_PATH="/usr/lib64''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          fi

          # Run project setup scripts (idempotent)
          for project in ''${HAWKER_PROJECTS//,/ }; do
            setup="$HOME/hawker/containers/''${project}-setup.sh"
            if [ -f "$setup" ]; then
              bash "$setup"
            fi
          done
        '';
      };

      # ── Container image (for CI and hosts without Nix) ──
      packages.${system} = let
        containerConfig = self.nixosConfigurations.container.config;
        containerPackages = containerConfig.environment.systemPackages;
      in {
        container = import ./containers/default.nix {
          inherit pkgs settings;
          packages = containerPackages;
        };
      };
    };
}
