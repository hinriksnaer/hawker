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
    # CMake FindCUDAToolkit uses these (not CUDA_HOME) to locate headers + libs
    CUDAToolkit_ROOT = "${cudaPackages.cudatoolkit}";
    CUDA_TOOLKIT_ROOT_DIR = "${cudaPackages.cudatoolkit}";
    CUDNN_INCLUDE_DIR = "${cudaPackages.cudnn.include}/include";
    CUDNN_LIB_DIR = "${cudaPackages.cudnn.lib}/lib";
    # PyTorch FindCUDNN uses CUDNN_INCLUDE_PATH / CUDNN_LIBRARY_PATH (not _DIR)
    CUDNN_INCLUDE_PATH = "${cudaPackages.cudnn.include}/include";
    CUDNN_LIBRARY_PATH = "${cudaPackages.cudnn.lib}/lib";
    # nvcc calls gcc which needs cuda_runtime.h + cudnn.h
    CPATH = "${cudaPackages.cuda_cudart}/include:${cudaPackages.cudnn.include}/include";
  };
}
