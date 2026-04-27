# GitHub CLI -- shared across all profiles.
{ ... }:

{
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };
}
