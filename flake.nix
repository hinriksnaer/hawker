{
  description = "hawker - NixOS configuration. Chuck the system anywhere.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      settings = import ./settings.nix;

      # Auto-discover .nix files from a directory, returning { name = import path; }
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

      # Auto-discover directories with default.nix (for projects)
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
        # modules/<category>/*.nix
        (discoverModules ./modules/core) //
        (discoverModules ./modules/terminal) //
        (discoverModules ./modules/desktop) //
        (discoverModules ./modules/hardware) //
        (discoverModules ./modules/ai) //
        (discoverModules ./modules/apps) //
        # projects/<name>/default.nix
        (discoverDirs ./projects) //
        # components/*.nix
        (discoverModules ./components);

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
        vm-integration = import ./tests/vm-test.nix { inherit pkgs settings; };
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

          ${builtins.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") sessionVars
          )}

          if [ -d /usr/lib64 ] && [ ! -f /etc/NIXOS ]; then
            export LD_LIBRARY_PATH="/usr/lib64''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          fi

          for project in ''${HAWKER_PROJECTS//,/ }; do
            setup="$HOME/hawker/projects/''${project}/setup.sh"
            if [ -f "$setup" ]; then
              bash "$setup"
            fi
          done
        '';
      };

      # ── Container image ──
      packages.${system} = let
        containerConfig = self.nixosConfigurations.container.config;
        containerPackages = containerConfig.environment.systemPackages;
        containerSessionVars = containerConfig.environment.sessionVariables;
      in {
        container = import ./containers/default.nix {
          inherit pkgs settings;
          packages = containerPackages;
          sessionVariables = containerSessionVars;
        };
      };
    };
}
