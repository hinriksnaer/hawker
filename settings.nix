# ── User settings ──
# Single source of truth for all user-specific configuration.
# Global options are type-checked against modules/hawker-options.nix.
# Per-host settings live under hawker.hosts.<name> and are read
# directly by each host config.
{ ... }:

{
  hawker = {
    # ── Global (shared across all hosts) ──
    defaultTheme = "torrentz-hydra";

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

      container = {
        username = "dev";
        gpuPassthrough = "4";

        projects = {
          helion = {
            enable = true;
            repo = "https://github.com/pytorch/helion.git";
            branch = "main";
            torchIndex = "nightly/cu130";
            backends = [ "cute" ];
          };
          #
          # pytorch = {
          #   enable = true;
          #   repo = "https://github.com/pytorch/pytorch.git";
          #   branch = "main";
          #   cudaArch = "9.0";
          #   buildTests = false;
          # };
        };
      };
    };
  };
}
