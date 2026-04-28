# OpenCode -- AI coding assistant with Vertex AI support.
# Installs the package, configures Vertex AI env vars from settings,
# and sets up theme integration (symlinks theme files, creates initial tui.json).
{ pkgs, lib, config, settings, ... }:

let
  oc = settings.opencode;
  hasVertex = oc.vertexProject != "";
  defaultTheme = settings.defaultTheme;
  hawkerPath = "${config.home.homeDirectory}/.local/share/hawker";
  ocDir = "${config.home.homeDirectory}/.config/opencode";
in
{
  home.packages = [ pkgs.opencode ]
    ++ lib.optionals hasVertex [ pkgs.google-cloud-sdk ];

  home.sessionVariables = lib.optionalAttrs hasVertex {
    CLAUDE_CODE_USE_VERTEX = "1";
    CLOUD_ML_REGION = oc.cloudMlRegion;
    ANTHROPIC_VERTEX_PROJECT_ID = oc.vertexProject;
    GOOGLE_CLOUD_PROJECT = oc.vertexProject;
    VERTEX_LOCATION = oc.cloudMlRegion;
  };

  # Symlink per-theme opencode.json files into ~/.config/opencode/themes/
  # and create initial tui.json with the default theme.
  # Theme switching is handled by hawker-theme-set-terminal (sed on tui.json).
  home.activation.opencodeConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p "${ocDir}/themes"

    # Symlink each theme's opencode.json
    for theme_dir in "${hawkerPath}/themes"/*/; do
      theme=$(basename "$theme_dir")
      if [ -f "$theme_dir/opencode.json" ]; then
        ln -sf "$theme_dir/opencode.json" "${ocDir}/themes/$theme.json"
      fi
    done

    # Create tui.json with default theme if it doesn't exist
    if [ ! -f "${ocDir}/tui.json" ]; then
      echo '{"$schema":"https://opencode.ai/tui.json","theme":"${defaultTheme}"}' > "${ocDir}/tui.json"
    fi
  '';
}
