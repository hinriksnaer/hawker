#!/usr/bin/env fish
# Refresh/reapply the current theme (useful after config changes)
# Usage: hawker-theme-refresh

set current_theme (hawker-theme-current 2>/dev/null)

if test -n "$current_theme"
    echo "Refreshing theme: $current_theme"
    hawker-theme-set $current_theme
else
    echo "Error: No theme is currently set"
    echo "Run 'hawker-theme-set <theme-name>' first"
    exit 1
end
