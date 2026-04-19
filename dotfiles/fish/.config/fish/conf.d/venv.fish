# Auto-activate shared venv if it exists (used by helion, pytorch, etc.)
if test -f $HOME/repos/.venv/bin/activate.fish
    source $HOME/repos/.venv/bin/activate.fish
end
