# Shared CUDA + Python development base.
# Imported by project modules that need GPU development tools.
# Packages deduplicate via NixOS module system -- safe to import multiple times.
#
# cudaPackages.cudatoolkit is a symlinkJoin of all individual CUDA redist
# packages (cuda_cudart, cuda_nvcc, libcublas, etc.) with all outputs
# (lib, dev, include) merged into one store path. This gives us a single
# CUDA_HOME with headers, libraries, and tools — exactly what cmake and
# pip-based builds expect.
#
# Projects should remove any vendored FindCUDAToolkit.cmake that bypasses
# standard cmake search (see projects/pytorch/setup.sh, following nixpkgs).
{ pkgs, ... }:

let
  inherit (pkgs) cudaPackages;
  cudaToolkit = cudaPackages.cudatoolkit;
  cudnn = cudaPackages.cudnn;
in
{
  environment.systemPackages = with pkgs; [
    # Python
    python3
    python3Packages.pip
    python3Packages.virtualenv
    uv

    # CUDA toolkit (merged symlinkJoin of all redist packages + outputs)
    cudaToolkit
    cudnn
    cudnn.include
    cudnn.lib

    # Build tools
    cmake
    ninja
    gcc
    gnumake
    pkg-config
    zlib
    glibc.bin
  ];

  # CUDA binary cache (pre-built CUDA packages from nixos-cuda.org)
  nix.settings = {
    substituters = [ "https://cache.nixos-cuda.org" ];
    trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
  };

  environment.sessionVariables = {
    CUDA_HOME = "${cudaToolkit}";
    CUDA_PATH = "${cudaToolkit}";
    CMAKE_PREFIX_PATH = "${cudaToolkit}";
    CUDNN_INCLUDE_DIR = "${cudnn.include}/include";
    CUDNN_LIB_DIR = "${cudnn.lib}/lib";
    CUDNN_INCLUDE_PATH = "${cudnn.include}/include";
    CUDNN_LIBRARY_PATH = "${cudnn.lib}/lib";
    CPATH = "${cudaToolkit}/include:${cudnn.include}/include";
  };
}
