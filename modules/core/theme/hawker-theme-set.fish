#!/usr/bin/env fish
# Set a specific theme by name
# Usage: hawker-theme-set <theme-name>

if test (count $argv) -lt 1
    echo "Usage: hawker-theme-set <theme-name>"
    echo ""
    echo "Available themes:"
    hawker-theme-list
    exit 1
end

set theme_name (echo $argv[1] | string lower | string replace -a ' ' '-')
set pretty_name (echo $theme_name | sed 's/-/ /g; s/\b\(.\)/\u\1/g')

# Verify theme exists
if test -n "$HAWKER_PATH"; and test -d "$HAWKER_PATH/themes"
    set themes_dir "$HAWKER_PATH/themes"
else
    set themes_dir "$HOME/.local/share/hawker/themes"
end

if not test -d "$themes_dir/$theme_name"
    echo "Error: Theme '$theme_name' does not exist"
    echo ""
    echo "Available themes:"
    hawker-theme-list
    exit 1
end

# 1. Write global state
mkdir -p "$HOME/.config/hawker"
echo "$theme_name" > "$HOME/.config/hawker/current-theme"

# 2. Apply terminal themes (always)
echo ""
echo "Switching to theme: $pretty_name"
echo ""

set result (hawker-theme-set-terminal $theme_name)
set terminal_status $status

# 3. Apply desktop themes (only if available)
if command -v hawker-theme-set-desktop >/dev/null 2>&1
    hawker-theme-set-desktop $theme_name
else
    # Terminal-only output
    if test $terminal_status -eq 0
        set counts (string split ":" $result)
        set applied $counts[1]
        set skipped $counts[2]

        echo ""
        echo "Theme switched to: $pretty_name"
        echo "  Applied: $applied  Skipped: $skipped"
        echo ""
    else
        echo "Failed to switch theme"
        exit 1
    end
end
