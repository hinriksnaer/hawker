# Auto-activate Helion venv if it exists
if test -f /home/softmax/work/helion/.venv/bin/activate.fish
    source /home/softmax/work/helion/.venv/bin/activate.fish
    cd /home/softmax/work/helion
end
