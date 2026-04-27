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
  # Uses activation script instead of home.file because mkOutOfStoreSymlink
  # fails when the target doesn't exist at build time.
  home.activation.neovimConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/nvim" ] || [ -L "$HOME/.config/nvim" ]; then
      mkdir -p "$HOME/.config"
      ln -sfn "$HOME/workspace/hawker/dotfiles/neovim/.config/nvim" "$HOME/.config/nvim"
    fi
  '';
}
