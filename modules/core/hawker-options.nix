# Typed option declarations for all configuration.
# Global values are set in settings.nix. Per-host values are set by each host config
# reading from hawker.hosts.<name>. Type errors are caught at evaluation time.
{ lib, ... }:

with lib;

{
  options.hawker = {
    username = mkOption {
      type = types.str;
      description = "System username. Set per-host from settings.nix hosts section.";
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
      cloudMlRegion = mkOption {
        type = types.str;
        default = "global";
        description = "Cloud ML region for OpenCode.";
      };
    };

    # Per-host settings (freeform). Keyed by host name.
    # Each host config reads its section and populates typed options.
    hosts = mkOption {
      type = types.raw;
      default = {};
      description = "Per-host settings (username, gpu, projects, etc.). Keyed by host name.";
    };

    # Container options. Project-specific options are declared in
    # each project's options.nix (auto-discovered by the container config).
    container = {
      gpuPassthrough = mkOption {
        type = types.str;
        default = "all";
        description = ''
          GPU device indices to pass through to containers.
          "all" for all GPUs, "none" to disable, or a
          comma-separated list of indices (e.g. "0,1,4").
        '';
        example = "4";
      };

      storagePath = mkOption {
        type = types.str;
        default = "";
        description = ''
          Host path for persistent container storage (repos, nix store,
          credentials, etc.). Empty uses podman named volumes.
        '';
        example = "/mnt/podman_storage/user";
      };
    };
  };
}
