# Fish shell -- enables shell integrations and sets fish as default.
{ pkgs, ... }:

{
  programs.fish.enable = true;

  # Set fish as the default shell for interactive sessions.
  # On non-NixOS hosts (where chsh may not work with Nix paths),
  # exec into fish from both bash and zsh login shells.
  programs.bash.enable = true;
  programs.bash.initExtra = ''
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]; then
      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
      exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
    fi
  '';

  programs.zsh.enable = true;
  programs.zsh.initExtra = ''
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${ZSH_EXECUTION_STRING} ]]; then
      exec ${pkgs.fish}/bin/fish ''${login_shell:+--login}
    fi
  '';
}
