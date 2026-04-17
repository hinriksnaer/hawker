# Environment variables
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/go/bin
# Note: Rust/Cargo PATH is managed in conf.d/installer-managed.fish

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

# Default terminal for GUI applications
set -gx TERMINAL kitty

# SSH Agent (Proton Pass)
set -gx SSH_AUTH_SOCK $HOME/.ssh/proton-pass-agent.sock

# Source virtual environment if it exists
if test -f ~/.venv/bin/activate.fish
    source ~/.venv/bin/activate.fish
end
