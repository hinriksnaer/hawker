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
      pkgsUnfree = import nixpkgs { inherit system; config.allowUnfree = true; };
      lib = nixpkgs.lib;

      # Common modules: user settings (imported by all machine configs)
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

      # Home Manager NixOS integration -- auto-applies HM on nixos-rebuild switch.
      hmNixosModule = hostname: {
        imports = [ home-manager.nixosModules.home-manager ];
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.users.${settings.hosts.${hostname}.username} =
          import ./home { inherit hostname settings; };
      };

    in {

      # ── Individually importable modules (auto-discovered) ──
      nixosModules = let
        discoverAll = dir: (discoverModules dir) // (discoverDirs dir);
      in
        (discoverAll ./modules/core) //
        (discoverAll ./modules/terminal) //
        (discoverAll ./modules/desktop) //
        (discoverAll ./modules/hardware) //
        (discoverAll ./modules/apps) //
        (discoverModules ./roles) //
        (discoverDirs ./projects);

      # ── Machine configurations ──
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/desktop/default.nix
            (hmNixosModule "desktop")
          ];
        };

        laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/laptop/default.nix
            (hmNixosModule "laptop")
          ];
        };
      };

      # ── Home Manager (standalone) ──
      homeConfigurations = let
        mkHome = hostname: home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            (import ./home { inherit hostname settings; })
          ];
        };
      in {
        hawker = mkHome "desktop";
        hgudmund = mkHome "laptop";
        remote = mkHome "remote";
      };

      # ── Development shells ──
      devShells.${system}.default = import ./projects/devshell.nix {
        pkgs = pkgsUnfree;
        inherit settings;
      };
    };
}
