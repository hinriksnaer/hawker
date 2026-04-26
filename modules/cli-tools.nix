{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Search and navigation
    ripgrep
    fd
    fzf
    zoxide

    # Better defaults
    lsd
    bat
  ];
}
