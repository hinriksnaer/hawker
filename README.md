# hyprpunk-nix

NixOS + Hyprland desktop. NVIDIA, modular themes, reproducible containers.

## Setup

```bash
git clone git@github.com:hinriksnaer/hyprpunk-nix.git ~/hyprpunk-nix
sudo nixos-rebuild switch --flake ~/hyprpunk-nix#desktop
./bootstrap.sh
```

## Structure

```
hosts/          Machines (hardware + components)
components/     Composable groups
  terminal.nix    fish, kitty, tmux, neovim, btop, lazygit, yazi, opencode, cli-tools, gh
  ui.nix          hyprland, sddm, waybar, rofi, mako, hyprlock, fonts, screenshot, cliphist
  apps.nix        firefox, thunar, steam, discord, obsidian, proton-pass, podman
  media.nix       pipewire audio
modules/        Individual NixOS modules
dotfiles/       Stow packages (each with optional modules.d/ and theme-hooks.d/)
containers/     OCI container image (same packages as terminal component)
```

## Themes

12 themes across hyprland, kitty, neovim, btop, waybar, mako, rofi, hyprlock, opencode.

```
Super+T          Theme picker
Super+Shift+T    Next theme
Super+W          Wallpaper picker
Super+Shift+W    Next wallpaper
```

Modular: each stow package registers its own theme hook in `~/.config/hyprpunk/theme-hooks.d/`.

## Containers

Build a NixOS container image with your terminal tools -- no Dockerfile needed:

```bash
nix build .#container                              # build image
podman load -i ./result                            # load locally
./containers/push.sh ibm-kaiba                     # or push to remote host
```

## Adding a Machine

1. Create `hosts/<name>/default.nix`, pick components
2. Generate `hardware-configuration.nix` on target
3. Add to `flake.nix` under `nixosConfigurations`
4. `sudo nixos-rebuild switch --flake .#<name>`
