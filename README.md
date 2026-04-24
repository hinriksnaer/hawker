# hawker

Reproducible GPU dev containers on any machine. One config, one command.

Built for pytorch/helion development on shared GPU servers (NVIDIA H200).
Also includes a full NixOS desktop with Hyprland.

## What You Get

- **GPU containers** with CUDA 12.9, cuDNN 9.13, GCC 14, torch.compile
- **Nix-native OCI images** via `streamLayeredImage` — no Docker base, no systemd
- **One-command deploy** to any remote host with GPUs
- **Persistent state** — repos, builds, and ccache survive container rebuilds
- **Fast iteration** — config changes rebuild in seconds (Nix layer caching)
- **Single config file** (`settings.nix`) controls everything
- **Drop-in projects** — add a directory, it's auto-discovered
- **Build ordering** — projects declare a `buildOrder` priority, lower builds first

## Dev Container Setup

### On a GPU host (recommended)

```bash
# 1. Install Nix (one-time, needs root for /nix only)
sudo mkdir -p /nix && sudo chown $USER /nix
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf

# 2. Clone and configure
git clone https://github.com/hinriksnaer/hawker.git ~/hawker
cd ~/hawker
# Edit settings.nix -- set username, git identity, GPU index, projects

# 3. Install CLI + start container
nix profile install ~/hawker#hawker-container
hawker-container start

# 4. Build project sources (inside the container)
hawker-build
```

### Deploy from a local machine

```bash
# Clone, edit settings.nix, then:
hawker-container deploy my-gpu-host
# Inside the container:
hawker-build
```

### Updating

```bash
hawker-container update    # pull latest, upgrade CLI, rebuild container
```

Rebuilds are fast — Nix caches unchanged layers. Only modified packages
are rebuilt. Project repos and ccache persist via named volumes.

### Host requirements

- podman (or docker) + NVIDIA drivers with CDI:
  ```bash
  sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
  ```
- Nix (recommended, see install steps above)

## Container Architecture

The container is a Nix-built OCI image (`streamLayeredImage`):

- **No systemd, no NixOS inside** — just packages + config baked into layers
- **NixOS module system** declares packages and env vars; the image builder extracts them
- **Config changes = image rebuild** on the host (fast with Nix caching)
- **Named podman volumes** persist `~/repos` (source + builds) and `~/.cache/ccache`
- **SSH agent forwarding** — git works inside via host's SSH agent
- **Hawker repo mounted** — `~/hawker` bind-mounted from host for live updates
- **FHS compat** — `/usr/bin/env` and `/bin/sh` via `dockerTools.usrBinEnv` + `binSh`

### What's inside the container

```
~/repos/              persistent volume (named, survives rebuilds)
  .venv/              shared Python venv across all projects
  helion/             cloned on first hawker-build
  pytorch/            built from source on first hawker-build
~/.cache/ccache/      persistent compilation cache (25GB max)
~/hawker/             this repo (bind-mounted from host)
```

## Container Commands

Host-side (manage the container):

```bash
hawker-container start              # build image + start container
hawker-container enter [host]       # enter running container (local or remote)
hawker-container update             # pull latest, upgrade CLI, rebuild container
hawker-container deploy <host>      # clone/pull repo on remote + start container
hawker-container stop [host]        # stop container
hawker-container clean [host]       # remove container, image, and volumes
hawker-container status [host]      # show container status
```

Container-side (build projects):

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

## Adding a Project

1. Create `projects/<name>/options.nix` (typed option declarations with `buildOrder`)
2. Create `projects/<name>/default.nix` (imports `modules/cuda-dev.nix`, packages, env vars)
3. Create `projects/<name>/setup.sh` (clone repo, install into shared venv)
4. Add `<name> = { enable = true; ... }` to `container.projects` in `settings.nix`

No other files need editing. Options are auto-discovered by the container config.
The project is auto-sorted by `buildOrder` and `hawker-build` picks it up.

## CUDA Environment

- `cudaPackages.cudatoolkit` — merged symlinkJoin of all CUDA redist packages
- `cudaPackages.backendStdenv.cc` (GCC 14) — default compiler (CUDA 12.9 requires <=14)
- `CMAKE_PREFIX_PATH` — set to cudatoolkit + python3 for cmake discovery
- `FindCUDAToolkit.cmake` passthrough — replaces PyTorch's vendored cmake module with cmake's standard one (following nixpkgs upstream)

## NixOS Desktop

Not required for GPU container usage. Full desktop environment
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

modules/              NixOS modules (flat, one per tool/service)
  cuda-dev.nix        CUDA toolkit + cuDNN + Python + GCC 14
  tmux.nix            full tmux config + Nix-managed plugins
  fish.nix            fish shell + starship + fzf + zoxide
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

containers/           streamLayeredImage builder + hawker-container CLI
hosts/                machine configs (desktop, laptop, container)
dotfiles/             stow-managed configs + 12 themes
scripts/              runtime utilities (theme engine, hawker-build, etc.)
tests/                unit tests + VM integration + CI
```

## Tests

```bash
nix flake check       # everything: script tests + VM integration + container build
```
