# ── User settings ──
# Single source of truth for all user-specific configuration.
# All options are type-checked against modules/core/hawker-options.nix.
{ ... }:

{
  hawker = {
    username = "hgudmund";
    defaultTheme = "torrentz-hydra";

    git = {
      name = "hinriksnaer";
      email = "hgudmund@redhat.com";
    };

    opencode = {
      vertexProject = "itpc-gcp-ai-eng-claude";
      vertexRegion = "us-east5";
    };

    # ── Container + projects ──
    container = {
      gpus = "none";

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
}
