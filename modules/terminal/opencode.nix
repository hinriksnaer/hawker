{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    opencode
    google-cloud-sdk
  ];

  # Vertex AI environment for opencode
  environment.sessionVariables = {
    CLAUDE_CODE_USE_VERTEX = "1";
    CLOUD_ML_REGION = "us-east5";
    ANTHROPIC_VERTEX_PROJECT_ID = "itpc-gcp-ai-eng-claude";
    GOOGLE_CLOUD_PROJECT = "itpc-gcp-ai-eng-claude";
    VERTEX_LOCATION = "global";
  };
}
