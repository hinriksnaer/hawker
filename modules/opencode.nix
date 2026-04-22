{ pkgs, lib, config, ... }:

let
  oc = config.hawker.opencode;
  hasVertex = oc.vertexProject != "";
  username = config.hawker.username;
  defaultTheme = config.hawker.defaultTheme;
  themesDir = ../dotfiles/themes;
in
{
  environment.systemPackages = with pkgs; [
    opencode
  ] ++ lib.optionals hasVertex [
    google-cloud-sdk
  ];

  environment.sessionVariables = lib.optionalAttrs hasVertex {
    CLAUDE_CODE_USE_VERTEX = "1";
    CLOUD_ML_REGION = oc.cloudMlRegion;
    ANTHROPIC_VERTEX_PROJECT_ID = oc.vertexProject;
    GOOGLE_CLOUD_PROJECT = oc.vertexProject;
    VERTEX_LOCATION = oc.cloudMlRegion;
  };

  system.activationScripts.opencodeThemes = ''
    OC_DIR="/home/${username}/.config/opencode"
    mkdir -p "$OC_DIR/themes"

    for theme_dir in ${themesDir}/*/; do
      theme=$(basename "$theme_dir")
      if [ -f "$theme_dir/opencode.json" ]; then
        ln -sf "$theme_dir/opencode.json" "$OC_DIR/themes/$theme.json"
      fi
    done

    if [ ! -f "$OC_DIR/tui.json" ]; then
      echo '{"$schema":"https://opencode.ai/tui.json","theme":"${defaultTheme}"}' > "$OC_DIR/tui.json"
    fi

    chown -R ${username}:users "$OC_DIR"
  '';
}
