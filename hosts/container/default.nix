# Container configuration — declares packages and env vars for the container.
# The streamLayeredImage builder (containers/default.nix) extracts these
# and bakes them into the OCI image. No NixOS runs inside the container.
{ config, pkgs, lib, ... }:

let
  hostSettings = (import ../../settings.nix { }).hawker.hosts.container;

  # Auto-discover projects from the projects/ directory.
  projectSettings = hostSettings.projects or {};
  isEnabled = name: (projectSettings.${name}.enable or false) == true;
  projectDir = name: ../../projects + "/${name}";
  hasProject = name: builtins.pathExists (projectDir name + "/default.nix");
  hasOptions = name: builtins.pathExists (projectDir name + "/options.nix");

  allProjects = builtins.attrNames (
    lib.filterAttrs (n: t: t == "directory" && hasProject n)
      (builtins.readDir ../../projects)
  );

  enabledProjects = builtins.filter isEnabled allProjects;

  # Sort enabled projects by buildOrder (lower first).
  sortedProjects = lib.sort (a: b:
    config.hawker.container.projects.${a}.buildOrder <
    config.hawker.container.projects.${b}.buildOrder
  ) enabledProjects;

  username = hostSettings.username;
in
{
  imports = [
    ../../roles/core.nix
    ../../roles/terminal.nix
  ]
  ++ map (n: projectDir n + "/options.nix") (builtins.filter hasOptions allProjects)
  ++ map projectDir enabledProjects;

  # ── Per-host settings → module options ──
  hawker.username = lib.mkForce username;
  hawker.container.gpuPassthrough = hostSettings.gpuPassthrough;

  # Populate project module options from per-host settings (auto-discovered)
  hawker.container.projects = lib.genAttrs allProjects (name: projectSettings.${name} or {});

  # Container user
  users.users.${username} = {
    uid = lib.mkForce 1000;
    extraGroups = [ "video" "render" ];
  };

  environment.systemPackages = with pkgs; [
    openssh
    cacert
    git
    (writeShellApplication {
      name = "hawker-refresh";
      runtimeInputs = [ git coreutils ];
      text = builtins.readFile ../../containers/hawker-refresh.sh;
    })
  ];

  # Container-specific: disable services and boot that don't apply
  boot.loader.grub.enable = false;
  fileSystems."/" = { device = "none"; fsType = "tmpfs"; };
  services.nscd.enable = false;
  system.nssModules = lib.mkForce [];

  # Environment variables for CUDA/CDI
  environment.sessionVariables = {
    LD_LIBRARY_PATH = "/usr/lib64:${pkgs.stdenv.cc.cc.lib}/lib";
    TRITON_LIBCUDA_PATH = "/usr/lib64";
    HAWKER_PROJECTS = builtins.concatStringsSep " " sortedProjects;
  };

  system.stateVersion = lib.mkForce "24.11";
}
