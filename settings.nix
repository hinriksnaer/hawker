# ── User settings ──
# Single source of truth for all user-specific configuration.
# Values are type-checked against modules/core/hawker-options.nix.
# Change these values to match your system, then rebuild.
{ ... }:

{
  hawker = {
    username = "hawker";
    defaultTheme = "torrentz-hydra";

    git = {
      name = "hinriksnaer";
      email = "hgudmund@redhat.com";
    };

    opencode = {
      vertexProject = "itpc-gcp-ai-eng-claude";
      vertexRegion = "us-east5";
    };

    # Each project handles its own dependencies.
    projects = [ "helion" "pytorch" ];

    helion = {
      repo = "https://github.com/pytorch/helion.git";
      branch = "main";
      torchIndex = "nightly/cu130";
      backends = [ "cuda" ];
    };

    pytorch = {
      repo = "https://github.com/pytorch/pytorch.git";
      branch = "main";
    };
  };
}
