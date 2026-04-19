{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    tree-sitter
  ];

  # Set neovim as default editor
  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
