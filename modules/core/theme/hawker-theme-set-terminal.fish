#!/usr/bin/env fish
# Apply theme to terminal applications (btop, neovim, yazi, opencode)
# Usage: hawker-theme-set-terminal <theme-name>
# Returns applied:skipped counts on stdout

if test (count $argv) -lt 1
    echo "Usage: hawker-theme-set-terminal <theme-name>"
    exit 1
end

# Find themes directory
if test -n "$HAWKER_PATH"; and test -d "$HAWKER_PATH/themes"
    set themes_dir "$HAWKER_PATH/themes"
else
    set themes_dir "$HOME/.local/share/hawker/themes"
end

set theme_name (echo $argv[1] | string lower | string replace -a ' ' '-')

if not test -d "$themes_dir/$theme_name"
    echo "Error: Theme '$theme_name' does not exist"
    exit 1
end

set theme_path "$themes_dir/$theme_name"
set applied_count 0
set skipped_count 0

# ── btop ──
set btop_source "$theme_path/btop.theme"
set btop_dest "$HOME/.config/btop/themes/active.theme"
if test -f "$btop_source"
    mkdir -p (dirname $btop_dest) 2>/dev/null
    ln -sf $btop_source $btop_dest
    set applied_count (math $applied_count + 1)
else
    set skipped_count (math $skipped_count + 1)
end

# Reload btop if running
if pgrep -x btop >/dev/null 2>&1
    pkill -SIGUSR2 btop 2>/dev/null
end

# ── neovim ──
# COPY instead of symlink -- Lua module loader breaks with symlinks
set nvim_source "$theme_path/neovim.lua"
set nvim_dest "$HOME/.config/nvim/lua/plugins/theme.lua"
if test -f "$nvim_source"
    mkdir -p (dirname $nvim_dest) 2>/dev/null
    cp -f $nvim_source $nvim_dest
    set applied_count (math $applied_count + 1)
else
    set skipped_count (math $skipped_count + 1)
end

# ── yazi ──
# Map hawker theme name to yazi flavor via theme-map.conf
if command -v yazi >/dev/null 2>&1
    set theme_map "$HOME/.config/yazi/theme-map.conf"
    set yazi_flavor ""

    if test -f "$theme_map"
        for line in (grep -v '^#' "$theme_map" | grep -v '^$')
            set parts (string split "=" $line)
            if test "$parts[1]" = "$theme_name"
                set yazi_flavor $parts[2]
                break
            end
        end
    end

    # Fallback if no mapping found
    if test -z "$yazi_flavor"
        set yazi_flavor "catppuccin-mocha"
    end

    set theme_file "$HOME/.config/yazi/theme.toml"
    printf '%s\n' \
        '# Yazi Theme for Hawker' \
        '# Managed by hawker-theme-set - Do not edit manually' \
        '' \
        '[flavor]' \
        "use = \"$yazi_flavor\"" \
        > $theme_file 2>/dev/null

    if test $status -eq 0
        set applied_count (math $applied_count + 1)
    else
        set skipped_count (math $skipped_count + 1)
    end
else
    set skipped_count (math $skipped_count + 1)
end

# ── opencode ──
# Rewrite theme key in tui.json
set oc_config "$HOME/.config/opencode/tui.json"
if test -f "$oc_config"
    sed -i "s/\"theme\": *\"[^\"]*\"/\"theme\": \"$theme_name\"/" "$oc_config" 2>/dev/null
    if test $status -eq 0
        set applied_count (math $applied_count + 1)
    else
        set skipped_count (math $skipped_count + 1)
    end
else
    set skipped_count (math $skipped_count + 1)
end

# Return counts for caller
echo "$applied_count:$skipped_count"
