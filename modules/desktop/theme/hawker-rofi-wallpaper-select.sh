# Wallpaper selector with image previews using rofi grid layout

THEMES_DIR="$HOME/.local/share/hawker/themes"
CURRENT_THEME=$(hawker-theme-current 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
WALLPAPER_DIR="$THEMES_DIR/$CURRENT_THEME/backgrounds"
CURRENT_WALLPAPER=$(readlink -f "$HOME/.config/hypr/wallpapers/current" 2>/dev/null)

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    notify-send "Wallpaper Selector" "No wallpapers for theme: $CURRENT_THEME" -t 3000
    exit 1
fi

mapfile -t WALLPAPERS < <(find -L "$WALLPAPER_DIR" -type f | grep -iE '\.(jpg|jpeg|png|webp)$' | sort)

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    notify-send "Wallpaper Selector" "No wallpaper images found" -t 3000
    exit 1
fi

MENU_ITEMS=""
for wp in "${WALLPAPERS[@]}"; do
    resolved=$(readlink -f "$wp")
    name=$(basename "$wp" | sed 's/\.[^.]*$//; s/\.[^.]*$//; s/-/ /g; s/_/ /g')
    if [[ "$resolved" == "$CURRENT_WALLPAPER" ]]; then
        MENU_ITEMS+="* $name\x00icon\x1f$resolved\n"
    else
        MENU_ITEMS+="  $name\x00icon\x1f$resolved\n"
    fi
done

SELECTED=$(echo -e "$MENU_ITEMS" | rofi -dmenu \
    -i \
    -p "Wallpaper" \
    -show-icons \
    -theme-str 'window {width: 80%; height: 70%;}' \
    -theme-str 'mainbox {padding: 20px;}' \
    -theme-str 'listview {columns: 4; lines: 2; flow: horizontal; fixed-columns: true; fixed-lines: true; spacing: 20px;}' \
    -theme-str 'element {orientation: vertical; padding: 10px; spacing: 8px; border-radius: 10px;}' \
    -theme-str 'element-icon {size: 20%; border-radius: 8px;}' \
    -theme-str 'element-text {horizontal-align: 0.5;}' \
    -theme-str 'inputbar {padding: 12px; margin: 0 0 20px 0; border-radius: 8px;}')

if [[ -z "$SELECTED" ]]; then
    exit 0
fi

SELECTED_CLEAN="${SELECTED#\* }"
SELECTED_CLEAN="${SELECTED_CLEAN# }"

SELECTED_PATH=""
for wp in "${WALLPAPERS[@]}"; do
    name=$(basename "$wp" | sed 's/\.[^.]*$//; s/\.[^.]*$//; s/-/ /g; s/_/ /g')
    if [[ "$name" == "$SELECTED_CLEAN" ]]; then
        SELECTED_PATH="$wp"
        break
    fi
done

if [[ -n "$SELECTED_PATH" ]]; then
    mkdir -p "$HOME/.config/hypr/wallpapers"
    ln -sf "$SELECTED_PATH" "$HOME/.config/hypr/wallpapers/current"

    OLD_PIDS=$(pgrep -f swaybg)
    swaybg -i "$SELECTED_PATH" -m fill >/dev/null 2>&1 &
    sleep 0.5
    for pid in $OLD_PIDS; do
        kill "$pid" 2>/dev/null
    done

    notify-send "Wallpaper Changed" "$(basename "$SELECTED_PATH")" -t 2000
fi
