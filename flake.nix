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

        # Alias for docker-nixos bootstrap (options.nix defaults to "default")
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

      # ── Development shell (shared across all projects) ──
      devShells.${system}.default = import ./projects/shell.nix {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      };

      # ── Packages ──
      packages.${system} = {
        # OCI container image (docker-nixos base, pinned)
        container = import ./containers/default.nix { inherit pkgs; };

        # Standalone CLI for managing containers (installable on any host with Nix)
        hawker-container = pkgs.writeShellScriptBin "hawker-container"
          (builtins.readFile ./containers/hawker-container.sh);
      };
    };
}
