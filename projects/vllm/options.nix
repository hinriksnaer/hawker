# Typed option declarations for the vLLM project.
# Values are set in settings.nix under hawker.hosts.container.projects.vllm.
{ lib, ... }:

{
  options.hawker.container.projects.vllm = {
    enable = lib.mkEnableOption "vLLM (LLM inference engine, build from source)";

    buildOrder = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Build priority (lower builds first). pytorch=10, helion=20, vllm=30.";
    };

    repo = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/vllm-project/vllm.git";
      description = "vLLM git repository URL.";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "vLLM git branch or tag (e.g. 'main', 'v0.19.1').";
    };

    cudaArch = lib.mkOption {
      type = lib.types.str;
      default = "9.0";
      description = "CUDA architectures to compile for (fallback when pytorch project is not enabled).";
    };

    maxJobs = lib.mkOption {
      type = lib.types.int;
      default = 32;
      description = "Max parallel compile jobs (fallback when pytorch project is not enabled).";
    };

    torchIndex = lib.mkOption {
      type = lib.types.str;
      default = "nightly/cu130";
      description = "PyTorch wheel index for vLLM (when pytorch project is not enabled).";
    };
  };
}
