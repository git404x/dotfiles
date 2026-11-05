#!/usr/bin/env bash
# power.sh - APU power governor, ryzenadj control, and continuous watchdog daemon

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/gamerun"
mkdir -p "$runtime_dir" 2>/dev/null || true
pid_file="${runtime_dir}/watchdog.pid"
prof_file="${runtime_dir}/profile"
target_prof_file="${runtime_dir}/target_profile"
lock_file="${runtime_dir}/lock"
poll_interval="$(get_poll_interval)"

find_ryzenadj() {
  if [ -x "/run/wrappers/bin/ryzenadj" ]; then
    echo "/run/wrappers/bin/ryzenadj"
  else
    command -v ryzenadj 2>/dev/null || echo "ryzenadj"
  fi
}

can_run_ryzenadj() {
  local rbin
  rbin="$(find_ryzenadj)"
  [ -n "$rbin" ] && [ -x "$rbin" ] && "$rbin" -i >/dev/null 2>&1
}

apply_profile() {
  local prof="${1:-}"
  if ! is_valid_profile "$prof"; then
    echo "[-] gamerun: invalid profile '$prof'. valid: $(get_choices)" >&2
    return 1
  fi

  if ! can_run_ryzenadj; then
    echo "[*] gamerun: direct SMU hardware access restricted (sandbox / NO_NEW_PRIVS detected)" >&2
    echo "[*] hardware governor delegated to host GameMode service" >&2
    return 0
  fi

  local rbin stapm fast slow vrm vrmmax temp
  rbin="$(find_ryzenadj)"
  stapm=$(get_profile_field "$prof" "stapm")
  fast=$(get_profile_field "$prof" "fast")
  slow=$(get_profile_field "$prof" "slow")
  vrm=$(get_profile_field "$prof" "vrm")
  vrmmax=$(get_profile_field "$prof" "vrmmax")
  temp=$(get_profile_field "$prof" "temp")

  if "$rbin" \
    "--stapm-limit=$((stapm * 1000))" \
    "--fast-limit=$((fast * 1000))" \
    "--slow-limit=$((slow * 1000))" \
    "--vrm-current=$((vrm * 1000))" \
    "--vrmmax-current=$((vrmmax * 1000))" \
    "--tctl-temp=${temp}" >/dev/null 2>&1; then
    echo "[+] power profile applied: ${prof^^} (${stapm}W / ${temp}°C)"
    return 0
  else
    echo "[-] gamerun: failed applying limits via $rbin (check 'gamemode' group)" >&2
    return 1
  fi
}

_watchdog_cleanup() {
  local my_pid="$1"
  local cur_pid
  cur_pid=$(cat "$pid_file" 2>/dev/null || true)
  if [ -n "$cur_pid" ] && [ "$cur_pid" = "$my_pid" ]; then
    rm -f "$pid_file"
    apply_profile "$(get_idle_profile)" >/dev/null 2>&1 || true
  fi
}

_watchdog_loop() {
  local target_prof="$1"
  local my_pid="$BASHPID"

  trap '' HUP
  trap '_watchdog_cleanup "'"$my_pid"'"; exit 0' INT TERM EXIT

  echo "$my_pid" > "$pid_file"

  while [ -f "$pid_file" ]; do
    local active_pid
    active_pid=$(cat "$pid_file" 2>/dev/null || true)
    [ -n "$active_pid" ] && [ "$active_pid" != "$my_pid" ] && break

    if ! can_run_ryzenadj; then
      break
    fi

    local cur
    cur=$(cat "$prof_file" 2>/dev/null || echo "$target_prof")
    cur="${cur//[[:space:]]/}"

    if is_valid_profile "$cur"; then
      local rbin stapm fast slow vrm vrmmax temp
      rbin="$(find_ryzenadj)"
      stapm=$(get_profile_field "$cur" "stapm")
      fast=$(get_profile_field "$cur" "fast")
      slow=$(get_profile_field "$cur" "slow")
      vrm=$(get_profile_field "$cur" "vrm")
      vrmmax=$(get_profile_field "$cur" "vrmmax")
      temp=$(get_profile_field "$cur" "temp")

      "$rbin" \
        "--stapm-limit=$((stapm * 1000))" \
        "--fast-limit=$((fast * 1000))" \
        "--slow-limit=$((slow * 1000))" \
        "--vrm-current=$((vrm * 1000))" \
        "--vrmmax-current=$((vrmmax * 1000))" \
        "--tctl-temp=${temp}" >/dev/null 2>&1 || true
    fi
    sleep "$poll_interval"
  done
}

start_watchdog() {
  local prof="$1"
  if ! is_valid_profile "$prof"; then
    echo "[-] usage: gamerun power set <$(get_choices)>" >&2
    return 1
  fi

  exec 9>"$lock_file"
  flock -x 9

  if [ -f "$pid_file" ]; then
    local cur_pid cur_prof
    cur_pid=$(cat "$pid_file" 2>/dev/null || true)
    cur_prof=$(cat "$prof_file" 2>/dev/null || true)
    if [ -n "$cur_pid" ] && kill -0 "$cur_pid" 2>/dev/null && [ "$cur_prof" = "$prof" ]; then
      apply_profile "$prof" >/dev/null 2>&1 || true
      flock -u 9 && exec 9>&-
      return 0
    fi
  fi

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

  local self_bin="${GAMERUN_BIN:-$(readlink -f "$0")}"
  if command -v setsid >/dev/null 2>&1; then
    setsid "$self_bin" power daemon "$prof" <&- >/dev/null 2>&1 &
  else
    ( trap '' HUP; "$self_bin" power daemon "$prof" <&- >/dev/null 2>&1 & )
  fi

  local new_pid=""
  for _ in {1..25}; do
    if [ -f "$pid_file" ]; then
      new_pid=$(cat "$pid_file" 2>/dev/null || true)
      if [ -n "$new_pid" ] && kill -0 "$new_pid" 2>/dev/null; then
        break
      fi
    fi
    sleep 0.02
  done

  if [ -n "$new_pid" ] && kill -0 "$new_pid" 2>/dev/null; then
    echo "[+] started continuous power watchdog (PID: $new_pid, interval: ${poll_interval}s)"
  else
    echo "[-] failed to verify watchdog startup" >&2
  fi
  flock -u 9 && exec 9>&-
}

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
  local idle_prof
  idle_prof="$(get_idle_profile)"
  apply_profile "$idle_prof" >/dev/null 2>&1 || true
  echo "[+] power watchdog stopped. apu profile reset to ${idle_prof^^}."
  flock -u 9 && exec 9>&-
}

status_watchdog() {
  echo "=== Gamerun Power Status ==="
  echo "Ryzenadj binary: $(find_ryzenadj)"
  echo "SMU Access:      $(can_run_ryzenadj && echo "Direct (Privileged)" || echo "Restricted (Sandbox / User)")"
  if [ -f "$pid_file" ]; then
    local pid
    pid=$(cat "$pid_file" 2>/dev/null || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      echo "Watchdog state:  ACTIVE"
      echo "Watchdog PID:    $pid"
      echo "Active profile:  $(cat "$prof_file" 2>/dev/null || get_default_profile)"
      echo "Poll interval:   ${poll_interval}s"
    else
      echo "Watchdog state:  INACTIVE"
      echo "Active profile:  $(cat "$prof_file" 2>/dev/null || get_idle_profile)"
    fi
  else
    echo "Watchdog state:  INACTIVE"
    echo "Active profile:  $(cat "$prof_file" 2>/dev/null || get_idle_profile)"
  fi

  local rbin
  rbin="$(find_ryzenadj)"
  if can_run_ryzenadj; then
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
  fi
}
