#!/usr/bin/env fish
# Volume control with OSD notification
# Usage: volume-control [up|down|mute]

set action $argv[1]
set active_sink "@DEFAULT_AUDIO_SINK@"

switch $action
    case up
        wpctl set-volume $active_sink 5%+
    case down
        wpctl set-volume $active_sink 5%-
    case mute
        wpctl set-mute $active_sink toggle
    case '*'
        echo "Usage: volume-control [up|down|mute]"
        exit 1
end

# Get current volume and mute status
set volume_info (wpctl get-volume $active_sink)
set volume_value (echo $volume_info | awk '{print $2}')
set volume_percent (math "round($volume_value * 100)")
set is_muted (echo $volume_info | grep -q "MUTED" && echo "yes" || echo "no")

# Determine icon
if test "$is_muted" = "yes"
    set icon "audio-volume-muted"
else if test $volume_percent -lt 33
    set icon "audio-volume-low"
else if test $volume_percent -lt 66
    set icon "audio-volume-medium"
else
    set icon "audio-volume-high"
end

# Send notification with progress bar hint
if test "$is_muted" = "yes"
    notify-send -t 1500 -h string:x-canonical-private-synchronous:volume -h int:value:0 -i $icon -u low "Volume" "Muted"
else
    notify-send -t 1500 -h string:x-canonical-private-synchronous:volume -h int:value:$volume_percent -i $icon -u low "$volume_percent%" ""
end
