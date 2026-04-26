#!/usr/bin/env fish
# Get the currently active theme
# Usage: hawker-theme-current

# Find themes directory - use active profile
if test -n "$HAWKER_PATH"; and test -d "$HAWKER_PATH/themes"
    # Using HAWKER_PATH directly
    set themes_dir "$HAWKER_PATH/themes"
else if test -n "$HAWKER_USER"
    set themes_dir "$HOME/.local/share/hawker/themes"
else
    # Try to find relative to script location (for running from repo)
    set themes_dir "$HAWKER_PATH/themes"
end

# First try active-theme.conf marker (most accurate for desktop)
set active_theme_conf "$HOME/.config/hypr/active-theme.conf"
if test -f "$active_theme_conf"
    set marker_line (grep '^# theme:' "$active_theme_conf" 2>/dev/null)

    if test -n "$marker_line"
        set theme_name (echo $marker_line | sed 's/^# theme: *//')

        # Verify the theme directory actually exists
        if test -d "$themes_dir/$theme_name"
            # Format nicely: convert dashes to spaces and capitalize
            echo $theme_name | sed 's/-/ /g; s/\b\(.\)/\u\1/g'
            exit 0
        end
    end
end

# Fallback: try the common theme symlink (works for terminal-only)
if test -L "$HOME/.config/hawker/current/theme"
    set theme_name (basename (readlink "$HOME/.config/hawker/current/theme"))

    # Verify the theme directory actually exists
    if test -d "$themes_dir/$theme_name"
        # Format nicely: convert dashes to spaces and capitalize
        echo $theme_name | sed 's/-/ /g; s/\b\(.\)/\u\1/g'
        exit 0
    end
end

# No valid theme found
echo ""
exit 1
