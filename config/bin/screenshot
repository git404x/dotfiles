#!/usr/bin/env bash

# Take screenshot of active monitor in hyprland

active_workspace_monitor=$(hyprctl -j activeworkspace | jq -r '(.monitor)')
screenshot_filename="$HOME/Pictures/screenshots/$(date +"%d-%m-%Y-%H%S")-$active_workspace_monitor.png"

grim -o $active_workspace_monitor $screenshot_filename

if [ -e $screenshot_filename ]; then
    notify-desktop -i $screenshot_filename "Grim" "Screenshot Saved at $screenshot_filename"
fi
