# Shared CUDA + Python development base.
# Imported by project modules that need GPU development tools.
# Packages deduplicate via NixOS module system -- safe to import multiple times.
{ pkgs, ... }:

let
  cudaPackages = pkgs.cudaPackages;
in
{
  environment.systemPackages = with pkgs; [
    # Python
    python3
    python3Packages.pip
    python3Packages.virtualenv
    uv

    # CUDA -- individual packages + dev outputs for headers
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    cudaPackages.cudnn.include  # headers (cudnn.h) -- .dev has no include/
    cudaPackages.cudnn.lib
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvcc

    # Build tools
    cmake
    ninja
    gcc
    gnumake
    pkg-config
    zlib
    glibc.bin  # ldd (needed by cmake link verification)
  ];

  environment.sessionVariables = {
    CUDA_HOME = "${cudaPackages.cudatoolkit}";
    CUDA_PATH = "${cudaPackages.cudatoolkit}";
    # CMake needs CMAKE_PREFIX_PATH to find CUDA headers/libs in Nix store.
    # PyTorch's custom FindCUDAToolkit.cmake derives the toolkit root from the
    # nvcc binary path (/run/current-system/sw/bin/nvcc), which doesn't contain
    # headers. CMAKE_PREFIX_PATH is read by PyTorch's setup.py and passed to cmake.
    CMAKE_PREFIX_PATH = "${cudaPackages.cudatoolkit}";
    CUDAToolkit_ROOT = "${cudaPackages.cudatoolkit}";
    CUDNN_INCLUDE_DIR = "${cudaPackages.cudnn.include}/include";
    CUDNN_LIB_DIR = "${cudaPackages.cudnn.lib}/lib";
    # PyTorch FindCUDNN uses CUDNN_INCLUDE_PATH / CUDNN_LIBRARY_PATH (not _DIR)
    CUDNN_INCLUDE_PATH = "${cudaPackages.cudnn.include}/include";
    CUDNN_LIBRARY_PATH = "${cudaPackages.cudnn.lib}/lib";
    # nvcc calls gcc which needs cuda_runtime.h + cudnn.h
    CPATH = "${cudaPackages.cuda_cudart}/include:${cudaPackages.cudnn.include}/include";
  };
}
