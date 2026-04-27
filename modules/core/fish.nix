# Fish shell -- system-level configuration.
# Shell integrations for starship, fzf, zoxide, and lsd aliases
# are now managed by Home Manager (home/modules/terminal/cli-tools.nix).
{ pkgs, ... }:

{
  # Starship is managed by HM but the NixOS fish init references
  # it by absolute system path. Keep it in system packages until
  # fish itself migrates to HM.
  environment.systemPackages = [ pkgs.starship ];

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # Vi mode
      fish_vi_key_bindings

      # History
      set -g fish_history_size 10000

      # Auto-activate shared venv if it exists (used by helion, pytorch, etc.)
      if test -f $HOME/repos/.venv/bin/activate.fish
          source $HOME/repos/.venv/bin/activate.fish
      end

      # Proton Pass SSH agent
      if test -S $HOME/.ssh/proton-pass-agent.sock
          set -gx SSH_AUTH_SOCK $HOME/.ssh/proton-pass-agent.sock
      end
    '';

    shellAbbrs = {
      y = "yazi";
    };
  };
}
