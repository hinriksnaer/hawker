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
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/workspace/hawker/dotfiles/neovim/.config/nvim";
}
