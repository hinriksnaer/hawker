{ pkgs, lib, settings, ... }:

let
  oc = settings.opencode or {};
  hasVertex = oc ? vertexProject && oc.vertexProject != "";
  username = settings.username;
  defaultTheme = settings.defaultTheme or "torrentz-hydra";
  themesDir = ../../dotfiles/themes;
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

  # Deploy opencode theme symlinks and default tui.json
  system.activationScripts.opencodeThemes = ''
    OC_DIR="/home/${username}/.config/opencode"
    mkdir -p "$OC_DIR/themes"

    # Symlink each theme's opencode.json
    for theme_dir in ${themesDir}/*/; do
      theme=$(basename "$theme_dir")
      if [ -f "$theme_dir/opencode.json" ]; then
        ln -sf "$theme_dir/opencode.json" "$OC_DIR/themes/$theme.json"
      fi
    done

    # Create default tui.json if it doesn't exist
    if [ ! -f "$OC_DIR/tui.json" ]; then
      echo '{"$schema":"https://opencode.ai/tui.json","theme":"${defaultTheme}"}' > "$OC_DIR/tui.json"
    fi

    chown -R ${username}:users "$OC_DIR"
  '';
}
