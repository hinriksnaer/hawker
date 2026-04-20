{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    tree-sitter
    nodejs      # required by Copilot and Mason-installed LSPs (pyright)
    clang-tools # clangd + clang-format (Mason can't build these itself)
  ];

  # Set neovim as default editor
  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
