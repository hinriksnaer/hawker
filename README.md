# hawker

NixOS desktop + GPU dev containers. Same config, any machine.

## Quickstart (no NixOS required)

For GPU development on remote hosts. Works from any Linux or macOS machine.

```bash
# 1. Install Nix (one-time, no root needed)
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

# 2. Clone and configure
git clone https://github.com/hinriksnaer/hawker.git ~/hawker
cd ~/hawker

# 3. Edit settings.nix -- set your username, git identity, and projects

# 4. Deploy to a GPU host (Nix required on remote)
hawker-container deploy my-gpu-host
```

First deploy builds the container remotely (~10 min, downloads from cache.nixos.org).
Subsequent deploys rebuild only what changed (seconds). Compilation cache (ccache)
persists across container restarts.

## Full NixOS Desktop Install

### Fresh install (from NixOS live USB)

```bash
# 1. Partition & mount disks, then:
nixos-generate-config --root /mnt
# 2. Copy /mnt/etc/nixos/hardware-configuration.nix to hosts/desktop/
nixos-install --flake github:hinriksnaer/hawker#desktop
# 3. Reboot, log in, then:
git clone git@github.com:hinriksnaer/hawker.git ~/hawker
cd ~/hawker && bash bootstrap.sh
```

### Existing NixOS system

```bash
git clone git@github.com:hinriksnaer/hawker.git ~/hawker
nixos-generate-config --dir ~/hawker/hosts/desktop/
# Edit settings.nix -- set username to match your user
sudo nixos-rebuild switch --flake ~/hawker#desktop
bash bootstrap.sh
```

## Configuration

All user-specific settings live in `settings.nix`:

```nix
{
  username = "hawker";
  defaultTheme = "torrentz-hydra";

  git = {
    name = "your-github-username";
    email = "you@example.com";
  };

  opencode = {
    vertexProject = "your-gcp-project";
    vertexRegion = "us-east5";
  };

  # Each project is self-contained. Order doesn't matter for correctness.
  projects = [ "helion" "pytorch" ];

  helion = {
    repo = "https://github.com/pytorch/helion.git";
    branch = "main";
    torchIndex = "nightly/cu130";
    backends = [ "cuda" ];       # also: "cute"
  };

  pytorch = {
    repo = "https://github.com/pytorch/pytorch.git";
    branch = "main";
  };
}
```

## Dev Containers

Deploy to any remote host with Nix + podman/docker. Builds happen remotely,
pulling packages from cache.nixos.org.

```bash
hawker-container deploy my-gpu-host     # build + push + enter
hawker-container enter my-gpu-host      # enter existing deployment
hawker-container shell my-gpu-host      # nix develop (no container)
hawker-container status my-gpu-host     # check Nix/GPU availability
hawker-container clean my-gpu-host      # remove image + volumes (fresh start)
```

### Setting up a remote host

```bash
# Install Nix (required)
ssh my-gpu-host "curl -L https://nixos.org/nix/install | sh -s -- --no-daemon"
ssh my-gpu-host "mkdir -p ~/.config/nix && echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf"

# Optional: increase parallel builds (check core count with nproc)
ssh my-gpu-host "echo 'max-jobs = 16' >> ~/.config/nix/nix.conf"
ssh my-gpu-host "echo 'cores = 10' >> ~/.config/nix/nix.conf"
```

### Container layout

```
~/repos/              persistent volume
  .venv/              shared Python venv across all projects
  helion/             cloned on first entry
  pytorch/            cloned on first entry
~/.cache/ccache/      persistent volume (compilation cache)
~/hawker/             repo (baked into image)
```

### Project dependencies

Each project's setup script handles its own dependencies:
- **helion only**: installs torch from nightly wheels
- **pytorch only**: builds torch from source
- **both**: helion detects existing torch and skips the download

## Structure

```
settings.nix          User configuration (single source of truth)
flake.nix             Flake outputs (auto-discovers modules and projects)
bootstrap.sh          Stow dotfiles + runtime dirs (55 lines)

modules/              NixOS modules (each dir has default.nix that auto-imports all)
  core/               base, fish, cli-tools, git, hawker-scripts
  terminal/           tmux, btop, lazygit, yazi, neovim, gh, opencode
  desktop/            hyprland, kitty, waybar, mako, rofi, sddm, proton-pass, fonts...
  hardware/           nvidia, bluetooth, networking, fancontrol, audio
  ai/                 cuda-dev (shared CUDA + Python base)
  apps/               firefox, discord, obsidian, steam, podman, thunar

projects/             Self-contained project modules
  helion/             default.nix (packages) + setup.sh (clone + install)
  pytorch/            default.nix (packages) + setup.sh (clone + build)

scripts/              Source files for Nix-wrapped CLI scripts
  *.sh                bash (writeShellApplication -- shellcheck at build time)
  *.fish              fish (writeScriptBin)

containers/           OCI image builder (default.nix)
hosts/                Machine configs (desktop, container)
tests/                Unit tests (22) + NixOS VM integration test
dotfiles/             Stow-managed configs
  hawker-config/      Theme hooks + hyprland modules.d (consolidated)
  themes/             12 themes (hyprland, kitty, neovim, btop, waybar, mako, rofi...)
  hyprland/           Window manager config
  neovim/             Editor config
  ...                 fish, kitty, waybar, rofi, mako, hyprlock, tmux, lazygit, yazi
```

## Adding a Module

Drop a `.nix` file in the right `modules/` subdirectory. It's auto-imported.

## Adding a Project

1. Create `projects/<name>/default.nix` (packages, imports `modules/ai/cuda-dev.nix`)
2. Create `projects/<name>/setup.sh` (clone repo, install into shared venv)
3. Add `"<name>"` to `settings.nix` `projects` list
4. `hawker-container deploy <host>`

## Adding a Machine

1. Create `hosts/<name>/default.nix`, import module directories
2. Generate `hardware-configuration.nix` on target
3. Add to `flake.nix` under `nixosConfigurations`
4. `sudo nixos-rebuild switch --flake .#<name>`

## Themes

12 themes across hyprland, kitty, neovim, btop, waybar, mako, rofi, hyprlock, opencode.

```
Super+T          Theme picker
Super+Shift+T    Next theme
Super+W          Wallpaper picker
Super+Shift+W    Next wallpaper
```

## Tests

```bash
bash tests/run-tests.sh           # Run all script tests locally
nix flake check                   # Run everything (scripts + VM + container build)
```
