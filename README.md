# hawker

Reproducible GPU dev containers on any machine. One config, one command.

Built for pytorch/helion development on shared GPU servers (NVIDIA H200).
Also includes a full NixOS desktop with Hyprland.

## What You Get

- **GPU containers** with CUDA 12.9, cuDNN 9.13, torch.compile -- all working
- **One-command deploy** to any remote host with GPUs
- **Persistent state** -- repos, builds, and ccache survive container restarts
- **Single config file** (`settings.nix`) controls everything
- **Drop-in projects** -- add a directory, it's auto-discovered
- **Build ordering** -- projects declare a `buildOrder` priority, lower builds first

## Quickstart

### Deploy from your local machine

You need: a local machine with Nix, a remote GPU host with podman.

```bash
# 1. Clone
git clone https://github.com/hinriksnaer/hawker.git ~/hawker
cd ~/hawker

# 2. Edit settings.nix -- set your username, git identity, GPU index, and projects

# 3. Deploy to a GPU host (clones repo on remote via git, starts container)
hawker-container deploy my-gpu-host

# 4. Build project sources inside the container
hawker-build
```

### Run directly on a GPU host

If you have Nix on the GPU host itself, you can skip the deploy step:

```bash
# 1. Clone
git clone https://github.com/hinriksnaer/hawker.git ~/hawker
cd ~/hawker

# 2. Edit settings.nix

# 3. Install the CLI
nix profile install ~/hawker#hawker-container

# 4. Start the container
hawker-container start

# 5. Build project sources inside the container
hawker-build
```

To update after pushing changes:

```bash
cd ~/hawker && git pull && nix profile upgrade hawker-container
```

### Host setup

The GPU host needs podman (or docker) and NVIDIA drivers with CDI:

```bash
# Generate CDI spec (run once after driver install/update, requires sudo)
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```

Installing Nix on the host is recommended for faster builds:

```bash
# Create /nix (requires root once, then everything runs unprivileged)
sudo mkdir -p /nix && sudo chown $USER /nix

# Install Nix (no root needed)
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf
```

Without Nix on the host, `hawker-container deploy` from your local machine
still works -- it clones the repo and builds remotely.

## Configuration

All settings live in `settings.nix`:

```nix
{
  hawker = {
    git = {
      name = "your-github-username";
      email = "you@example.com";
    };

    hosts.container = {
      username = "dev";
      gpuPassthrough = "4";                    # GPU index, "all", or "none"

      projects = {
        helion = {
          enable = true;
          repo = "https://github.com/pytorch/helion.git";
          branch = "main";
          backends = [ "cuda" ];               # also: "cute"
        };

        pytorch = {
          enable = true;
          repo = "https://github.com/pytorch/pytorch.git";
          branch = "viable/strict";
          cudaArch = "9.0";                    # "8.0;9.0" for multi-arch
          maxJobs = 32;                        # parallel compile jobs
        };
      };
    };
  };
}
```

## Container Commands

```bash
hawker-container start              # build image + start container (local)
hawker-container enter [host]       # enter running container (local or remote)
hawker-container build [args...]    # build project sources (delegates to hawker-build)
hawker-container rebuild [host]     # rebuild NixOS config inside container
hawker-container deploy <host>      # clone/pull repo on remote + start container
hawker-container stop [host]        # stop container
hawker-container clean [host]       # remove everything (fresh start)
hawker-container status [host]      # show container status
```

### Building projects

Once inside the container, use `hawker-build` to build project sources:

```bash
hawker-build                        # build all enabled projects (in buildOrder)
hawker-build helion                 # build only helion
hawker-build pytorch helion         # build specific projects (auto-sorted)
hawker-build --force                # rebuild all (keep source, re-run install)
hawker-build --clean pytorch        # nuke workspace + rebuild from scratch
hawker-build --status               # show build state of all projects
```

Projects build in the order defined by their `buildOrder` option (lower first).
When both pytorch and helion are enabled, pytorch builds first (buildOrder=10)
so helion can use the source-built torch instead of downloading nightly wheels.

If any project fails, remaining projects are skipped.

### What's inside

```
~/repos/              persistent volume
  .venv/              shared Python venv across all projects
  helion/             cloned on first hawker-build
  pytorch/            built from source on first hawker-build
~/.cache/ccache/      persistent compilation cache (25GB max)
~/hawker/             this repo (bind-mounted from host)
```

## Adding a Project

1. Create `projects/<name>/options.nix` (typed option declarations with `buildOrder`)
2. Create `projects/<name>/default.nix` (imports `modules/cuda-dev.nix`, packages, env vars)
3. Create `projects/<name>/setup.sh` (clone repo, install into shared venv)
4. Add `<name> = { enable = true; ... }` to `container.projects` in `settings.nix`

No other files need editing. Options are auto-discovered by the container config.
The project is auto-sorted by `buildOrder` and `hawker-build` picks it up.

## CUDA Environment

The container uses `cudaPackages.cudatoolkit` (a merged symlinkJoin of all
individual CUDA redist packages) for a unified `CUDA_HOME` with headers,
libraries, and tools. `cudaPackages.backendStdenv.cc` (GCC 14) is used as
the nvcc host compiler since nixpkgs-unstable ships GCC 15 which CUDA 12.9
does not support.

Projects that build with cmake should remove any vendored `FindCUDAToolkit.cmake`
so cmake's standard module is used (which respects `CMAKE_PREFIX_PATH`). See
`projects/pytorch/setup.sh` for an example -- this follows the same fix nixpkgs
applies upstream.

## NixOS Desktop

Not required for GPU container usage. This is a full desktop environment
with Hyprland, themed terminal tools, and 12 color themes.

### Fresh install

```bash
nixos-generate-config --root /mnt
# Copy hardware-configuration.nix to hosts/desktop/
nixos-install --flake github:hinriksnaer/hawker#desktop
# After reboot:
git clone git@github.com:hinriksnaer/hawker.git ~/hawker
cd ~/hawker && bash bootstrap.sh
```

### Existing NixOS system

```bash
git clone git@github.com:hinriksnaer/hawker.git ~/hawker
nixos-generate-config --dir ~/hawker/hosts/desktop/
# Edit settings.nix
sudo nixos-rebuild switch --flake ~/hawker#desktop
bash bootstrap.sh
```

### Themes

12 themes across hyprland, kitty, neovim, btop, waybar, mako, rofi, hyprlock.

```
Super+T          Theme picker
Super+Shift+T    Next theme
Super+W          Wallpaper picker
Super+Shift+W    Next wallpaper
```

## Structure

```
settings.nix          all user config (single source of truth)
flake.nix             3 machine configs, 2 packages, tests

modules/              38 NixOS modules (flat, one per tool/service)
  cuda-dev.nix        CUDA toolkit + cuDNN + Python + GCC 14 for nvcc
  hawker-options.nix  typed option declarations
  hawker-scripts.nix  CLI scripts (hawker-build, theme tools, etc.)
  gpu.nix             GPU driver dispatch (nvidia/intel/amd/none)
  ...

roles/                named module collections (assigned to hosts)
  core.nix            base system, fish, cli-tools, git, scripts
  terminal.nix        neovim, tmux, btop, lazygit, yazi, gh, opencode
  desktop.nix         hyprland, kitty, waybar, mako, rofi, sddm, fonts
  hardware.nix        GPU, bluetooth, networking, audio
  apps.nix            firefox, discord, obsidian, steam, podman

projects/
  helion/             options.nix + default.nix + setup.sh
  pytorch/            options.nix + default.nix + setup.sh

containers/           OCI image builder + CLI (hawker-container)
hosts/                machine configs (desktop, laptop, container)
dotfiles/             stow-managed configs + 12 themes
scripts/              runtime utilities (theme engine, hawker-build, etc.)
tests/                unit tests + VM integration + CI
```

## Tests

```bash
nix flake check       # everything: script tests + VM integration + container build
```
