#!/usr/bin/env fish
# Cycle to the previous theme in the list
# Usage: hawker-theme-prev

set available_themes (hawker-theme-list)

if test (count $available_themes) -eq 0
    echo "Error: No themes found"
    exit 1
end

set current_theme (hawker-theme-current 2>/dev/null)

# If can't determine current, use second theme (so prev will be first)
if test -z "$current_theme"
    if test (count $available_themes) -gt 1
        set current_theme $available_themes[2]
    else
        set current_theme $available_themes[1]
    end
end

# Find current theme index
set current_index 0
for i in (seq (count $available_themes))
    if test "$available_themes[$i]" = "$current_theme"
        set current_index $i
        break
    end
end

# Get previous theme (wrap around)
set prev_index (math $current_index - 1)
if test $prev_index -lt 1
    set prev_index (count $available_themes)
end

hawker-theme-set $available_themes[$prev_index]
