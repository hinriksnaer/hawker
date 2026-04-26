#!/usr/bin/env fish
# Cycle to the next theme in the list
# Usage: hawker-theme-next

set available_themes (hawker-theme-list)

if test (count $available_themes) -eq 0
    echo "Error: No themes found"
    exit 1
end

set current_theme (hawker-theme-current 2>/dev/null)

# If can't determine current, use last theme (so next will be first)
if test -z "$current_theme"
    set current_theme $available_themes[-1]
end

# Find current theme index
set current_index 0
for i in (seq (count $available_themes))
    if test "$available_themes[$i]" = "$current_theme"
        set current_index $i
        break
    end
end

# Get next theme (wrap around)
set next_index (math $current_index + 1)
if test $next_index -gt (count $available_themes)
    set next_index 1
end

hawker-theme-set $available_themes[$next_index]
