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

    # Build essentials
    gcc
    gnumake
    cmake
    pkg-config
    openssl
    openssl.dev
    unzip
    gnutar


  ];
}
