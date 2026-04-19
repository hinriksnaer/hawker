{ pkgs, lib, settings, ... }:

let
  oc = settings.opencode or {};
  hasVertex = oc ? vertexProject && oc.vertexProject != "";
in
{
  environment.systemPackages = with pkgs; [
    opencode
  ] ++ lib.optionals hasVertex [
    google-cloud-sdk
  ];

  environment.sessionVariables = lib.optionalAttrs hasVertex {
    CLAUDE_CODE_USE_VERTEX = "1";
    CLOUD_ML_REGION = oc.vertexRegion or "us-east5";
    ANTHROPIC_VERTEX_PROJECT_ID = oc.vertexProject;
    GOOGLE_CLOUD_PROJECT = oc.vertexProject;
    VERTEX_LOCATION = "global";
  };
}
