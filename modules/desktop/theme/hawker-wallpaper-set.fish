#!/usr/bin/env fish
# Set wallpaper from current theme (uses first wallpaper found)
# Usage: hawker-wallpaper-set [theme-name]
# If no theme-name provided, uses current theme
# Uses swaybg (like omarchy)

# Find themes directory using active profile
if test -n "$HAWKER_PATH"; and test -d "$HAWKER_PATH/themes"
    # Using HAWKER_PATH directly
    set themes_dir "$HAWKER_PATH/themes"
else
    echo "Error: Active profile not found"
    exit 1
end
set current_wallpaper_link "$HOME/.config/hypr/wallpapers/current"

# Determine theme name
if test (count $argv) -ge 1
    set theme_name (echo $argv[1] | string lower | string replace -a ' ' '-')
else
    set theme_name (hawker-theme-current 2>/dev/null)
    if test -z "$theme_name"
        echo "Error: No theme set and no theme name provided"
        exit 1
    end
end

set backgrounds_dir "$themes_dir/$theme_name/backgrounds"

# Check if backgrounds directory exists
if not test -d "$backgrounds_dir"
    echo "⊘ No wallpapers found for theme '$theme_name'"
    # Clear current wallpaper link if it exists
    rm -f "$current_wallpaper_link"
    return 0
end

# Get first background image
set first_wallpaper (find -L "$backgrounds_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | sort | head -1)

if test -z "$first_wallpaper"
    echo "⊘ No wallpaper images found in theme backgrounds"
    rm -f "$current_wallpaper_link"
    # Set black background if no wallpaper
    pkill -x swaybg 2>/dev/null
    swaybg --color '#000000' >/dev/null 2>&1 &
    disown
    return 0
end

# Create wallpapers directory if needed and set wallpaper symlink
mkdir -p (dirname "$current_wallpaper_link")
ln -sf "$first_wallpaper" "$current_wallpaper_link"

# Start new swaybg, wait for render, kill old one
set old_pids (pgrep -x swaybg)
swaybg -i "$current_wallpaper_link" -m fill >/dev/null 2>&1 &
disown
sleep 0.5
for pid in $old_pids
    kill $pid 2>/dev/null
end

set wallpaper_name (basename "$first_wallpaper")
echo "✓ Wallpaper set to: $wallpaper_name"
