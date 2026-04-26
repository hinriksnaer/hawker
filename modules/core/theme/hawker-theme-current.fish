#!/usr/bin/env fish
# Get the currently active theme
# Usage: hawker-theme-current

set state_file "$HOME/.config/hawker/current-theme"

if test -f "$state_file"
    set theme_name (string trim (cat "$state_file"))
    if test -n "$theme_name"
        echo "$theme_name"
        exit 0
    end
end

# No theme set
echo ""
exit 1
