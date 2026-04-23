{
  description = "hawker - NixOS configuration. Chuck the system anywhere.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      # Common modules: user settings (imported by all machine configs)
      # Note: hawker-options.nix is imported via roles/core.nix
      commonModules = [
        ./settings.nix
      ];

      # Per-host settings (read directly, not through module system)
      settings = (import ./settings.nix { }).hawker;

      # Auto-discover .nix files from a directory
      discoverModules = dir:
        lib.mapAttrs'
          (name: _: lib.nameValuePair
            (lib.removeSuffix ".nix" name)
            (import (dir + "/${name}"))
          )
          (lib.filterAttrs
            (name: type: type == "regular" && lib.hasSuffix ".nix" name)
            (builtins.readDir dir)
          );

      # Auto-discover directories with default.nix
      discoverDirs = dir:
        lib.mapAttrs'
          (name: _: lib.nameValuePair name (import (dir + "/${name}")))
          (lib.filterAttrs
            (name: type: type == "directory" && builtins.pathExists (dir + "/${name}/default.nix"))
            (builtins.readDir dir)
          );

    in {

      # ── Individually importable modules (auto-discovered) ──
      nixosModules =
        (discoverModules ./modules) //
        (discoverModules ./roles) //
        (discoverDirs ./projects);

      # ── Machine configurations ──
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/desktop/default.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${settings.hosts.desktop.username} = import ./home;
            }
          ];
        };

        container = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/container/default.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${settings.hosts.container.username} = import ./home;
            }
          ];
        };

        # Alias used by bootstrap.sh to read default theme from container config
        default = self.nixosConfigurations.container;

        laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/laptop/default.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${settings.hosts.laptop.username} = import ./home;
            }
          ];
        };
      };

      # ── Checks (run via `nix flake check`) ──
      checks.${system} = let
        scriptTests = import ./tests { inherit pkgs; src = self; };
      in scriptTests // {
        vm-integration = import ./tests/vm-test.nix {
          inherit pkgs;
          hawkerConfig = self.nixosConfigurations.desktop.config.hawker;
        };
        container-build = self.packages.${system}.container;
      };

      # ── Packages ──
      packages.${system} = let
        containerConfig = self.nixosConfigurations.container.config;
        containerPackages = containerConfig.environment.systemPackages;
        containerSessionVars = containerConfig.environment.sessionVariables;
      in {
        # OCI container image (streamLayeredImage, built by Nix)
        container = import ./containers/default.nix {
          inherit pkgs;
          inherit (settings.hosts.container) username;
          packages = containerPackages;
          sessionVariables = containerSessionVars;
        };

        # Standalone CLI for managing containers (installable on any host with Nix)
        hawker-container = pkgs.writeShellScriptBin "hawker-container"
          (builtins.readFile ./containers/hawker-container.sh);
      };
    };
}
