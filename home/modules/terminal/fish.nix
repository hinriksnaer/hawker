# Fish shell -- enables shell integrations and sets fish as default.
{ pkgs, ... }:

{
  programs.fish.enable = true;

  # Set fish as the default shell for interactive sessions.
  # On non-NixOS hosts (where chsh may not work with Nix paths),
  # this sources fish from bash/zsh login.
  programs.bash.enable = true;
  programs.bash.initExtra = ''
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]; then
      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
      exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
    fi
  '';
}
