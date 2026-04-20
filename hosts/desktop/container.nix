# NixOS declarative container for GPU dev.
# Uses systemd-nspawn under the hood. Shares host /nix/store.
# Full NixOS inside with nixos-rebuild switch.
{ config, pkgs, lib, ... }:

let
  settings = (import ../../settings.nix { }).hawker.container.projects or {};
  isEnabled = name: (settings.${name}.enable or false) == true;
  projectDir = name: ../../projects + "/${name}";
  hasProject = name: builtins.pathExists (projectDir name + "/default.nix");
  allProjects = builtins.attrNames (
    lib.filterAttrs (n: t: t == "directory" && hasProject n)
      (builtins.readDir ../../projects)
  );
in
{
  containers.hawker-dev = {
    autoStart = true;
    privateNetwork = false;  # share host network

    # Bind mount GPU devices
    allowedDevices = [
      { node = "/dev/nvidia0"; modifier = "rw"; }
      { node = "/dev/nvidiactl"; modifier = "rw"; }
      { node = "/dev/nvidia-uvm"; modifier = "rw"; }
      { node = "/dev/nvidia-uvm-tools"; modifier = "rw"; }
    ];

    # Persistent storage
    bindMounts = {
      "/home/${config.hawker.username}/repos" = {
        hostPath = "/var/lib/hawker-dev/repos";
        isReadOnly = false;
      };
      "/home/${config.hawker.username}/.cache/ccache" = {
        hostPath = "/var/lib/hawker-dev/ccache";
        isReadOnly = false;
      };
    };

    config = { pkgs, ... }: {
      imports = [
        ../../modules/core/hawker-options.nix
        ../../settings.nix
        ../../modules/core
        ../../modules/terminal
      ] ++ map projectDir (builtins.filter isEnabled allProjects);

      # Container-specific
      networking.hostName = "hawker-dev";
      system.stateVersion = "24.11";

      users.users.${config.hawker.username} = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "wheel" "video" "render" ];
      };

      security.sudo.wheelNeedsPassword = false;
      nixpkgs.config.allowUnfree = true;

      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [ "root" config.hawker.username ];
      };
    };
  };

  # Create persistent directories on the host
  systemd.tmpfiles.rules = [
    "d /var/lib/hawker-dev/repos 0755 1000 1000 -"
    "d /var/lib/hawker-dev/ccache 0755 1000 1000 -"
  ];
}
