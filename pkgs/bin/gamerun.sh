#!/usr/bin/env bash
set -euo pipefail

# gamerun - game launcher wrapper with continuous power management for ryzen mobile

if [ $# -eq 0 ]; then
  cat <<'EOF'
Usage: gamerun [power | base | goldberg | fixed] <executable> [args...]

Commands:
  power <profile>     Apply hardware power profile (cool | balanced | performance)
  base <command>      Run command with MangoHud and GameMode
  goldberg <command>  Run command with Goldberg steam_api overrides
  fixed <command>     Run command with OnlineFix DLL overrides
EOF
  exit 1
fi

if [ -x "/run/wrappers/bin/ryzenadj" ]; then
  RYZENADJ="/run/wrappers/bin/ryzenadj"
else
  RYZENADJ="$(command -v ryzenadj 2>/dev/null || echo "ryzenadj")"
fi

apply_power_profile() {
  local profile="$1"
  if [ ! -x "$RYZENADJ" ]; then
    echo "[-] ryzenadj binary not found or not executable" >&2
    return 1
  fi

  case "$profile" in
    cool|battery)
      "$RYZENADJ" --stapm-limit=12000 --fast-limit=15000 --slow-limit=12000 --vrm-current=30000 --vrmmax-current=35000 --tctl-temp=75 >/dev/null 2>&1 || true
      echo "[+] Power profile: COOL (12W sustained / 75°C max)"
      ;;
    balanced|default)
      "$RYZENADJ" --stapm-limit=15000 --fast-limit=18000 --slow-limit=15000 --vrm-current=35000 --vrmmax-current=40000 --tctl-temp=80 >/dev/null 2>&1 || true
      echo "[+] Power profile: BALANCED (15W sustained / 80°C max)"
      ;;
    performance|max|turbo)
      "$RYZENADJ" --stapm-limit=18000 --fast-limit=22000 --slow-limit=18000 --stapm-time=300 --vrm-current=35000 --vrmmax-current=45000 --tctl-temp=88 >/dev/null 2>&1 || true
      echo "[+] Power profile: PERFORMANCE (18W sustained / 22W burst / 88°C max)"
      ;;
    *)
      echo "[-] Invalid power profile: '$profile'. Available: cool, balanced, performance" >&2
      return 1
      ;;
  esac
}

# Standalone power command
if [ "${1:-}" = "power" ]; then
  shift
  if [ $# -eq 0 ]; then
    echo "Usage: gamerun power [cool | balanced | performance]" >&2
    exit 1
  fi
  apply_power_profile "$1"
  exit 0
fi

# Game execution mode
MODE="$1"
shift

case "$MODE" in
  base)
    # Standard launcher without DLL overrides
    ;;
  goldberg)
    export WINEDLLOVERRIDES="steam_api=n,steam_api64=n"
    ;;
  fixed)
    export WINEDLLOVERRIDES="OnlineFix=n;OnlineFix64=n;SteamOverlay=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api=n;steam_api64=n;winhttp=n,b"
    ;;
  *)
    echo "[-] Invalid mode '$MODE'. Use base, goldberg, fixed, or power." >&2
    exit 1
    ;;
esac

export MANGOHUD=1

# Apply performance profile and launch periodic watchdog to prevent Asus EC from resetting limits to 12W
apply_power_profile performance || true

WATCHDOG_PID=""
cleanup() {
  if [ -n "$WATCHDOG_PID" ]; then
    kill -TERM "$WATCHDOG_PID" 2>/dev/null || true
  fi
  apply_power_profile balanced >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# Run game process
if command -v gamemoderun >/dev/null 2>&1; then
  gamemoderun "$@" &
else
  "$@" &
fi
GAME_PID=$!

# Watchdog loop running every 6 seconds to reinforce 18W power against EC override
(
  while kill -0 "$GAME_PID" 2>/dev/null; do
    sleep 6
    apply_power_profile performance >/dev/null 2>&1 || true
  done
) &
WATCHDOG_PID=$!

wait "$GAME_PID"
