# ── User settings ──
# Single source of truth for all user-specific configuration.
# Global options are type-checked against modules/hawker-options.nix.
# Per-host settings live under hawker.hosts.<name> and are read
# directly by each host config or Home Manager profile.
{ ... }:

{
  hawker = {
    # ── Global (shared across all hosts) ──
    defaultTheme = "ayu-dark";

    git = {
      name = "hinriksnaer";
      email = "hgudmund@redhat.com";
    };

    opencode = {
      vertexProject = "itpc-gcp-ai-eng-claude";
      vertexRegion = "us-east5";
      cloudMlRegion = "global";
    };

    # ── Per-host settings ──
    hosts = {
      desktop = {
        username = "hawker";
        gpu = "nvidia";
      };

      laptop = {
        username = "hgudmund";
        gpu = "intel";
      };

      remote = {
        username = "hgudmund";
        cudaVisibleDevices = "4";

        projects = {
          helion = {
            enable = true;
            repo = "https://github.com/pytorch/helion.git";
            branch = "main";
            torchIndex = "nightly/cu130";
            backends = [ "cute" ];
          };
          pytorch = {
            enable = true;
            repo = "https://github.com/pytorch/pytorch.git";
            branch = "viable/strict";
            cudaArch = "9.0";
            buildTests = false;
            maxJobs = 32;
          };
          vllm = {
            enable = false;
            repo = "https://github.com/vllm-project/vllm.git";
            branch = "main";
            cudaArch = "9.0";
            maxJobs = 32;
            torchIndex = "nightly/cu130";
          };
        };
      };
    };
  };
}
