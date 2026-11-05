#!/usr/bin/env bash
# main.sh - CLI dispatcher and entry point for gamerun

set -euo pipefail

# Resolve library directory
lib_dir="${GAMERUN_LIB_DIR:-$(dirname "$0")}"
[ -f "$lib_dir/config.sh" ] || lib_dir="$(dirname "$0")/../lib/gamerun"
[ -f "$lib_dir/config.sh" ] || lib_dir="$(dirname "$0")"

# Source modular components
# shellcheck source=/dev/null
source "$lib_dir/config.sh"
# shellcheck source=/dev/null
source "$lib_dir/power.sh"
# shellcheck source=/dev/null
source "$lib_dir/launch.sh"
# shellcheck source=/dev/null
source "$lib_dir/bench.sh"

print_usage() {
  local def_prof idle_prof
  def_prof="$(get_default_profile)"
  idle_prof="$(get_idle_profile)"

  cat <<EOF
Usage: gamerun [mode] [profile] <executable> [args...]
       gamerun power <action> [args...]

Game Execution Modes:
  base, default                              Standard GameMode launch with APU tuning (default)
  goldberg                                   Launch with Goldberg Steam emulator overrides
  online-fix, fixed                          Launch with OnlineFix / SteamOverlay overrides

Game Launch Options:
  -p, --profile <profile>                    Target APU profile (default: $def_prof)
  --no-hud                                   Disable MangoHud overlay
  --no-gamemode                              Bypass gamemoderun execution wrapper

Power Management Commands:
  power start [profile]                      Start watchdog using target or default profile
  power stop                                 Stop watchdog & restore stock $idle_prof profile
  power set <profile>                        Set APU profile & start background watchdog
  power reset                                Force-reset watchdog and restore stock $idle_prof
  power status                               Inspect active watchdog, limits, and live SMU metrics
  power once <profile>                       Apply profile once without starting watchdog
  power test [profile] [seconds]             Run automated stress benchmark and sample live power
  power list                                 Display formatted table of all power profiles

$(print_table)
EOF
}

handle_power_command() {
  if [ $# -eq 0 ]; then
    echo "[-] missing action. valid: start, stop, set, status, reset, once, test, list, or profile (<$(get_choices)>)" >&2
    exit 1
  fi
  local action="$1"
  shift

  case "$action" in
    start)
      local target_prof
      target_prof="$(get_default_profile)"
      if [ -f "$target_prof_file" ]; then
        local p
        p=$(cat "$target_prof_file" 2>/dev/null || echo "")
        p="${p//[[:space:]]/}"
        is_valid_profile "$p" && target_prof="$p"
      fi
      if [ $# -gt 0 ] && is_valid_profile "$1"; then
        target_prof="$1"
      fi
      start_watchdog "$target_prof"
      ;;
    stop|end|reset)
      stop_watchdog
      rm -f "$target_prof_file" 2>/dev/null || true
      ;;
    set)
      if [ $# -eq 0 ]; then
        echo "[-] usage: gamerun power set <$(get_choices)>" >&2
        exit 1
      fi
      start_watchdog "$1"
      ;;
    once)
      if [ $# -eq 0 ]; then
        echo "[-] usage: gamerun power once <$(get_choices)>" >&2
        exit 1
      fi
      apply_profile "$1"
      ;;
    status)
      status_watchdog
      ;;
    test)
      test_profile "${1:-$(get_default_profile)}" "${2:-10}"
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
}

if [ $# -eq 0 ]; then
  print_usage
  exit 1
fi

case "$1" in
  -h|--help|help)
    print_usage
    exit 0
    ;;
  -v|--version|version)
    echo "gamerun version 1.2.0"
    exit 0
    ;;
  power)
    shift
    handle_power_command "$@"
    exit 0
    ;;
esac

# Game launch execution mode resolution
mode="base"
case "$1" in
  base|default)
    mode="base"
    shift
    ;;
  goldberg)
    mode="goldberg"
    shift
    ;;
  online-fix|fixed)
    mode="online-fix"
    shift
    ;;
  *)
    # If not an explicit mode name, default to base mode without consuming $1
    mode="base"
    ;;
esac

# Parse profile and options
prof="$(get_default_profile)"
use_hud=1
use_gamemode=1

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--profile)
      shift
      if [ $# -eq 0 ] || ! is_valid_profile "${1:-}"; then
        echo "[-] invalid profile for -p. expected: <$(get_choices)>" >&2
        exit 1
      fi
      prof="$1"
      shift
      ;;
    --no-hud)
      use_hud=0
      shift
      ;;
    --no-gamemode)
      use_gamemode=0
      shift
      ;;
    *)
      if is_valid_profile "$1"; then
        prof="$1"
        shift
      else
        break
      fi
      ;;
  esac
done

if [ $# -eq 0 ]; then
  echo "[-] missing executable for mode '$mode'. usage: gamerun [mode] [profile] <executable> [args...]" >&2
  exit 1
fi

export GAMERUN_MANGOHUD="$use_hud"
export GAMERUN_NO_GAMEMODE="$((1 - use_gamemode))"

run_game "$mode" "$prof" "$@"
