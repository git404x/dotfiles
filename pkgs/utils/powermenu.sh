#!/usr/bin/env bash

lock="󱅞 Lock"
suspend="󰒲 Suspend"
logout="󰍃 Logout"
reboot="󰜉 Reboot"
shutdown="󰐥 Shutdown"

selected=$(echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | \
  fuzzel --dmenu --lines 5 --width 20 --prompt "Power > ")

case $selected in
  "$lock") hyprlock ;;
  "$suspend") systemctl suspend ;;
  "$logout") loginctl terminate-user "$USER" ;;
  "$reboot") systemctl reboot ;;
  "$shutdown") systemctl poweroff ;;
esac
