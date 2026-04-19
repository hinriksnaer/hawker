# Typed option declarations for all user-specific configuration.
# Values are set in settings.nix. Type errors are caught at evaluation time.
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

    gpuPassthrough = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GPU passthrough in containers (--device nvidia).";
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

    helion = {
      repo = mkOption {
        type = types.str;
        default = "https://github.com/pytorch/helion.git";
        description = "Helion git repository URL.";
      };
      branch = mkOption {
        type = types.str;
        default = "main";
        description = "Helion git branch.";
      };
      torchIndex = mkOption {
        type = types.str;
        default = "nightly/cu130";
        description = "PyTorch wheel index for helion (when pytorch project is not enabled).";
      };
      backends = mkOption {
        type = types.listOf (types.enum [ "cuda" "cute" ]);
        default = [ "cuda" ];
        description = "GPU backends to enable. Stackable, not mutually exclusive.";
      };
    };

    pytorch = {
      repo = mkOption {
        type = types.str;
        default = "https://github.com/pytorch/pytorch.git";
        description = "PyTorch git repository URL.";
      };
      branch = mkOption {
        type = types.str;
        default = "main";
        description = "PyTorch git branch.";
      };
    };
  };
}
