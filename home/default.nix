# Home Manager configuration for the container user.
# Edit this file inside the container, then run:
#   home-manager switch --flake ~/hawker#dev
# Changes are tracked via git and apply across any system.
{ config, pkgs, ... }:

{
  home.username = "dev";
  home.homeDirectory = "/home/dev";
  home.stateVersion = "24.11";

  # Let home-manager manage itself (for `home-manager switch`)
  programs.home-manager.enable = true;

  # Git -- proof of concept for HM-managed config
  programs.git = {
    enable = true;
    userName = "hinriksnaer";
    userEmail = "hgudmund@redhat.com";
    extraConfig = {
      core.editor = "nvim";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };
}
