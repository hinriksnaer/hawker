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

## Structure

```
hosts/          Machines (hardware + components)
  desktop/        Hyprland desktop (NVIDIA, themes, apps)
  container/      Dev container (terminal tools only)
  helion/         GPU compiler dev (CUDA + PyTorch + terminal tools)
components/     Composable groups
  terminal.nix    fish, kitty, tmux, neovim, btop, lazygit, yazi, opencode, cli-tools, gh
  ui.nix          hyprland, sddm, waybar, rofi, mako, hyprlock, fonts, screenshot, cliphist
  apps.nix        firefox, thunar, steam, discord, obsidian, proton-pass, podman
  media.nix       pipewire audio
modules/        Individual NixOS modules
dotfiles/       Stow packages (each with optional modules.d/ and theme-hooks.d/)
containers/     OCI container images (built from host configs, no Dockerfile)
```

## Containers

Same flake, different targets:

```bash
hawker-container build                        # dev container
hawker-container --image helion build          # Helion GPU container
hawker-container --image helion deploy ibm-kaiba  # build + push + enter
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
