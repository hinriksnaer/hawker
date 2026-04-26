#!/usr/bin/env fish
# Brightness control with OSD notification
# Usage: brightness-control [up|down]

set action $argv[1]

switch $action
    case up
        brightnessctl set 5%+
    case down
        brightnessctl set 5%-
    case '*'
        echo "Usage: brightness-control [up|down]"
        exit 1
end

# Get current brightness percentage
set brightness_percent (brightnessctl -m | awk -F, '{gsub(/%/, "", $4); print $4}')

# Determine icon
if test $brightness_percent -lt 33
    set icon "display-brightness-low"
else if test $brightness_percent -lt 66
    set icon "display-brightness-medium"
else
    set icon "display-brightness-high"
end

# Send notification with progress bar hint
notify-send -t 1500 -h string:x-canonical-private-synchronous:brightness -h int:value:$brightness_percent -i $icon -u low "$brightness_percent%" ""
