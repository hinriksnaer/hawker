{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
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
