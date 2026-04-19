#!/usr/bin/env fish
# Set terminal-only theme components (btop, neovim)
# Usage: hawker-theme-set-terminal <theme-name>
# This script handles only terminal application themes

if test (count $argv) -lt 1
    echo "Usage: hawker-theme-set-terminal <theme-name>"
    exit 1
end

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

set theme_name (echo $argv[1] | string lower | string replace -a ' ' '-')

if test -d "$themes_dir/$theme_name"
    set theme_path "$themes_dir/$theme_name"
else
    echo "Error: Theme '$theme_name' does not exist"
    exit 1
end

set applied_count 0
set skipped_count 0

# Create theme symlink for tracking current theme
mkdir -p ~/.config/hawker/current
ln -snf $theme_path ~/.config/hawker/current/theme

# Apply btop theme (symlink works fine for btop)
set btop_source "$theme_path/btop.theme"
set btop_dest "$HOME/.config/btop/themes/active.theme"
if test -f "$btop_source"
    mkdir -p (dirname $btop_dest) 2>/dev/null
    ln -sf $btop_source $btop_dest
    set applied_count (math $applied_count + 1)
else
    set skipped_count (math $skipped_count + 1)
end

# Apply neovim theme (COPY instead of symlink - Lua module loader breaks with symlinks)
set nvim_source "$theme_path/neovim.lua"
set nvim_dest "$HOME/.config/nvim/lua/plugins/theme.lua"
if test -f "$nvim_source"
    mkdir -p (dirname $nvim_dest) 2>/dev/null
    cp -f $nvim_source $nvim_dest
    set applied_count (math $applied_count + 1)
else
    set skipped_count (math $skipped_count + 1)
end

# Apply yazi theme (use flavor system)
if command -v yazi >/dev/null 2>&1
    set yazi_theme_script "$HOME/.local/bin/hawker-set-yazi-theme"
    if test -x "$yazi_theme_script"
        set yazi_result ($yazi_theme_script $theme_name 2>/dev/null)
        if test $status -eq 0
            set applied_count (math $applied_count + 1)
        else
            set skipped_count (math $skipped_count + 1)
        end
    end
end

# Reload btop if running
if pgrep -x btop >/dev/null 2>&1
    pkill -SIGUSR2 btop 2>/dev/null
end

# Return counts for caller
echo "$applied_count:$skipped_count"
