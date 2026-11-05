#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "usage: powermenu"
  exit 0
fi

# Declarative action map: "LABEL|COMMAND"
actions=(
  "󱅞  Lock|hyprlock"
  "󰒲  Suspend|systemctl suspend"
  "󰍃  Logout|loginctl terminate-user $USER"
  "󰜉  Reboot|systemctl reboot"
  "󰐥  Shutdown|systemctl poweroff"
)

labels=()
for item in "${actions[@]}"; do
  labels+=("${item%%|*}")
done

selected=$(printf '%s\n' "${labels[@]}" | \
  fuzzel --dmenu --lines "${#actions[@]}" --width 20 --prompt "Power > " || true)

[ -z "$selected" ] && exit 0

for item in "${actions[@]}"; do
  if [ "$selected" = "${item%%|*}" ]; then
    cmd="${item#*|}"
    exec $cmd
  fi
done
