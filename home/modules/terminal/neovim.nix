# Neovim -- package, LSP/tooling deps, and config.
# Config files live in dotfiles/neovim/ in the hawker repo.
# HM symlinks ~/.config/nvim to the repo directory so files
# remain writable (needed for theme.lua runtime updates).
{ pkgs, config, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;
  };

  home.packages = with pkgs; [
    tree-sitter
    nodejs        # required by Copilot
    clang-tools   # clangd + clang-format
    pyright       # Python LSP
    python3Packages.debugpy  # Python DAP adapter
  ];

  # Symlink ~/.config/nvim → repo dotfiles (writable, theme system compatible)
  # Uses activation script to replace HM's generated nvim dir with a symlink
  # to the repo's Lua config. Runs after linkGeneration so it can override.
  home.activation.neovimConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    rm -rf "$HOME/.config/nvim"
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/workspace/hawker/dotfiles/neovim/.config/nvim" "$HOME/.config/nvim"
  '';
}
