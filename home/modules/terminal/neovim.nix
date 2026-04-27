# Neovim -- package + LSP/tooling dependencies.
# The Lua config (plugins, keymaps, etc.) stays in dotfiles/neovim/
# and is deployed via stow. HM just provides the binaries.
{ pkgs, ... }:

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
}
