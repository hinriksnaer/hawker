# hawker

Reproducible GPU dev containers on any machine. One config, one command.

Built for pytorch/helion development on shared GPU servers (NVIDIA H200).
Also includes a full NixOS desktop with Hyprland.

## What You Get

- **GPU containers** with CUDA 12.9, cuDNN 9.13, NCCL, torch.compile -- all working
- **One-command deploy** to any remote host with GPUs
- **Persistent state** -- repos, builds, and ccache survive container restarts
- **Single config file** (`settings.nix`) controls everything
- **Drop-in projects** -- add a directory, it's auto-discovered

## Quickstart

You need: a local machine with Nix, a remote GPU host with Nix + podman.

```bash
# 1. Clone
git clone https://github.com/hinriksnaer/hawker.git ~/hawker
cd ~/hawker

# 2. Edit settings.nix -- set your username, git identity, GPU index, and projects

# 3. Deploy to a GPU host
hawker-container deploy my-gpu-host
```

First deploy takes ~10 minutes (builds remotely, pulls from cache.nixos.org).
After that, deploys rebuild only what changed (seconds).

## Installing Nix

Required on both your local machine and the remote host.

```bash
# Install Nix (no root needed)
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf
```

### Remote host setup

The remote host also needs podman (or docker) and NVIDIA drivers with CDI:

```bash
# Generate CDI spec (run once after driver install/update, requires sudo)
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

# Optional: increase parallel builds
echo 'max-jobs = 16' >> ~/.config/nix/nix.conf
```

## Configuration

All settings live in `settings.nix`:

```nix
{
  hawker = {
    username = "hawker";

    git = {
      name = "your-github-username";
      email = "you@example.com";
    };

    container = {
      gpus = "4";                            # GPU index, "all", or "none"

      projects = {
        helion = {
          enable = true;
          repo = "https://github.com/pytorch/helion.git";
          branch = "main";
          backends = [ "cuda" ];             # also: "cute"
        };

        pytorch = {
          enable = true;
          repo = "https://github.com/pytorch/pytorch.git";
          branch = "main";
          cudaArch = "9.0";                  # "8.0;9.0" for multi-arch
        };
      };
    };
  };
}
```

## Container Commands

```bash
hawker-container deploy <host>    # build + push + enter
hawker-container enter <host>     # enter existing container
hawker-container push <host>      # build + push without entering
hawker-container status <host>    # check Nix/GPU availability
hawker-container stop <host>      # stop running container
hawker-container clean <host>     # remove everything (fresh start)
```

### What's inside

```
~/repos/              persistent volume
  .venv/              shared Python venv across all projects
  helion/             cloned on first entry
  pytorch/            built from source on first entry (~3248 compile steps)
~/.cache/ccache/      persistent compilation cache (25GB max)
~/hawker/             this repo (baked into image)
```

When both projects are enabled, pytorch builds first. Helion detects the
source-built torch and skips downloading nightly wheels.

## Adding a Project

1. Create `projects/<name>/options.nix` (typed option declarations)
2. Create `projects/<name>/default.nix` (imports `options.nix` + `modules/ai/cuda-dev.nix`, packages, env vars)
3. Create `projects/<name>/setup.sh` (clone repo, install into shared venv)
4. Add `"<name>"` to `container.projects` in `settings.nix`

No other files need editing. Options are auto-discovered by both desktop and
container configs.

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
flake.nix             2 machine configs, 1 container package, tests

modules/
  core/               base system, fish, cli-tools, git, scripts
  terminal/           neovim, tmux, btop, lazygit, yazi, gh, opencode
  desktop/            hyprland, kitty, waybar, mako, rofi, sddm, fonts
  hardware/           nvidia, bluetooth, networking, audio
  ai/                 shared CUDA + cuDNN + Python base
  apps/               firefox, discord, obsidian, steam, podman

projects/
  helion/             options.nix + default.nix + setup.sh
  pytorch/            options.nix + default.nix + setup.sh

containers/           OCI image builder
hosts/                machine configs (desktop, container)
dotfiles/             stow-managed configs + 12 themes
tests/                22 unit tests + VM integration + CI
```

## Tests

```bash
nix flake check       # everything: script tests + VM integration + container build
```
