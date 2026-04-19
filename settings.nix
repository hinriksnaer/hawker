# ── User settings ──
# Single source of truth for all user-specific configuration.
# Change these values to match your system, then rebuild.
{
  username = "hawker";

  # Default desktop theme (from dotfiles/themes/)
  defaultTheme = "torrentz-hydra";

  # Git identity (used by .gitconfig)
  git = {
    name = "hinriksnaer";
    email = "hgudmund@redhat.com";
  };

  # OpenCode / Vertex AI configuration
  # Set to {} to disable Vertex AI integration.
  opencode = {
    vertexProject = "itpc-gcp-ai-eng-claude";
    vertexRegion = "us-east5";
  };

  # Projects to include in the dev container.
  # Each entry pulls in project-specific packages and setup scripts.
  # Available: "helion", "pytorch"
  # Setup scripts run in list order. Each handles its own dependencies:
  # - helion: installs torch from nightly if not already present
  # - pytorch: builds torch from source (overrides nightly if helion ran first)
  projects = [ "helion" "pytorch" ];

  # Helion configuration
  helion = {
    repo = "https://github.com/pytorch/helion.git";
    branch = "main";
    torchIndex = "nightly/cu130";
    # Hardware backends to enable. Not mutually exclusive.
    # Available: "cuda", "cute"
    backends = [ "cuda" ];
  };

  # PyTorch configuration
  pytorch = {
    repo = "https://github.com/pytorch/pytorch.git";
    branch = "main";
  };
}
