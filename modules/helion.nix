{ pkgs, lib, config, ... }:

let
  cfg = config.helion;

  backendPackages = {
    cuda = with pkgs; [
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
    ];
    cute = with pkgs; [
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      cudaPackages.cutlass
    ];
    # rocm = with pkgs; [ rocmPackages.clr rocmPackages.rocm-smi ];
    # cpu = [];
  };

  backendEnv = {
    cuda = {
      CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
    };
    cute = {
      CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
    };
    # rocm = { ROCM_PATH = "${pkgs.rocmPackages.clr}"; };
    # cpu = {};
  };

  # Extra pip install args per backend (used by helion-setup.sh)
  backendPipExtras = {
    cuda = "";
    cute = "[cute-cu12]";
    # rocm = "";
    # cpu = "";
  };
in
{
  options.helion = {
    backend = lib.mkOption {
      type = lib.types.enum (builtins.attrNames backendPackages);
      default = "cuda";
      description = "Helion hardware backend";
    };
  };

  config = {
    environment.systemPackages = with pkgs; [
      # Python
      python3
      python3Packages.pip
      python3Packages.virtualenv
      uv

      # Build tools
      clang_20
      zlib
      ninja
      pkg-config
    ] ++ backendPackages.${cfg.backend};

    environment.sessionVariables = backendEnv.${cfg.backend} // {
      HELION_BACKEND = cfg.backend;
      HELION_PIP_EXTRAS = backendPipExtras.${cfg.backend};
    };
  };
}
