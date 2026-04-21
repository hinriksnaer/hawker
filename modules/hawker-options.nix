# Typed option declarations for all configuration.
# Values are set in settings.nix. Type errors are caught at evaluation time.
{ lib, ... }:

with lib;

{
  options.hawker = {
    username = mkOption {
      type = types.str;
      description = "System username. Must match your Linux user account.";
    };

    gpu = mkOption {
      type = types.enum [ "nvidia" "intel" "amd" "none" ];
      default = "none";
      description = "GPU driver to use. Configures drivers, kernel modules, VAAPI, and container toolkit.";
      example = "nvidia";
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

      projects = {
        helion = {
          enable = mkEnableOption "Helion GPU kernel DSL";
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
          enable = mkEnableOption "PyTorch (build from source)";
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
          cudaArch = mkOption {
            type = types.str;
            default = "9.0";
            description = "CUDA architectures to compile for (e.g. '9.0' for H200, '8.0;9.0' for A100+H200).";
          };
          buildTests = mkOption {
            type = types.bool;
            default = false;
            description = "Build pytorch test binaries (slower build, only needed for running C++ tests).";
          };
        };
      };
    };
  };
}
