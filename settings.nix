# ── User settings ──
# Single source of truth for all user-specific configuration.
# Change these values to match your system, then rebuild.
{
  username = "hawker";

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
  projects = [ "helion" "pytorch" ];

  # Helion configuration
  helion = {
    # Hardware backends to enable. Not mutually exclusive -- enable multiple.
    # Available: "cuda", "cute"
    # Future: "rocm", "cpu"
    backends = [ "cuda" ];
  };
}
