# NixOS configuration for docker-nixos container.
# Docker workarounds are handled by the docker-nixos base image via extendModules.
# This file only defines what's specific to the hawker dev environment.
{ config, pkgs, lib, ... }:

let
  hostSettings = (import ../../settings.nix { }).hawker.hosts.container;

  # Project imports from per-host settings
  projectSettings = hostSettings.projects or {};
  isEnabled = name: (projectSettings.${name}.enable or false) == true;
  projectDir = name: ../../projects + "/${name}";
  hasProject = name: builtins.pathExists (projectDir name + "/default.nix");

  allProjects = builtins.attrNames (
    lib.filterAttrs (n: t: t == "directory" && hasProject n)
      (builtins.readDir ../../projects)
  );

  username = hostSettings.username;
in
{
  imports = [
    ../../profiles/core.nix
    ../../profiles/terminal.nix
  ] ++ map projectDir (builtins.filter isEnabled allProjects);

  # ── Per-host settings → module options ──
  hawker.username = lib.mkForce username;
  hawker.container.gpuPassthrough = hostSettings.gpuPassthrough;

  # Populate project module options from per-host settings
  hawker.container.projects.helion = projectSettings.helion or {};
  hawker.container.projects.pytorch = projectSettings.pytorch or {};

  # Container user (base.nix creates the user, we add uid + groups)
  users.users.${username} = {
    uid = lib.mkForce 1000;
    extraGroups = [ "video" "render" ];
  };

  # Nix
  nix.settings = {
    trusted-users = [ "root" username ];
  };
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    openssh
    cacert
    git
  ];

  # ── Container-specific overrides ──

  # Services that fail in unprivileged containers
  services.nscd.enable = false;
  system.nssModules = lib.mkForce [];
  systemd.oomd.enable = false;
  documentation.man.cache.enable = false;
  systemd.services.mandb.enable = false;

  # Suppress kernel mounts that fail in containers
  systemd.mounts = [
    { where = "/sys/kernel/tracing"; enable = false; }
  ];

  # FHS compatibility: CDI-mounted binaries (nvidia-smi) need /lib64/ld-linux-x86-64.so.2
  system.activationScripts.ldLinker = ''
    mkdir -p /lib64
    ln -sfn ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
  '';

  # Container setup: runs after user creation on every nixos-rebuild switch.
  # Fixes home dir ownership, symlinks repo, deploys dotfiles.
  system.activationScripts.containerSetup = {
    deps = [ "users" "groups" ];
    text = ''
      chown -R ${username}:users /home/${username} 2>/dev/null || true
      ln -sfn /config /home/${username}/hawker 2>/dev/null || true
      chown -h ${username}:users /home/${username}/hawker 2>/dev/null || true
      if [ -d /home/${username}/hawker ]; then
        /run/current-system/sw/bin/su - ${username} -c 'bash /home/${username}/hawker/bootstrap.sh' || true
      fi
    '';
  };

  # Environment variables for CUDA/CDI
  # CDI mounts host NVIDIA driver libs at /usr/lib64 inside the container.
  # CUDA toolkit, cuDNN, NCCL paths are set by cuda-dev.nix via Nix store.
  environment.sessionVariables = {
    LD_LIBRARY_PATH = "/usr/lib64:${pkgs.stdenv.cc.cc.lib}/lib";
    TRITON_LIBCUDA_PATH = "/usr/lib64";
  };

  # Add /usr/bin to PATH for CDI-mounted binaries (nvidia-smi, etc.)
  environment.extraInit = ''
    export PATH="/usr/bin:$PATH"
  '';

  system.stateVersion = lib.mkForce "24.11";
}
