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

      # Common modules: options + user settings (imported by all machine configs)
      commonModules = [
        ./modules/core/hawker-options.nix
        ./settings.nix
      ];

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

      # Access hawker config from a nixosConfiguration
      hawkerConfig = self.nixosConfigurations.container.config.hawker;

    in {

      # ── Individually importable modules (auto-discovered) ──
      nixosModules =
        (discoverModules ./modules/core) //
        (discoverModules ./modules/terminal) //
        (discoverModules ./modules/desktop) //
        (discoverModules ./modules/hardware) //
        (discoverModules ./modules/ai) //
        (discoverModules ./modules/apps) //
        (discoverDirs ./modules) //
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
              home-manager.users.${(import ./settings.nix { }).hawker.username} = import ./home;
            }
          ];
        };

        container = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/container/default.nix
          ];
        };
      };

      # ── Standalone Home Manager (for use inside containers) ──
      homeConfigurations = {
        "${(import ./settings.nix { }).hawker.username}" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home ];
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

      # ── Container image ──
      packages.${system} = let
        containerConfig = self.nixosConfigurations.container.config;
        containerPackages = containerConfig.environment.systemPackages;
        containerSessionVars = containerConfig.environment.sessionVariables;
        # Derive enabled projects list from enable flags
        enabledProjects = builtins.filter
          (name: hawkerConfig.container.projects.${name}.enable or false)
          (builtins.attrNames hawkerConfig.container.projects);
      in {
        container = import ./containers/default.nix {
          inherit pkgs;
          inherit (hawkerConfig) username;
          inherit (hawkerConfig.container) gpus;
          projects = enabledProjects;
          packages = containerPackages;
          sessionVariables = containerSessionVars;
        };
      };
    };
}
