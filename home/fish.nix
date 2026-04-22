{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # Vi mode
      fish_vi_key_bindings

      # History
      set -g fish_history_size 10000

      # Starship prompt
      if command -v starship >/dev/null 2>&1
          starship init fish | source
      end

      # fzf integration
      if command -v fzf >/dev/null 2>&1
          fzf --fish | source
      end

      # zoxide (smart cd)
      if command -v zoxide >/dev/null 2>&1
          zoxide init fish | source
      end

      # Auto-activate shared venv if it exists (used by helion, pytorch, etc.)
      if test -f $HOME/repos/.venv/bin/activate.fish
          source $HOME/repos/.venv/bin/activate.fish
      end
    '';

    shellAliases = {
      ls = "lsd";
      l = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      lt = "ls --tree";
    };

    shellAbbrs = {
      y = "yazi";
    };

    functions = {
      yy = ''
        # Yazi with cd on quit
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            cd -- "$cwd"
        end
        rm -f -- "$tmp"
      '';
    };
  };
}
