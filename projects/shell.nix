# Shared development shell for all projects.
# Available via: nix develop (on a NixOS host or for local development).
# Nix's setup hooks automatically populate CMAKE_PREFIX_PATH,
# PKG_CONFIG_PATH, etc. from buildInputs.
#
# Inside the container, packages are baked into the image by
# streamLayeredImage — this shell is not used there.
#
# To add deps for a new project, add them to buildInputs below.
{ pkgs }:

let
  inherit (pkgs) cudaPackages;
  cudaToolkit = cudaPackages.cudatoolkit;
  cudnn = cudaPackages.cudnn;
in
pkgs.mkShell {
  # Libraries and headers cmake needs to find (populates CMAKE_PREFIX_PATH)
  buildInputs = [
    # CUDA
    cudaToolkit
    cudnn
    cudnn.include
    cudnn.lib

    # Python (cmake FindPython needs Python.h + libpython)
    pkgs.python3

    # Common build deps
    pkgs.zlib
    pkgs.glibc

    # PyTorch-specific
    pkgs.openblas
    pkgs.libuv
    pkgs.libpng
    pkgs.libjpeg

    # Helion-specific
    cudaPackages.cutlass
  ];

  # Build tools (compilers, generators — not searched by cmake for libs)
  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
    cudaPackages.backendStdenv.cc  # GCC 14 (CUDA 12.9 compatible)
    pkgs.gnumake
    pkgs.pkg-config
    pkgs.ccache
    pkgs.gfortran
    pkgs.clang_20
  ];
}
