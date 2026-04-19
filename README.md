# hawker

Chuck the system anywhere. NixOS desktop, dev containers, remote GPU clusters -- same config.

## Quickstart (no NixOS required)

For GPU development on remote hosts. Works from any Linux or macOS machine.

```bash
# 1. Install Nix (one-time, no root needed)
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

# 2. Clone and configure
git clone https://github.com/hinriksnaer/hawker.git ~/hawker
cd ~/hawker

# 3. Edit settings.nix -- set your username and projects
#    username should match your remote host user

# 4. Deploy to a GPU host
nix run .#container  # or: hawker-container deploy my-gpu-host
```

The container includes: fish, neovim, tmux, btop, git, CUDA toolkit, Python, and
your configured projects (helion, pytorch). First deploy takes ~10 minutes (downloads
packages). Subsequent deploys take seconds.

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

  git = {
    name = "your-github-username";
    email = "you@example.com";
  };

  projects = [ "helion" "pytorch" ];

  helion = {
    repo = "https://github.com/pytorch/helion.git";
    branch = "main";
    torchIndex = "nightly/cu130";
    backends = [ "cuda" ];
  };

  pytorch = {
    repo = "https://github.com/pytorch/pytorch.git";
    branch = "main";
  };
}
```

| Setting | Values | Effect |
|---|---|---|
| `username` | any string | System user, container user |
| `git.name/email` | strings | Git identity (generated at bootstrap) |
| `projects` | `"helion"`, `"pytorch"` | Project modules + setup scripts |
| `helion.backends` | `"cuda"`, `"cute"` | GPU backends (stackable) |
| `helion.repo/branch` | URLs/strings | Source repo and branch to clone |
| `pytorch.repo/branch` | URLs/strings | Source repo and branch to clone |

## Dev Containers

Deploy to any remote host with podman/docker. If the remote has Nix installed, builds happen remotely and subsequent deploys only transfer changed packages.

```bash
hawker-container deploy my-gpu-host     # build + push + enter
hawker-container enter my-gpu-host      # enter existing deployment
hawker-container shell my-gpu-host      # nix develop (no container)
hawker-container status my-gpu-host     # check Nix/GPU availability
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
  helion/             cloned on first entry
  pytorch/            cloned on first entry
~/hawker/             repo (baked into image)
```

## Structure

```
settings.nix          User configuration (single source of truth)
flake.nix             Flake outputs (machines, containers, checks, dev shell)
modules/
  core/               base, fish, cli-tools
  terminal/           tmux, btop, lazygit, yazi, neovim, gh, opencode, proton-pass
  desktop/            hyprland, kitty, waybar, mako, rofi, sddm, fonts...
  hardware/           nvidia, bluetooth, networking, fancontrol, audio
  ai/                 cuda-dev (shared CUDA + Python base)
  apps/               firefox, discord, obsidian, steam...
projects/             Self-contained project modules
  helion/             default.nix (packages) + setup.sh (clone + install)
  pytorch/            default.nix (packages) + setup.sh (clone + build)
components/           Composable module groups (terminal, ui, apps, media)
containers/           OCI image builder (default.nix)
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

## Adding a Project

1. Create `projects/<name>/default.nix` (packages, imports `modules/ai/cuda-dev.nix`)
2. Create `projects/<name>/setup.sh` (clone repo, install into shared venv)
3. Add `"<name>"` to `settings.nix` `projects` list
4. `hawker-container deploy <host>`

## Adding a Machine

1. Create `hosts/<name>/default.nix`, pick components
2. Generate `hardware-configuration.nix` on target
3. Add to `flake.nix` under `nixosConfigurations`
4. `sudo nixos-rebuild switch --flake .#<name>`

## Tests

```bash
bash tests/run-tests.sh           # Run all script tests locally
nix flake check                   # Run everything (scripts + VM + container build)
```
