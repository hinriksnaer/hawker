# Neovim -- package, LSP/tooling deps, and config.
# Config files are copied from dotfiles/neovim/ into the Nix store
# at build time, then symlinked into ~/.config/nvim/. The source
# path is relative to this module file, so it works on any host.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    tree-sitter
    nodejs        # required by Copilot
    clang-tools   # clangd + clang-format
    pyright       # Python LSP
    python3Packages.debugpy  # Python DAP adapter
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Deploy nvim config from dotfiles/ (relative Nix path → copied to store)
  xdg.configFile."nvim" = {
    source = ../../../dotfiles/neovim/.config/nvim;
    recursive = true;
  };
}
