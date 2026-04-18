{ pkgs, ... }:

{
  # System-level dependencies for Helion development
  # Python packages are managed via uv in a venv (matching upstream CI)
  environment.systemPackages = with pkgs; [
    # Python
    python3
    python3Packages.pip
    python3Packages.virtualenv
    uv

    # CUDA
    cudaPackages.cudatoolkit
    cudaPackages.cudnn

    # Build tools (for compiling Triton from source if needed)
    clang_20
    zlib
    ninja
    pkg-config
  ];

  environment.sessionVariables = {
    CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
  };
}
