#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "usage: clipboard [--manage | --pin | --unpin | --clear | --watch]"
  exit 0
fi

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/clipboard"
PINNED_FILE="$DATA_DIR/pinned"
PINNED_IMG_DIR="$DATA_DIR/pinned_images"

# Declarative glyph registry
declare -A GLYPHS=(
  [pin]="󰐃"
  [unpin]="󰅁"
  [secret]="󰌆"
  [link]="󰌹"
  [path]="󰉋"
  [cmd]="󰞷"
  [color]="󰏘"
  [image]="󰋩"
  [text]="󰅍"
)

classify_text() {
  local text="$1"

  # Colors (hex or rgb/rgba)
  if [[ "$text" =~ ^#[0-9a-fA-F]{3,8}$ || "$text" =~ ^rgba?\([0-9,\ .%]+\)$ ]]; then
    printf "%s  %s\n" "${GLYPHS[color]}" "${text:0:80}"
    return 0
  fi

  # Web Links / URLs
  if [[ "$text" =~ ^(https?://|ftp://|git@[a-zA-Z0-9.-]+:) ]]; then
    printf "%s  %s\n" "${GLYPHS[link]}" "${text:0:80}"
    return 0
  fi

  # Filesystem Paths
  if [[ "$text" =~ ^(/|\./|~/)[a-zA-Z0-9_.-]* ]]; then
    printf "%s  %s\n" "${GLYPHS[path]}" "${text:0:80}"
    return 0
  fi

  # Secrets / Tokens / Passwords
  if [[ "$text" =~ ^(ghp_|gho_|github_pat_|glpat-|xoxb-|xoxp-|eyJh|sk-|AKIA|bearer\ |-----BEGIN) ]]; then
    printf "%s  ••••••••••••••••  (Secret)\n" "${GLYPHS[secret]}"
    return 0
  fi
  if [[ ${#text} -ge 12 && ${#text} -le 64 && ! "$text" =~ [[:space:]/] ]]; then
    if [[ "$text" =~ [0-9] && "$text" =~ [a-z] && "$text" =~ [A-Z] && "$text" =~ [^a-zA-Z0-9] ]]; then
      printf "%s  ••••••••••••••••  (Secret)\n" "${GLYPHS[secret]}"
      return 0
    fi
  fi

  # Shell Commands
  if [[ "$text" =~ ^(nix|git|cargo|npm|pnpm|yarn|docker|kubectl|systemctl|journalctl|ssh|scp|curl|wget|tar|find|grep|sed|awk|make|bash|sh|zsh|doas|sudo|kill|pkill)\  ]]; then
    printf "%s  %s\n" "${GLYPHS[cmd]}" "${text:0:80}"
    return 0
  fi

  # Default plain text
  printf "%s  %s\n" "${GLYPHS[text]}" "${text:0:80}"
}

load_history() {
  local -n out_labels=$1
  local -n out_ids=$2
  local -n out_meta=$3

  local last_res=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local id="${line%%	*}"
    local content="${line#*	}"

    if [[ "$content" =~ ^\[\[\ binary\ data\ ([0-9.]+\ [A-Za-z]+)\ ([a-z0-9]+)\ ([0-9]+x[0-9]+)\ \]\]$ ]]; then
      local size="${BASH_REMATCH[1]}"
      local ext="${BASH_REMATCH[2]}"
      local res="${BASH_REMATCH[3]}"

      # Suppress duplicate multi-MIME entries (e.g. BMP alongside JPEG/PNG from Telegram)
      if [ "$ext" = "bmp" ] && [ "$res" = "$last_res" ]; then
        continue
      fi
      last_res="$res"

      if [ "$res" = "1366x768" ]; then
        out_labels+=("${GLYPHS[image]}  Screenshot [$res • $size $ext]")
      else
        out_labels+=("${GLYPHS[image]}  Image [$res • $size $ext]")
      fi
      out_ids+=("$id")
      out_meta+=("1:$ext:$res:$size")
    else
      last_res=""
      out_labels+=("$(classify_text "$content")")
      out_ids+=("$id")
      out_meta+=("0")
    fi
  done < <(cliphist list 2>/dev/null)
}

open_pinned_submenu() {
  if [ ! -s "$PINNED_FILE" ]; then
    notify-send -u low "Clipboard" "No pinned items"
    return 0
  fi

  local pin_labels=()
  local pin_types=()
  local pin_values=()

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [[ "$line" =~ ^txt:(.*)$ ]]; then
      local text
      text=$(printf "%s" "${BASH_REMATCH[1]}" | base64 -d 2>/dev/null || true)
      [ -z "$text" ] && continue
      local first_line
      first_line=$(printf "%s" "$text" | head -n 1)
      pin_labels+=("$(classify_text "$first_line")")
      pin_types+=("txt")
      pin_values+=("$text")
    elif [[ "$line" =~ ^img:([^:]+):([^:]+):(.*)$ ]]; then
      local fname="${BASH_REMATCH[1]}"
      local res="${BASH_REMATCH[2]}"
      local size="${BASH_REMATCH[3]}"
      local img_path="$PINNED_IMG_DIR/$fname"
      [ ! -s "$img_path" ] && continue
      if [ "$res" = "1366x768" ]; then
        pin_labels+=("${GLYPHS[image]}  Screenshot [$res • $size]")
      else
        pin_labels+=("${GLYPHS[image]}  Image [$res • $size]")
      fi
      pin_types+=("img")
      pin_values+=("$img_path")
    fi
  done < "$PINNED_FILE"

  [ "${#pin_labels[@]}" -eq 0 ] && return 0

  local sel
  sel=$(printf '%s\n' "${pin_labels[@]}" | fuzzel --dmenu --index --prompt "Pinned > " || true)
  [ -z "$sel" ] && return 0

  local sel_type="${pin_types[$sel]}"
  local sel_val="${pin_values[$sel]}"

  if [ "$sel_type" = "img" ]; then
    wl-copy < "$sel_val"
    notify-send -u low "Clipboard" "Copied pinned image to clipboard"
  else
    printf '%s' "$sel_val" | wl-copy
    notify-send -u low "Clipboard" "Copied pinned item to clipboard"
  fi
}

clip_pin() {
  local hist_labels=()
  local hist_ids=()
  local hist_meta=()
  load_history hist_labels hist_ids hist_meta

  if [ "${#hist_labels[@]}" -eq 0 ]; then
    notify-send -u low "Clipboard" "Clipboard history is empty"
    return 0
  fi

  local sel
  sel=$(printf '%s\n' "${hist_labels[@]}" | fuzzel --dmenu --index --prompt "Pin > " || true)
  [ -z "$sel" ] && return 0

  local id="${hist_ids[$sel]}"
  local meta="${hist_meta[$sel]}"

  mkdir -p "$DATA_DIR" "$PINNED_IMG_DIR"
  touch "$PINNED_FILE"

  if [ "$meta" != "0" ]; then
    local ext res size
    IFS=":" read -r _ ext res size <<< "$meta"

    local hash
    hash=$(printf "%s\t" "$id" | cliphist decode | sha256sum | awk '{print $1}')
    local img_path="$PINNED_IMG_DIR/${hash}.${ext}"
    if [ ! -s "$img_path" ]; then
      printf "%s\t" "$id" | cliphist decode > "$img_path"
    fi

    local entry="img:${hash}.${ext}:${res}:${size}"
    if grep -Fxq "$entry" "$PINNED_FILE" 2>/dev/null; then
      notify-send -u low "Clipboard" "Image already pinned"
      return 0
    fi
    printf '%s\n' "$entry" >> "$PINNED_FILE"
    notify-send -u low "Clipboard" "Pinned image to clipboard"
  else
    local text
    text=$(printf "%s\t" "$id" | cliphist decode)
    local b64
    b64=$(printf "%s" "$text" | base64 -w0)
    local entry="txt:${b64}"
    if grep -Fxq "$entry" "$PINNED_FILE" 2>/dev/null; then
      notify-send -u low "Clipboard" "Item already pinned"
      return 0
    fi
    printf '%s\n' "$entry" >> "$PINNED_FILE"
    notify-send -u low "Clipboard" "Pinned item to clipboard"
  fi
}

clip_unpin() {
  if [ ! -s "$PINNED_FILE" ]; then
    notify-send -u low "Clipboard" "No pinned items"
    return 0
  fi

  local pin_lines=()
  local pin_labels=()
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [[ "$line" =~ ^txt:(.*)$ ]]; then
      local text
      text=$(printf "%s" "${BASH_REMATCH[1]}" | base64 -d 2>/dev/null || true)
      [ -z "$text" ] && continue
      pin_lines+=("$line")
      local first_line
      first_line=$(printf "%s" "$text" | head -n 1)
      local item_label
      item_label=$(classify_text "$first_line")
      pin_labels+=("${GLYPHS[unpin]}  ${item_label#*  }")
    elif [[ "$line" =~ ^img:([^:]+):([^:]+):(.*)$ ]]; then
      local fname="${BASH_REMATCH[1]}"
      local res="${BASH_REMATCH[2]}"
      local size="${BASH_REMATCH[3]}"
      pin_lines+=("$line")
      if [ "$res" = "1366x768" ]; then
        pin_labels+=("${GLYPHS[unpin]}  Screenshot [$res • $size]")
      else
        pin_labels+=("${GLYPHS[unpin]}  Image [$res • $size]")
      fi
    fi
  done < "$PINNED_FILE"

  [ "${#pin_labels[@]}" -eq 0 ] && return 0

  local sel
  sel=$(printf '%s\n' "${pin_labels[@]}" | fuzzel --dmenu --index --prompt "Unpin > " || true)
  [ -z "$sel" ] && return 0

  local target="${pin_lines[$sel]}"
  local tmp_file
  tmp_file=$(mktemp)
  grep -Fxv "$target" "$PINNED_FILE" > "$tmp_file" || true
  mv "$tmp_file" "$PINNED_FILE"

  # Clean up image file if no longer referenced
  if [[ "$target" =~ ^img:([^:]+): ]]; then
    local fname="${BASH_REMATCH[1]}"
    if ! grep -q "$fname" "$PINNED_FILE" 2>/dev/null; then
      rm -f "$PINNED_IMG_DIR/$fname"
    fi
  fi
  notify-send -u low "Clipboard" "Unpinned item"
}

manage_clipboard() {
  mkdir -p "$DATA_DIR"
  touch "$PINNED_FILE"

  local pin_count=0
  if [ -s "$PINNED_FILE" ]; then
    pin_count=$(grep -cE '^(txt|img):' "$PINNED_FILE" || true)
  fi

  local display_labels=()
  local item_actions=()
  local item_data=()

  # 1. Pinned items submenu
  if [ "$pin_count" -gt 0 ]; then
    display_labels+=("${GLYPHS[pin]}  Pinned Items (${pin_count})...")
    item_actions+=("submenu_pinned")
    item_data+=("")
  fi

  # 2. Pin action (prompts user to pick from history)
  display_labels+=("${GLYPHS[pin]}  Pin an Item...")
  item_actions+=("action_pin")
  item_data+=("")

  # 3. Unpin action
  if [ "$pin_count" -gt 0 ]; then
    display_labels+=("${GLYPHS[unpin]}  Unpin an Item...")
    item_actions+=("action_unpin")
    item_data+=("")
  fi

  # 4. History items from cliphist
  local hist_labels=()
  local hist_ids=()
  local hist_meta=()
  load_history hist_labels hist_ids hist_meta

  for i in "${!hist_labels[@]}"; do
    display_labels+=("${hist_labels[$i]}")
    item_actions+=("history")
    item_data+=("${hist_ids[$i]}")
  done

  [ "${#display_labels[@]}" -eq 0 ] && exit 0

  local sel
  sel=$(printf '%s\n' "${display_labels[@]}" | fuzzel --dmenu --index --prompt "Clipboard > " || true)
  [ -z "$sel" ] && exit 0

  local action="${item_actions[$sel]}"
  local data="${item_data[$sel]}"

  case "$action" in
    submenu_pinned)
      open_pinned_submenu
      ;;
    action_pin)
      clip_pin
      ;;
    action_unpin)
      clip_unpin
      ;;
    history)
      printf '%s\t' "$data" | cliphist decode | wl-copy
      ;;
  esac
}

case "${1:-}" in
  --manage)
    manage_clipboard
    ;;
  --pin)
    clip_pin
    ;;
  --unpin)
    clip_unpin
    ;;
  --clear)
    cliphist wipe
    notify-send -u low "Clipboard" "Clipboard history cleared (pinned items preserved)"
    ;;
  --watch)
    pkill -f "wl-paste.*cliphist store" 2>/dev/null || true
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &
    wait
    ;;
  *)
    echo "usage: clipboard [--manage | --pin | --unpin | --clear | --watch]"
    exit 1
    ;;
esac
