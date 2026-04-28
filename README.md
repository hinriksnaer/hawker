# hawker

NixOS configuration and CUDA development environment.

CUDA 12.9, cuDNN 9.13, GCC 14. Development shell via `nix develop`
with direnv integration. All project settings configured in `settings.nix`.

## Development Shell

```bash
# 1. Install Nix (one-time, needs root for /nix only)
sudo mkdir -p /nix && sudo chown $USER /nix
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf

# 2. Clone and configure
git clone https://github.com/hinriksnaer/hawker.git ~/hawker
cd ~/hawker
# Edit settings.nix -- set username, git identity, projects

# 3. Enter the dev shell
nix develop
# or: cd into a project dir with .envrc → direnv auto-enters
```

## Configuration

All settings live in `settings.nix`. Project settings under `hosts.remote.projects`
are used by the development shell.

## CUDA Environment

- `cudaPackages.cudatoolkit` — merged symlinkJoin of all CUDA redist packages
- `cudaPackages.backendStdenv.cc` (GCC 14) — default compiler (CUDA 12.9 requires <=14)
- `CMAKE_PREFIX_PATH` — set to cudatoolkit + python3 for cmake discovery
- `FindCUDAToolkit.cmake` passthrough — replaces PyTorch's vendored cmake module with cmake's standard one (following nixpkgs upstream)

## NixOS Desktop

Full desktop environment with Hyprland, themed terminal tools, and 12 color themes.

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
flake.nix             2 machine configs + dev shell

modules/              NixOS modules (flat, one per tool/service)
  hawker-options.nix  typed option declarations
  gpu.nix             GPU driver dispatch (nvidia/intel/amd/none)
  fish.nix            fish shell + starship + fzf + zoxide
  ...

roles/                named module collections (assigned to hosts)
  core.nix            base system, fish, cli-tools, git, themes
  desktop.nix         hyprland, kitty, waybar, mako, rofi, fonts
  hardware.nix        GPU, bluetooth, networking, audio
  apps.nix            firefox, discord, obsidian, steam, podman

dev/                  development shell
  shell.nix           entry point (nix develop / direnv)
  base/               shared tooling + CUDA base layer
  projects/           per-project modules (pytorch, helion, vllm)
  cli/                hawker-dev CLI (available inside the shell)

hosts/                machine configs (desktop, laptop)
dotfiles/             stow-managed configs + 12 themes
```
