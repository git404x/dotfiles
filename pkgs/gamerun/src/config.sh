#!/usr/bin/env bash
# config.sh - Profile resolution, cascading JSON discovery, and configuration parsing

find_profiles_json() {
  local candidates=(
    "${GAMERUN_PROFILES:-}"
    "${XDG_CONFIG_HOME:-$HOME/.config}/gamerun/profiles.json"
    "/etc/gamerun/profiles.json"
    "${GAMERUN_DATA_DIR:-}/profiles.json"
    "$(dirname "$0")/../share/gamerun/profiles.json"
    "$(dirname "$0")/../profiles.json"
    "$(dirname "$0")/profiles.json"
  )
  for c in "${candidates[@]}"; do
    if [ -n "$c" ] && [ -f "$c" ]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

conf_file="$(find_profiles_json 2>/dev/null || true)"

load_profiles() {
  profiles=()
  if [ -n "$conf_file" ] && [ -f "$conf_file" ]; then
    mapfile -t profiles < <(jq -r '
      if (.profiles | type == "object") then
        .profiles | keys_unsorted[]
      elif (type == "object") then
        keys_unsorted[] | select(. != "default" and . != "stock" and . != "idle" and . != "reset" and . != "profiles")
      else
        empty
      end
    ' "$conf_file" 2>/dev/null || true)
  fi

  if [ ${#profiles[@]} -eq 0 ]; then
    profiles=("cool" "balanced" "performance" "max")
  fi
}
load_profiles

is_valid_profile() {
  local target="${1:-}"
  [ -z "$target" ] && return 1
  for p in "${profiles[@]}"; do
    [ "$p" = "$target" ] && return 0
  done
  return 1
}

get_default_profile() {
  local p=""
  if [ -n "$conf_file" ] && [ -f "$conf_file" ]; then
    p=$(jq -r '.default // empty' "$conf_file" 2>/dev/null || true)
  fi
  if [ -n "$p" ] && is_valid_profile "$p"; then
    echo "$p"
  elif [ -n "${GAMERUN_DEFAULT_PROFILE:-}" ] && is_valid_profile "$GAMERUN_DEFAULT_PROFILE"; then
    echo "$GAMERUN_DEFAULT_PROFILE"
  elif is_valid_profile "performance"; then
    echo "performance"
  elif [ ${#profiles[@]} -gt 0 ]; then
    echo "${profiles[0]}"
  else
    echo "balanced"
  fi
}

get_poll_interval() {
  local p=""
  if [ -n "$conf_file" ] && [ -f "$conf_file" ]; then
    p=$(jq -r '.poll_interval // empty' "$conf_file" 2>/dev/null || true)
  fi
  if [ -n "$p" ] && [[ "$p" =~ ^[0-9]+$ ]] && [ "$p" -gt 0 ]; then
    echo "$p"
  elif [ -n "${GAMERUN_POLL_INTERVAL:-}" ] && [[ "$GAMERUN_POLL_INTERVAL" =~ ^[0-9]+$ ]] && [ "$GAMERUN_POLL_INTERVAL" -gt 0 ]; then
    echo "$GAMERUN_POLL_INTERVAL"
  else
    echo 5
  fi
}

get_idle_profile() {
  local p=""
  if [ -n "$conf_file" ] && [ -f "$conf_file" ]; then
    p=$(jq -r '.stock // .idle // .reset // empty' "$conf_file" 2>/dev/null || true)
  fi
  if [ -n "$p" ] && is_valid_profile "$p"; then
    echo "$p"
  elif is_valid_profile "balanced"; then
    echo "balanced"
  elif [ ${#profiles[@]} -gt 0 ]; then
    echo "${profiles[0]}"
  else
    echo "balanced"
  fi
}

get_profile_field() {
  local prof="$1" field="$2"
  local val=""
  if [ -n "$conf_file" ] && [ -f "$conf_file" ]; then
    val=$(jq -r --arg p "$prof" --arg f "$field" '
      (if (.profiles | type == "object") then .profiles[$p][$f] else .[$p][$f] end) // empty
    ' "$conf_file" 2>/dev/null || true)
  fi

  if [ -n "$val" ]; then
    echo "$val"
    return 0
  fi

  case "$field" in
    stapm)  echo 15 ;;
    fast)   echo 18 ;;
    slow)   echo 15 ;;
    vrm)    echo 30 ;;
    vrmmax) echo 40 ;;
    temp)   echo 80 ;;
    desc)   echo "" ;;
    *)      echo "" ;;
  esac
}

get_choices() {
  local s
  s=$(printf " | %s" "${profiles[@]}")
  echo "${s:3}"
}

print_table() {
  printf "Available Power Profiles:\n"
  for name in "${profiles[@]}"; do
    local stapm fast temp vrm vrmmax desc
    stapm=$(get_profile_field "$name" "stapm")
    fast=$(get_profile_field "$name" "fast")
    temp=$(get_profile_field "$name" "temp")
    vrm=$(get_profile_field "$name" "vrm")
    vrmmax=$(get_profile_field "$name" "vrmmax")
    desc=$(get_profile_field "$name" "desc")

    printf "  %-12s - %2dW sustained / %2dW burst @ %d°C (VRM %dA/%dA)\n" \
      "$name" "$stapm" "$fast" "$temp" "$vrm" "$vrmmax"
    [ -n "$desc" ] && printf "                 %s\n" "$desc"
  done
}
