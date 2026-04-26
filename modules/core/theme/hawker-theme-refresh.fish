#!/usr/bin/env fish
# Refresh/reapply the current theme (useful after config changes)
# Usage: hawker-theme-refresh

set active_theme_conf "$HOME/.config/hypr/active-theme.conf"

# Extract current theme from active-theme.conf
if not test -f "$active_theme_conf"
    echo "Error: No active-theme.conf found"
    echo "Run 'hawker-theme-set <theme-name>' first"
    exit 1
end

# Try 1: look for "# theme: <name>" marker (written by hawker-theme-set-desktop)
set theme_name ""
set marker_line (grep '^# theme:' "$active_theme_conf" 2>/dev/null)
if test -n "$marker_line"
    set theme_name (echo $marker_line | sed 's/^# theme: *//')
end

# Try 2: fall back to symlink at ~/.config/hawker/current/theme
if test -z "$theme_name"; and test -L "$HOME/.config/hawker/current/theme"
    set theme_name (basename (readlink "$HOME/.config/hawker/current/theme"))
end

if test -n "$theme_name"
    echo "Refreshing theme: $theme_name"
    hawker-theme-set $theme_name
else
    echo "Error: Could not detect current theme"
    echo "Run 'hawker-theme-set <theme-name>' first"
    exit 1
end
