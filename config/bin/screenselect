#!/usr/bin/env bash

# Take screenshot of selection in wayland

screenshot_filename="$HOME/Pictures/screenshots/$(date +"%d-%m-%Y-%H%S")-Selection.png"

grim -g "$(slurp -d)" $screenshot_filename

if [ -e $screenshot_filename ]; then
    notify-desktop -i $screenshot_filename "Grim" "Selection Screenshot Saved at $screenshot_filename"
fi
