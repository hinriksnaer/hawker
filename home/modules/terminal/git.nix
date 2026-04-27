# Git configuration -- shared across all profiles.
# Reads user identity from settings.nix.
{ settings, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = settings.git.name;
      user.email = settings.git.email;
      core.editor = "nvim";
      init.defaultBranch = "main";
      pull.rebase = false;
      signing.format = "openpgp";
    };
  };
}
