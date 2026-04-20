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
          ];
        };

        container = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [
            ./hosts/container/default.nix
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

      # ── Dev shell (native Nix on any Linux host) ──
      devShells.${system}.default = let
        containerConfig = self.nixosConfigurations.container.config;
        containerPackages = containerConfig.environment.systemPackages;
        sessionVars = containerConfig.environment.sessionVariables;
        projects = builtins.concatStringsSep "," hawkerConfig.container.projects;
      in pkgs.mkShell {
        packages = containerPackages;

        shellHook = ''
          export HAWKER_PATH="$HOME/.local/share/hawker"
          export HAWKER_USER="${hawkerConfig.username}"
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

      # ── Apps (runnable with `nix run`) ──
      apps.${system} = let
        mkApp = name: runtimeInputs: {
          type = "app";
          program = "${pkgs.writeShellApplication {
            inherit name;
            inherit runtimeInputs;
            text = builtins.readFile ./scripts/${name}.sh;
            excludeShellChecks = [ "SC2029" "SC2016" ];
          }}/bin/${name}";
        };
      in {
        # nix run .#deploy -- ibm-kaiba
        deploy = mkApp "hawker-container" (with pkgs; [ rsync openssh git nix coreutils ]);
      };

      # ── Container image ──
      packages.${system} = let
        containerConfig = self.nixosConfigurations.container.config;
        containerPackages = containerConfig.environment.systemPackages;
        containerSessionVars = containerConfig.environment.sessionVariables;
      in {
        container = import ./containers/default.nix {
          inherit pkgs;
          inherit (hawkerConfig) username;
          inherit (hawkerConfig.container) projects gpus;
          packages = containerPackages;
          sessionVariables = containerSessionVars;
        };
      };
    };
}
