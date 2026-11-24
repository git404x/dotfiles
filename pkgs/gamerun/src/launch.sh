#!/usr/bin/env bash
# launch.sh - Game execution, runtime environment preparation, and DLL overrides

GAMERUN_FALLBACK_WIDTH="${GAMERUN_FALLBACK_WIDTH:-1920}"
GAMERUN_FALLBACK_HEIGHT="${GAMERUN_FALLBACK_HEIGHT:-1080}"

get_display_geometry() {
  local mode="" conn
  for conn in /sys/class/drm/*; do
    if [ -f "$conn/status" ] && [ "$(<"$conn/status")" = "connected" ] && [ -s "$conn/modes" ]; then
      mode="$(head -n 1 "$conn/modes")"
      [ -n "$mode" ] && break
    fi
  done

  if [ -n "$mode" ]; then
    echo "${mode%x*}" "${mode#*x}"
  else
    echo "$GAMERUN_FALLBACK_WIDTH" "$GAMERUN_FALLBACK_HEIGHT"
  fi
}

run_game() {
  local mode="$1" prof="$2"
  shift 2

  case "$mode" in
    goldberg)
      export WINEDLLOVERRIDES="steam_api=n,steam_api64=n${WINEDLLOVERRIDES:+;$WINEDLLOVERRIDES}"
      ;;
    online-fix|fixed)
      export WINEDLLOVERRIDES="OnlineFix=n;OnlineFix64=n;SteamOverlay=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api=n;steam_api64=n;winhttp=n,b${WINEDLLOVERRIDES:+;$WINEDLLOVERRIDES}"
      ;;
    scope)
      local res_w res_h
      read -r res_w res_h < <(get_display_geometry)
      echo "[*] launching game in gamescope (${res_w}x${res_h})"
      set -- gamescope -W "$res_w" -H "$res_h" -f ${GAMESCOPE_ARGS:-} -- "$@"
      ;;
    base|default|*)
      ;;
  esac

  if [ "${GAMERUN_MANGOHUD:-1}" = "1" ]; then
    export MANGOHUD=1
  else
    export MANGOHUD=0
    unset MANGOHUD 2>/dev/null || true
  fi

  echo "$prof" > "$target_prof_file" 2>/dev/null || true

  if [ "${GAMERUN_NO_GAMEMODE:-0}" = "1" ]; then
    echo "[*] launching game directly with profile '${prof^^}'"
    if can_run_ryzenadj; then
      start_watchdog "$prof" >/dev/null 2>&1 || true
      cleanup_direct() {
        stop_watchdog >/dev/null 2>&1 || true
      }
      trap cleanup_direct INT TERM EXIT
      "$@"
      exit $?
    else
      exec "$@"
    fi
  else
    echo "[*] launching game under gamemode with profile '${prof^^}'"
    exec gamemoderun "$@"
  fi
}
