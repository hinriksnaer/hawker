# History
set -g fish_history_size 10000

# Vi mode
fish_vi_key_bindings

# lsd aliases (only set if lsd is installed)
if command -v lsd >/dev/null 2>&1
    alias ls='lsd'
    alias l='ls -l'
    alias la='ls -a'
    alias lla='ls -la'
    alias lt='ls --tree'
end

# fzf integration (only load if fzf is installed)
if command -v fzf >/dev/null 2>&1
    fzf --fish | source
end

# Starship prompt (only load if starship is installed)
if command -v starship >/dev/null 2>&1
    starship init fish | source
end

# zoxide (smart cd, only load if installed)
if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end

# SSH Agent (Proton Pass)
if test -S $HOME/.ssh/proton-pass-agent.sock
    set -gx SSH_AUTH_SOCK $HOME/.ssh/proton-pass-agent.sock
end
