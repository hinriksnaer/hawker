# Fish shell -- enables shell integrations and sets fish as default.
{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    # Ensure nix profile paths are available on non-NixOS hosts
    shellInit = ''
      if test -d ~/.nix-profile/bin
        fish_add_path --prepend ~/.nix-profile/bin
      end
      if test -d /nix/var/nix/profiles/default/bin
        fish_add_path --prepend /nix/var/nix/profiles/default/bin
      end
    '';
  };

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
  programs.zsh.initContent = ''
    # Source nix profile before exec'ing into fish
    [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ] && . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${ZSH_EXECUTION_STRING} ]]; then
      exec ${pkgs.fish}/bin/fish ''${login_shell:+--login}
    fi
  '';
}
