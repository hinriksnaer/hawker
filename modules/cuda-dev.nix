# Shared CUDA + Python development base.
# Imported by project modules that need GPU development tools.
# Packages deduplicate via NixOS module system -- safe to import multiple times.
#
# Uses individual cudaPackages (not the legacy cudatoolkit meta-package),
# joined into a single store path for CUDA_HOME / CMAKE_PREFIX_PATH.
# Projects should remove any vendored FindCUDAToolkit.cmake that bypasses
# standard cmake search (see projects/pytorch/setup.sh, following nixpkgs).
{ pkgs, lib, ... }:

let
  inherit (pkgs) cudaPackages;
  cudnn = cudaPackages.cudnn;

  # Individual CUDA packages needed for GPU development.
  # Mirrors nixpkgs' torch buildInputs for compatibility.
  cudaDeps = with cudaPackages; [
    cuda_cccl          # <thrust/*>, <cub/*>
    cuda_cudart        # cuda_runtime.h + libcudart
    cuda_cupti         # profiling (torch.profiler / kineto)
    cuda_nvcc          # nvcc compiler + crt/host_config.h
    cuda_nvml_dev      # <nvml.h>
    cuda_nvrtc         # runtime compilation
    cuda_nvtx          # NVTX tracing markers
    libcublas          # cuBLAS
    libcufft           # cuFFT
    libcurand          # cuRAND
    libcusolver        # cuSOLVER
    libcusparse        # cuSPARSE
  ];

  # Unified CUDA root: join individual packages into one store path so
  # CUDA_HOME and CMAKE_PREFIX_PATH point to a single directory with
  # all headers, libs, and tools.
  cudaJoined = pkgs.symlinkJoin {
    name = "cuda-joined-${cudaPackages.cudaMajorMinorVersion}";
    paths = cudaDeps;
  };
in
{
  environment.systemPackages = [
    # Python
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.virtualenv
    pkgs.uv

    # CUDA
    cudaJoined
    cudnn
    cudnn.include
    cudnn.lib

    # Build tools
    pkgs.cmake
    pkgs.ninja
    pkgs.gcc
    pkgs.gnumake
    pkgs.pkg-config
    pkgs.zlib
    pkgs.glibc.bin
  ];

  environment.sessionVariables = {
    CUDA_HOME = "${cudaJoined}";
    CUDA_PATH = "${cudaJoined}";
    CMAKE_PREFIX_PATH = "${cudaJoined}";
    CUDNN_INCLUDE_DIR = "${cudnn.include}/include";
    CUDNN_LIB_DIR = "${cudnn.lib}/lib";
    CUDNN_INCLUDE_PATH = "${cudnn.include}/include";
    CUDNN_LIBRARY_PATH = "${cudnn.lib}/lib";
    CPATH = "${cudaJoined}/include:${cudnn.include}/include";
  };
}
