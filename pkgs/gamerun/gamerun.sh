#!/usr/bin/env bash
set -euo pipefail

# locate configuration file
find_profiles_conf() {
  local candidates=(
    "${GAMERUN_PROFILES:-}"
    "${XDG_CONFIG_HOME:-$HOME/.config}/gamerun/profiles.conf"
    "/etc/gamerun/profiles.conf"
    "${GAMERUN_DATA_DIR:-}/profiles.conf"
    "$(dirname "$0")/../share/gamerun/profiles.conf"
    "$(dirname "$0")/profiles.conf"
  )
  for c in "${candidates[@]}"; do
    if [ -n "$c" ] && [ -f "$c" ]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

conf_file="$(find_profiles_conf)" || {
  echo "[-] gamerun: profiles.conf not found" >&2
  exit 1
}
# shellcheck source=/dev/null
source "$conf_file"

# validate profile name
is_valid_profile() {
  local target="${1:-}"
  for p in "${profiles[@]}"; do
    [ "$p" = "$target" ] && return 0
  done
  return 1
}

# format profile list for cli choices
get_choices() {
  local s
  s=$(printf " | %s" "${profiles[@]}")
  echo "${s:3}"
}

# dynamic formatted table generated directly from numerical values
print_table() {
  printf "Available Power Profiles:\n"
  for name in "${profiles[@]}"; do
    declare -n p="$name"
    printf "  %-12s - %2dW sustained / %2dW burst @ %d°C (VRM %dA/%dA)\n" \
      "$name" "${p[stapm]}" "${p[fast]}" "${p[temp]}" "${p[vrm]}" "${p[vrmmax]}"
    [ -n "${p[desc]:-}" ] && printf "                 %s\n" "${p[desc]}"
  done
}

# locate ryzenadj wrapper or system binary
find_ryzenadj() {
  if [ -x "/run/wrappers/bin/ryzenadj" ]; then
    echo "/run/wrappers/bin/ryzenadj"
  else
    command -v ryzenadj 2>/dev/null || echo "ryzenadj"
  fi
}

# apply profile values to hardware via ryzenadj
apply_profile() {
  local prof="${1:-}"
  if ! is_valid_profile "$prof"; then
    echo "[-] gamerun: invalid profile '$prof'. valid: $(get_choices)" >&2
    return 1
  fi

  declare -n p="$prof"
  local rbin
  rbin="$(find_ryzenadj)"

  if "$rbin" \
    "--stapm-limit=$((p[stapm] * 1000))" \
    "--fast-limit=$((p[fast] * 1000))" \
    "--slow-limit=$((p[slow] * 1000))" \
    "--vrm-current=$((p[vrm] * 1000))" \
    "--vrmmax-current=$((p[vrmmax] * 1000))" \
    "--tctl-temp=${p[temp]}" >/dev/null 2>&1; then
    echo "[+] power profile applied: ${prof^^} (${p[stapm]}W / ${p[temp]}°C)"
  else
    echo "[-] gamerun: failed applying limits via $rbin (check 'gamemode' group)" >&2
    return 1
  fi
}

# runtime state directory and pidfile
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/gamerun"
mkdir -p "$runtime_dir" 2>/dev/null || true
pid_file="${runtime_dir}/watchdog.pid"
prof_file="${runtime_dir}/profile"
lock_file="${runtime_dir}/lock"
poll_interval="${GAMERUN_POLL_INTERVAL:-5}"

# background watchdog cleanup handler
_watchdog_cleanup() {
  local my_pid="$1"
  local cur_pid
  cur_pid=$(cat "$pid_file" 2>/dev/null || true)
  if [ -n "$cur_pid" ] && [ "$cur_pid" = "$my_pid" ]; then
    rm -f "$pid_file"
    apply_profile balanced >/dev/null 2>&1 || true
  fi
}

# background watchdog worker
_watchdog_loop() {
  local target_prof="$1"
  local my_pid="$BASHPID"

  echo "$my_pid" > "$pid_file"
  trap '' HUP
  trap '_watchdog_cleanup "'"$my_pid"'"; exit 0' INT TERM EXIT

  while [ -f "$pid_file" ]; do
    local active_pid
    active_pid=$(cat "$pid_file" 2>/dev/null || true)
    [ "$active_pid" != "$my_pid" ] && break

    local cur
    cur=$(cat "$prof_file" 2>/dev/null || echo "$target_prof")
    cur="${cur//[[:space:]]/}"

    if is_valid_profile "$cur"; then
      declare -n cp="$cur"
      "$(find_ryzenadj)" \
        "--stapm-limit=$((cp[stapm] * 1000))" \
        "--fast-limit=$((cp[fast] * 1000))" \
        "--slow-limit=$((cp[slow] * 1000))" \
        "--vrm-current=$((cp[vrm] * 1000))" \
        "--vrmmax-current=$((cp[vrmmax] * 1000))" \
        "--tctl-temp=${cp[temp]}" >/dev/null 2>&1 || true
    fi
    sleep "$poll_interval"
  done
}

# start or update background watchdog daemon
start_watchdog() {
  local prof="$1"
  if ! is_valid_profile "$prof"; then
    echo "[-] usage: gamerun power set <$(get_choices)>" >&2
    return 1
  fi

  exec 9>"$lock_file"
  flock -x 9

  # cleanly terminate existing watchdog so btop/ps reflect the new target profile
  if [ -f "$pid_file" ]; then
    local old_pid
    old_pid=$(cat "$pid_file" 2>/dev/null || true)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      kill -TERM "$old_pid" 2>/dev/null || true
      pkill -P "$old_pid" 2>/dev/null || true
      for _ in {1..20}; do
        kill -0 "$old_pid" 2>/dev/null || break
        sleep 0.05
      done
      kill -KILL "$old_pid" 2>/dev/null || true
    fi
    rm -f "$pid_file"
  fi

  echo "$prof" > "$prof_file"
  apply_profile "$prof"

  # launch daemon with clean argv so btop/ps accurately show profile
  "$0" power daemon "$prof" <&- >/dev/null 2>&1 &
  local new_pid=$!
  echo "$new_pid" > "$pid_file"
  disown "$new_pid" 2>/dev/null || true

  echo "[+] started continuous power watchdog (PID: $new_pid, interval: ${poll_interval}s)"
  flock -u 9 && exec 9>&-
}

# terminate background watchdog and reset to stock balanced
stop_watchdog() {
  exec 9>"$lock_file"
  flock -x 9

  if [ -f "$pid_file" ]; then
    local pid
    pid=$(cat "$pid_file" 2>/dev/null || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null || true
      pkill -P "$pid" 2>/dev/null || true
      for _ in {1..20}; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.05
      done
      kill -KILL "$pid" 2>/dev/null || true
    fi
    rm -f "$pid_file"
  fi

  rm -f "$prof_file"
  apply_profile balanced >/dev/null 2>&1 || true
  echo "[+] power watchdog stopped. apu profile reset to BALANCED."
  flock -u 9 && exec 9>&-
}

# report watchdog status and live hardware limits
status_watchdog() {
  echo "=== Gamerun Power Status ==="
  echo "Ryzenadj binary: $(find_ryzenadj)"
  if [ -f "$pid_file" ]; then
    local pid
    pid=$(cat "$pid_file" 2>/dev/null || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      echo "Watchdog state:  ACTIVE"
      echo "Watchdog PID:    $pid"
      echo "Active profile:  $(cat "$prof_file" 2>/dev/null || echo unknown)"
      echo "Poll interval:   ${poll_interval}s"
    else
      echo "Watchdog state:  INACTIVE"
      echo "Active profile:  $(cat "$prof_file" 2>/dev/null || echo balanced)"
    fi
  else
    echo "Watchdog state:  INACTIVE"
    echo "Active profile:  $(cat "$prof_file" 2>/dev/null || echo balanced)"
  fi

  local rbin
  rbin="$(find_ryzenadj)"
  "$rbin" -i 2>/dev/null | awk -F'|' '
    /STAPM LIMIT/      { stapm_lim = $3 + 0 }
    /STAPM VALUE/      { stapm_val = $3 + 0 }
    /PPT LIMIT FAST/   { fast_lim = $3 + 0 }
    /PPT VALUE FAST/   { fast_val = $3 + 0 }
    /PPT LIMIT SLOW/   { slow_lim = $3 + 0 }
    /PPT VALUE SLOW/   { slow_val = $3 + 0 }
    /THM LIMIT CORE/   { temp_lim = $3 + 0 }
    /THM VALUE CORE/   { temp_val = $3 + 0 }
    END {
      if (stapm_lim > 0) {
        printf "Hardware Limits: STAPM: %.1fW | FAST: %.1fW | SLOW: %.1fW | TEMP: %.0f°C\n", stapm_lim, fast_lim, slow_lim, temp_lim
        printf "Live SMU Power:  FAST: %.1fW | SLOW: %.1fW | STAPM: %.1fW | TEMP: %.1f°C\n", fast_val, slow_val, stapm_val, temp_val
      }
    }
  '
}

# stress benchmark worker loop
_stress_worker() {
  local dur="${1:-10}"
  local end=$((SECONDS + dur))
  while [ $SECONDS -lt "$end" ]; do
    : $((12345 * 67890 % 10007))
  done
}

# run automated stress benchmark and sample live power
test_profile() {
  local prof="${1:-performance}"
  local duration="${2:-10}"
  if ! is_valid_profile "$prof"; then
    echo "[-] invalid profile '$prof'. valid: $(get_choices)" >&2
    return 1
  fi

  local orig_prof="balanced"
  if [ -f "$prof_file" ]; then
    orig_prof=$(cat "$prof_file" 2>/dev/null || echo "balanced")
  fi

  echo "[*] testing profile '${prof^^}' under stress for ${duration}s..."
  echo "$prof" > "$prof_file"
  apply_profile "$prof"

  local workers=()
  local num_cpus
  num_cpus=$(nproc 2>/dev/null || echo 4)

  cleanup_test() {
    for w in "${workers[@]:-}"; do
      kill -KILL "$w" 2>/dev/null || true
      wait "$w" 2>/dev/null || true
    done
    echo "$orig_prof" > "$prof_file"
    apply_profile "$orig_prof" >/dev/null 2>&1 || true
  }
  trap cleanup_test INT TERM EXIT

  for ((i = 0; i < num_cpus; i++)); do
    "$0" power worker "$duration" <&- >/dev/null 2>&1 &
    workers+=($!)
  done

  local end_time=$((SECONDS + duration))
  while [ $SECONDS -lt "$end_time" ]; do
    sleep 2
    local rbin
    rbin="$(find_ryzenadj)"
    "$rbin" -i 2>/dev/null | awk -F'|' '
      /PPT VALUE FAST/   { fast_val = $3 + 0 }
      /PPT VALUE SLOW/   { slow_val = $3 + 0 }
      /STAPM VALUE/      { stapm_val = $3 + 0 }
      /THM VALUE CORE/   { temp_val = $3 + 0 }
      END {
        if (slow_val > 0) {
          printf "  [sample] SLOW: %5.1fW | FAST: %5.1fW | STAPM: %5.1fW | TEMP: %4.1f°C\n", slow_val, fast_val, stapm_val, temp_val
        }
      }
    '
  done

  trap - INT TERM EXIT
  cleanup_test
  echo "[+] stress test completed (restored '${orig_prof}')."
}

# game-tied watchdog worker
_tied_watchdog_loop() {
  local g_pid="$1" prof="$2"
  declare -n gp="$prof"
  local rbin
  rbin="$(find_ryzenadj)"

  trap 'apply_profile balanced >/dev/null 2>&1 || true; exit 0' INT TERM HUP EXIT

  while kill -0 "$g_pid" 2>/dev/null; do
    sleep "$poll_interval"
    if kill -0 "$g_pid" 2>/dev/null; then
      "$rbin" \
        "--stapm-limit=$((gp[stapm] * 1000))" \
        "--fast-limit=$((gp[fast] * 1000))" \
        "--slow-limit=$((gp[slow] * 1000))" \
        "--vrm-current=$((gp[vrm] * 1000))" \
        "--vrmmax-current=$((gp[vrmmax] * 1000))" \
        "--tctl-temp=${gp[temp]}" >/dev/null 2>&1 || true
    fi
  done
}

# launch game under gamemoderun with tied watchdog lifecycle
run_game() {
  local mode="$1" prof="$2"
  shift 2

  case "$mode" in
    goldberg) export WINEDLLOVERRIDES="steam_api=n,steam_api64=n" ;;
    fixed)    export WINEDLLOVERRIDES="OnlineFix=n;OnlineFix64=n;SteamOverlay=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api=n;steam_api64=n;winhttp=n,b" ;;
  esac

  echo "[*] launching game under gamemode with profile '${prof^^}'"
  apply_profile "$prof"

  export MANGOHUD=1
  gamemoderun "$@" &
  local game_pid=$!

  _tied_watchdog_loop "$game_pid" "$prof" <&- >/dev/null 2>&1 &
  local watchdog_pid=$!

  cleanup() {
    [ -n "$watchdog_pid" ] && {
      kill -TERM "$watchdog_pid" 2>/dev/null || true
      pkill -P "$watchdog_pid" 2>/dev/null || true
    }
    apply_profile balanced >/dev/null 2>&1 || true
  }
  trap cleanup EXIT INT TERM HUP

  wait "$game_pid"
  exit $?
}

# help documentation
print_usage() {
  cat <<EOF
Usage: gamerun <mode> [options] <executable> [args...]

Game Execution Modes:
  base [profile] <executable> [args...]      Launch game with GameMode & APU tuning
  goldberg [profile] <executable> [args...]  Launch with Goldberg Steam emulator overrides
  fixed [profile] <executable> [args...]     Launch with OnlineFix / SteamOverlay overrides

  Game Launch Options:
    -p, --profile <profile>                  Target profile (default: performance)
    Shorthand: gamerun base max %command% -vulkan -novid

Power Management Commands:
  power set <profile>                        Set APU profile & start background watchdog
  power stop                                 Stop watchdog & restore stock balanced profile
  power reset                                Force-reset watchdog and restore stock balanced
  power status                               Inspect active watchdog, limits, and live SMU metrics
  power once <profile>                       Apply profile once without starting watchdog
  power test [profile] [seconds]             Run automated stress benchmark and sample live power
  power list                                 Display formatted table of all power profiles

$(print_table)
EOF
}

if [ $# -eq 0 ]; then
  print_usage
  exit 1
fi

cmd="$1"
shift

case "$cmd" in
power)
  if [ $# -eq 0 ]; then
    echo "[-] missing action. valid: set, stop, status, reset, once, test, list, or profile (<$(get_choices)>)" >&2
    exit 1
  fi
  action="$1"
  shift

  case "$action" in
    set)
      if [ $# -eq 0 ]; then
        echo "[-] usage: gamerun power set <$(get_choices)>" >&2
        exit 1
      fi
      start_watchdog "$1"
      ;;
    stop|reset)
      stop_watchdog
      ;;
    status)
      status_watchdog
      ;;
    once)
      if [ $# -eq 0 ]; then
        echo "[-] usage: gamerun power once <$(get_choices)>" >&2
        exit 1
      fi
      apply_profile "$1"
      ;;
    test)
      test_profile "${1:-performance}" "${2:-10}"
      ;;
    daemon)
      if [ $# -eq 0 ]; then
        exit 1
      fi
      _watchdog_loop "$1"
      ;;
    worker)
      _stress_worker "${1:-10}"
      exit 0
      ;;
    list)
      print_table
      ;;
    *)
      if is_valid_profile "$action"; then
        start_watchdog "$action"
      else
        echo "[-] unknown power action or profile '$action'. valid: <$(get_choices)>" >&2
        exit 1
      fi
      ;;
  esac
  ;;

base|goldberg|fixed)
  prof="performance"

  if [ $# -gt 0 ]; then
    if [ "$1" = "-p" ] || [ "$1" = "--profile" ]; then
      shift
      if [ $# -eq 0 ] || ! is_valid_profile "${1:-}"; then
        echo "[-] invalid profile for -p. expected: <$(get_choices)>" >&2
        exit 1
      fi
      prof="$1"
      shift
    elif is_valid_profile "$1"; then
      prof="$1"
      shift
    fi
  fi

  if [ $# -eq 0 ]; then
    echo "[-] missing executable for mode '$cmd'. usage: gamerun $cmd [profile] <executable> [args...]" >&2
    exit 1
  fi

  run_game "$cmd" "$prof" "$@"
  ;;

--help|-h|help)
  print_usage
  ;;

*)
  echo "[-] unknown command '$cmd'." >&2
  print_usage
  exit 1
  ;;
esac
