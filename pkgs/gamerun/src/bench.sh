#!/usr/bin/env bash
# bench.sh - Automated stress testing and live hardware power sampling

_stress_worker() {
  local dur="${1:-10}"
  local end=$((SECONDS + dur))
  while [ $SECONDS -lt "$end" ]; do
    : $((12345 * 67890 % 10007))
  done
}

test_profile() {
  local prof="${1:-$(get_default_profile)}"
  local duration="${2:-10}"
  if ! is_valid_profile "$prof"; then
    echo "[-] invalid profile '$prof'. valid: $(get_choices)" >&2
    return 1
  fi

  local orig_prof="$(get_idle_profile)"
  if [ -f "$prof_file" ]; then
    orig_prof=$(cat "$prof_file" 2>/dev/null || get_idle_profile)
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

  local self_bin="${GAMERUN_BIN:-$(readlink -f "$0")}"
  for ((i = 0; i < num_cpus; i++)); do
    "$self_bin" power worker "$duration" <&- >/dev/null 2>&1 &
    workers+=($!)
  done

  local end_time=$((SECONDS + duration))
  while [ $SECONDS -lt "$end_time" ]; do
    sleep 2
    local rbin
    rbin="$(find_ryzenadj)"
    if can_run_ryzenadj; then
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
    fi
  done

  trap - INT TERM EXIT
  cleanup_test
  echo "[+] stress test completed (restored '${orig_prof}')."
}
