# Typed option declarations for infrastructure configuration.
# Values are set in settings.nix. Type errors are caught at evaluation time.
# Project-specific options live in their respective projects/<name>/default.nix.
{ lib, ... }:

with lib;

{
  options.hawker = {
    username = mkOption {
      type = types.str;
      description = "System username. Must match your Linux user account.";
    };

    defaultTheme = mkOption {
      type = types.str;
      default = "torrentz-hydra";
      description = "Default desktop theme (from dotfiles/themes/).";
    };

    git = {
      name = mkOption {
        type = types.str;
        default = "user";
        description = "Git author name for commits.";
      };
      email = mkOption {
        type = types.str;
        default = "user@localhost";
        description = "Git author email for commits.";
      };
    };

    opencode = {
      vertexProject = mkOption {
        type = types.str;
        default = "";
        description = "GCP project ID for Vertex AI. Empty to disable.";
      };
      vertexRegion = mkOption {
        type = types.str;
        default = "us-east5";
        description = "GCP region for Vertex AI.";
      };
    };

    container = {
      gpus = mkOption {
        type = types.str;
        default = "all";
        description = ''
          GPUs to pass through to containers.
          "all" for all GPUs, "none" to disable, or a
          comma-separated list of indices (e.g. "0,1,4").
        '';
        example = "4";
      };

      projects = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Projects to include in the dev container. Each entry
          must have a matching directory in projects/ with a
          default.nix and setup.sh.
        '';
        example = [ "helion" "pytorch" ];
      };
    };
  };
}
