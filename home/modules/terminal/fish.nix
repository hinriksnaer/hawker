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
      # Terminfo from HM profile (kitty terminfo for SSH sessions)
      if test -d ~/.nix-profile/share/terminfo
        set -gx TERMINFO_DIRS "$HOME/.nix-profile/share/terminfo:$TERMINFO_DIRS"
      end
    '';

    interactiveShellInit = ''
      # Vi mode
      fish_vi_key_bindings

      # History
      set -g fish_history_size 10000

      # Auto-activate shared venv if it exists
      if test -f $HOME/workspace/repos/.venv/bin/activate.fish
          source $HOME/workspace/repos/.venv/bin/activate.fish
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

  # Exec into fish from whatever the host's default shell is.
  # Sources nix profile first so fish has all HM tools in PATH.
  programs.bash.enable = true;
  programs.bash.initExtra = ''
    [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ] && . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ] && . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    exec fish
  '';

  programs.zsh = {
    enable = true;
    envExtra = ''
      [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"
      [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ] && . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    '';
    initContent = "exec fish";
  };
}
