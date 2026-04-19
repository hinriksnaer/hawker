# Auto-activate Helion venv if it exists
if test -f $HOME/work/helion/.venv/bin/activate.fish
    source $HOME/work/helion/.venv/bin/activate.fish
end
