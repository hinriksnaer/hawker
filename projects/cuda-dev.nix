# Shared CUDA + Python development base.
# Imported by project modules that need GPU development tools.
# Packages deduplicate via NixOS module system -- safe to import multiple times.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Python
    python3
    python3Packages.pip
    python3Packages.virtualenv
    uv

    # CUDA
    cudaPackages.cudatoolkit
    cudaPackages.cudnn

    # Build tools
    cmake
    ninja
    gcc
    gnumake
    pkg-config
    zlib
  ];

  environment.sessionVariables = {
    CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
  };
}
