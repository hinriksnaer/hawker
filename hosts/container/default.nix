# NixOS configuration for docker-nixos container.
# Docker workarounds are handled by the docker-nixos base image via extendModules.
# This file only defines what's specific to the hawker dev environment.
{ config, pkgs, lib, ... }:

let
  hostSettings = (import ../../settings.nix { }).hawker.hosts.container;

  # Auto-discover projects from the projects/ directory.
  # Each project has: options.nix (typed options), default.nix (config), setup.sh (build).
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

  # Sort enabled projects by buildOrder (set in each project's options.nix).
  # Lower values build first (pytorch=10, helion=20, new projects default=100).
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
  # Import options.nix from ALL projects (so option declarations exist even when disabled)
  ++ map (n: projectDir n + "/options.nix") (builtins.filter hasOptions allProjects)
  # Import default.nix (config + deps) only from enabled projects
  ++ map projectDir enabledProjects;

  # ── Per-host settings → module options ──
  hawker.username = lib.mkForce username;
  hawker.container.gpuPassthrough = hostSettings.gpuPassthrough;

  # Populate project module options from per-host settings (auto-discovered)
  hawker.container.projects = lib.genAttrs allProjects (name: projectSettings.${name} or {});

  # Container user (base.nix creates the user, we add uid + groups)
  users.users.${username} = {
    uid = lib.mkForce 1000;
    extraGroups = [ "video" "render" ];
  };

  # Nix
  nix.settings = {
    trusted-users = [ "root" username ];
  };

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

      # Copy SSH keys from staging mount with correct ownership/permissions.
      # ~/.ssh-host is mounted read-only from the host; SSH requires keys
      # owned by the current user with 600 permissions.
      if [ -d /home/${username}/.ssh-host ]; then
        mkdir -p /home/${username}/.ssh
        cp -f /home/${username}/.ssh-host/* /home/${username}/.ssh/ 2>/dev/null || true
        chown -R ${username}:users /home/${username}/.ssh
        chmod 700 /home/${username}/.ssh
        chmod 600 /home/${username}/.ssh/* 2>/dev/null || true
        chmod 644 /home/${username}/.ssh/*.pub 2>/dev/null || true
        chmod 644 /home/${username}/.ssh/known_hosts 2>/dev/null || true
      fi

      # Clone a writable copy of the repo from upstream (replaces /config symlink).
      # This lets git pull/push work inside the container.
      # Falls back to /config symlink if clone fails (e.g. no network).
      if [ ! -d /home/${username}/hawker/.git ]; then
        rm -f /home/${username}/hawker 2>/dev/null || true
        REMOTE_URL=$(git -C /config remote get-url origin 2>/dev/null || echo "")
        if [ -n "$REMOTE_URL" ]; then
          /run/current-system/sw/bin/su - ${username} -c \
            "git clone '$REMOTE_URL' /home/${username}/hawker" 2>/dev/null || \
            ln -sfn /config /home/${username}/hawker
        else
          ln -sfn /config /home/${username}/hawker
        fi
        chown -h ${username}:users /home/${username}/hawker 2>/dev/null || true
      fi

      # Point docker-nixos build flake to ~/hawker so nixos-rebuild uses the
      # writable repo. The /build/flake.nix wrapper combines the user config
      # with docker-nixos's container base module (fileSystems, boot, etc.)
      if [ -d /home/${username}/hawker/.git ] && [ -d /build ]; then
        cat > /build/flake.nix << 'BUILDEOF'
{
  description = "Container";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    container-base-config.url = "path:/baseconfig";
    user-config.url = "path:/home/${username}/hawker";
  };
  outputs = { nixpkgs, user-config, container-base-config, ... }@inputs: {
    nixosConfigurations.container = user-config.nixosConfigurations.container.extendModules {
      modules = [container-base-config.nixosModules.containerConfig];
    };
  };
}
BUILDEOF
      fi

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
    # Enabled projects sorted by buildOrder -- consumed by hawker-build
    HAWKER_PROJECTS = builtins.concatStringsSep " " sortedProjects;
  };

  # Add /usr/bin to PATH for CDI-mounted binaries (nvidia-smi, etc.)
  environment.extraInit = ''
    export PATH="/usr/bin:$PATH"
  '';

  system.stateVersion = lib.mkForce "24.11";
}
