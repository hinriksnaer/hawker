# Fish shell -- fully managed by Home Manager.
# Replaces modules/core/fish.nix (NixOS) and dotfiles/fish/ (stow).
# Shell integrations for starship, fzf, zoxide, lsd are handled
# automatically by their respective HM modules in cli-tools.nix.
{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    # Nix profile paths for non-NixOS hosts
    shellInit = ''
      if test -d ~/.nix-profile/bin
        fish_add_path --prepend ~/.nix-profile/bin
      end
      if test -d /nix/var/nix/profiles/default/bin
        fish_add_path --prepend /nix/var/nix/profiles/default/bin
      end
    '';

    interactiveShellInit = ''
      # Vi mode
      fish_vi_key_bindings

      # History
      set -g fish_history_size 10000

      # Auto-activate shared venv if it exists
      if test -f $HAWKER_ROOT/workspace/.venv/bin/activate.fish
          source $HAWKER_ROOT/workspace/.venv/bin/activate.fish
      else if test -f $HOME/workspace/hawker/workspace/.venv/bin/activate.fish
          source $HOME/workspace/hawker/workspace/.venv/bin/activate.fish
      end

      # Proton Pass SSH agent (desktop only, harmless elsewhere)
      if test -S $HOME/.ssh/proton-pass-agent.sock
          set -gx SSH_AUTH_SOCK $HOME/.ssh/proton-pass-agent.sock
      end
    '';

    shellAbbrs = {
      y = "yazi";
    };
  };

  # Set fish as default shell for interactive sessions on non-NixOS hosts.
  # Bash and zsh exec into fish since chsh may not work with Nix paths.
  programs.bash.enable = true;
  programs.bash.initExtra = ''
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]; then
      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
      exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
    fi
  '';

  programs.zsh.enable = true;
  programs.zsh.initContent = ''
    [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ] && . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${ZSH_EXECUTION_STRING} ]]; then
      exec ${pkgs.fish}/bin/fish ''${login_shell:+--login}
    fi
  '';
}
