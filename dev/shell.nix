# Shared CUDA development shell.
# Works on any host with Nix + NVIDIA drivers.
#
# Imports base/ for shared tooling and CUDA, then merges per-project
# modules from projects/ based on settings.nix.
#
# Usage: nix develop ~/workspace/hawker
#    or: cd into a project dir with .envrc → direnv auto-enters
{ pkgs, settings }:

let
  lib = pkgs.lib;

  # Project settings
  hostSettings = settings.hosts.remote or {};
  projectSettings = hostSettings.projects or {};
  cudaVisibleDevices = hostSettings.cudaVisibleDevices or "";

  # Workspace paths
  repos = "$HOME/workspace/repos";
  venv = "${repos}/.venv";

  # ── CLI ──
  cli = import ../cli { inherit pkgs; };

  # ── Base layers ──
  tooling  = import ./base/tooling.nix { inherit pkgs; };
  cudaBase = import ./base/cuda.nix    { inherit pkgs; };

  # ── Per-project modules (imported only when enabled) ──
  projectModules = {
    pytorch = import ./projects/pytorch.nix { inherit pkgs; config = projectSettings.pytorch or {}; };
    helion  = import ./projects/helion.nix  { inherit pkgs; config = projectSettings.helion or {}; };
    vllm    = import ./projects/vllm.nix    { inherit pkgs; config = projectSettings.vllm or {}; };
  };

  enabledNames = builtins.filter (name:
    (projectSettings.${name} or {}).enable or false
  ) (builtins.attrNames projectModules);

  enabledModules = map (name: projectModules.${name}) enabledNames;

  # ── Merge packages and env vars from all enabled modules ──
  mergedPackages = lib.concatMap (m: m.packages) enabledModules;
  mergedEnv = lib.foldl' (a: b: a // b) {} (map (m: m.env) enabledModules);
in
pkgs.mkShell ({
  name = "hawker-dev";

  packages = [ cli.hawker-dev ] ++ tooling.packages ++ cudaBase.packages ++ mergedPackages;

  # CUDA binary cache
  NIX_CONFIG = "extra-substituters = https://cache.nixos-cuda.org\nextra-trusted-public-keys = cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=";

  HAWKER_ENABLED_PROJECTS = builtins.concatStringsSep " " enabledNames;

  # ── Shell hook (runtime-dependent vars only) ──
  shellHook = ''
    export HAWKER_ROOT="''${HAWKER_ROOT:-$HOME/hawker}"
    export CCACHE_DIR="$HOME/.cache/ccache"
    ${lib.optionalString (cudaVisibleDevices != "") ''export CUDA_VISIBLE_DEVICES="${cudaVisibleDevices}"''}

    # Symlink host NVIDIA driver libs into a clean directory so we can add
    # them to LD_LIBRARY_PATH without exposing the host glibc.
    _nv="$HOME/.cache/hawker/nvidia-driver-libs"
    mkdir -p "$_nv"
    for _f in /usr/lib64/libcuda.so* /usr/lib64/libnvidia*.so* /usr/lib64/libnvcuvid*.so*; do
      [ -e "$_f" ] && ln -sf "$_f" "$_nv/" 2>/dev/null
    done
    export LD_LIBRARY_PATH="${cudaBase.libPath}:$_nv''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    # Activate shared venv if it exists
    if [ -f "${venv}/bin/activate" ]; then
      source "${venv}/bin/activate"
    fi
  '';
} // cudaBase.env // mergedEnv)
