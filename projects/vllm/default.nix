{ pkgs, lib, config, ... }:

let
  vc = config.hawker.container.projects.vllm;
in
{
  imports = [ ../../modules/cuda-dev.nix ];

  config = {
    environment.systemPackages = with pkgs; [
      # Build acceleration (vLLM's setup.py auto-detects ccache)
      ccache
    ];

    environment.sessionVariables = {
      VLLM_REPO = vc.repo;
      VLLM_BRANCH = vc.branch;
      VLLM_TARGET_DEVICE = "cuda";
      VLLM_TORCH_INDEX = vc.torchIndex;

      # Fallbacks for when pytorch project is not enabled.
      # lib.mkDefault gives these lower priority so pytorch's values win
      # when both projects are active.
      TORCH_CUDA_ARCH_LIST = lib.mkDefault vc.cudaArch;
      MAX_JOBS = lib.mkDefault (toString vc.maxJobs);

      # ccache config -- pip creates random build dirs per invocation,
      # CCACHE_NOHASHDIR prevents the directory path from being part of
      # the cache key so rebuilds still get cache hits.
      CCACHE_NOHASHDIR = lib.mkDefault "true";
      CCACHE_DIR = lib.mkDefault "/home/${config.hawker.username}/.cache/ccache";
      CCACHE_MAXSIZE = lib.mkDefault "25G";
    };
  };
}
