# hawker

Chuck the system anywhere. NixOS desktop, dev containers, remote GPU clusters -- same config.

## Install

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
  projects = [ "helion" "pytorch" ];
  helion.backends = [ "cuda" ];
}
```

| Setting | Values | Effect |
|---|---|---|
| `username` | any string | System user, home dir, container user |
| `projects` | `"helion"`, `"pytorch"` | Project modules + setup scripts to include |
| `helion.backends` | `"cuda"`, `"cute"` | GPU backends (stackable, not exclusive) |

## Dev Containers

Deploy to any remote host with podman/docker. If the remote has Nix installed, builds happen remotely and subsequent deploys only transfer changed packages.

```bash
# Deploy to a remote GPU host
hawker-container deploy my-gpu-host

# Enter an existing deployment
hawker-container enter my-gpu-host

# Native nix shell (no container isolation)
hawker-container shell my-gpu-host

# Check what a remote host has
hawker-container status my-gpu-host
```

### How it works

| Remote has | Deploy method | Speed |
|---|---|---|
| Nix + podman | Remote `nix build`, incremental | Fast (seconds after first deploy) |
| podman only | Local build, stream via SSH | Slower (transfers full image) |

### Installing Nix on a remote host (optional, speeds up deploys)

```bash
ssh my-gpu-host "curl -L https://nixos.org/nix/install | sh -s -- --no-daemon"
ssh my-gpu-host "mkdir -p ~/.config/nix && echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf"
```

### Container layout

```
~/repos/              persistent volume (survives container restarts)
  .venv/              shared Python venv across all projects
  helion/             cloned on first entry by helion-setup.sh
  pytorch/            cloned on first entry by pytorch-setup.sh
~/hawker/             repo (baked into image)
```

## Structure

```
settings.nix          User configuration (single source of truth)
flake.nix             Flake outputs (machines, containers, checks, dev shell)
modules/
  core/               base, fish, cli-tools
  terminal/           tmux, btop, lazygit, yazi, neovim, gh, opencode
  desktop/            hyprland, kitty, waybar, mako, rofi, sddm, fonts...
  hardware/           nvidia, bluetooth, networking, fancontrol, audio
  ai/                 cuda-dev (shared CUDA + Python base)
  apps/               firefox, discord, obsidian, steam, proton-pass...
projects/             helion, pytorch (import modules/ai/cuda-dev)
components/           Composable module groups (terminal, ui, apps, media)
containers/           Setup scripts + configs per project
hosts/                Machine configs (desktop, container)
tests/                Unit tests + NixOS VM integration test
dotfiles/             Stow packages (theme-hooks.d/, modules.d/)
```

## Themes

12 themes across hyprland, kitty, neovim, btop, waybar, mako, rofi, hyprlock, opencode.

```
Super+T          Theme picker
Super+Shift+T    Next theme
Super+W          Wallpaper picker
Super+Shift+W    Next wallpaper
```

## Adding a Machine

1. Create `hosts/<name>/default.nix`, pick components
2. Generate `hardware-configuration.nix` on target
3. Add to `flake.nix` under `nixosConfigurations`
4. `sudo nixos-rebuild switch --flake .#<name>`

## Adding a Project

1. Create `projects/<name>.nix` (packages, imports `modules/ai/cuda-dev.nix`)
2. Create `containers/<name>-setup.sh` (clone repo, install into shared venv)
3. Add `"<name>"` to `settings.nix` `projects` list
4. `hawker-container deploy <host>`

## Tests

```bash
bash tests/run-tests.sh           # Run all script tests locally
nix flake check                   # Run everything (scripts + VM + container build)
```
