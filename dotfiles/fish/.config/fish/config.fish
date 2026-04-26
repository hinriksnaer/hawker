# Fish shell interactive init (portable)
#
# On NixOS hosts, programs.fish.interactiveShellInit in modules/core/fish.nix
# provides this config via /etc/fish/. This dotfile ensures the same setup
# works inside containers and non-NixOS environments where the NixOS
# fish module is not available.

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

# lsd aliases
if command -v lsd >/dev/null 2>&1
    alias ls='lsd'
    alias l='ls -l'
    alias la='ls -a'
    alias lla='ls -la'
    alias lt='ls --tree'
end

# Yazi abbreviation
abbr -a y "yazi"

# Auto-activate shared venv if it exists (used by helion, pytorch, etc.)
if test -f $HOME/repos/.venv/bin/activate.fish
    source $HOME/repos/.venv/bin/activate.fish
end

# SSH Agent (Proton Pass)
if test -S $HOME/.ssh/proton-pass-agent.sock
    set -gx SSH_AUTH_SOCK $HOME/.ssh/proton-pass-agent.sock
end
