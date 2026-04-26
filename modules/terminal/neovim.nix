{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    tree-sitter
    nodejs      # required by Copilot
    clang-tools # clangd + clang-format
    pyright     # Python LSP (Nix-provided, not Mason)
    python3Packages.debugpy # Python DAP adapter
  ];

  # Set neovim as default editor
  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
