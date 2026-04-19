# Headless terminal tools -- safe for containers and remote hosts.
# Does not include display-dependent packages (kitty, wl-clipboard).
{ ... }:

{
  imports = [
    ../modules/core/fish.nix
    ../modules/terminal/tmux.nix
    ../modules/terminal/btop.nix
    ../modules/terminal/lazygit.nix
    ../modules/terminal/yazi.nix
    ../modules/core/cli-tools.nix
    ../modules/terminal/neovim.nix
    ../modules/terminal/gh.nix
    ../modules/terminal/opencode.nix
    ../modules/terminal/proton-pass.nix
    ../modules/core/hawker-scripts.nix
  ];
}
