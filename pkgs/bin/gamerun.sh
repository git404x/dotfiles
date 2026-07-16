#!/usr/bin/env bash

IS_WINDOWS=false
if [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
  IS_WINDOWS=true
fi

# catch empty execution before evaluating arguments
if [ $# -eq 0 ]; then
  echo "[-] Usage: gamerun [install | power | base | goldberg | fixed] <executable>"
  exit 1
fi

# INSTALLER
if [ "${1:-}" = "install" ]; then
  echo "gamerun installer"

  if [ "$IS_WINDOWS" = true ]; then
    mkdir -p ~/bin
    cp "$0" ~/bin/gamerun
    echo "[+] Installed to ~/bin/gamerun"
    echo "    (Ensure ~/bin is in your Windows environment PATH variables)"
    exit 0
  else
    mkdir -p ~/.local/bin
    cp "$0" ~/.local/bin/gamerun
    chmod +x ~/.local/bin/gamerun
    echo "[+] Installed to ~/.local/bin/gamerun"
    exit 0
  fi
fi

# POWER MANAGEMENT
if [ "${1:-}" = "power" ]; then
  if [ -z "${2:-}" ]; then
    echo "Usage: gamerun power [default | cool | balanced | max | hyper]"
    exit 1
  fi

  PROFILE=$2

  case "$PROFILE" in
  default)
    ryzenadj --stapm-limit=15000 --fast-limit=15000 --slow-limit=15000 --tctl-temp=75
    echo "[+] Power profile reset to DEFAULT (15W / 75C)"
    ;;
  cool)
    ryzenadj --stapm-limit=10000 --fast-limit=12000 --slow-limit=10000 --tctl-temp=70
    echo "[+] Power profile set to COOL (10W Limit)"
    ;;
  balanced)
    ryzenadj --stapm-limit=15000 --fast-limit=18000 --slow-limit=15000 --tctl-temp=80
    echo "[+] Power profile set to BALANCED (15W Limit)"
    ;;
  max)
    ryzenadj --stapm-limit=20000 --fast-limit=20000 --slow-limit=20000 --tctl-temp=85
    echo "[+] Power profile set to MAX (20W Limit / 85C)"
    ;;
  hyper)
    ryzenadj --stapm-limit=25000 --fast-limit=25000 --slow-limit=25000 --tctl-temp=95
    echo "[+] Power profile set to HYPER (25W Limit / 95C)"
    ;;
  *)
    echo "[-] Invalid power mode: $PROFILE"
    exit 1
    ;;
  esac
  exit 0
fi

# GAME WRAPPER
MODE=${1:-}
shift

case "$MODE" in
base)
  # no overrides
  ;;

goldberg)
  export WINEDLLOVERRIDES="steam_api=n,steam_api64=n"
  ;;

fixed)
  export WINEDLLOVERRIDES="OnlineFix=n;OnlineFix64=n;SteamOverlay=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api=n;steam_api64=n;winhttp=n,b"
  ;;

*)
  echo "[-] Invalid mode: $MODE. Use base, goldberg, fixed, or power."
  exit 1
  ;;
esac

export MANGOHUD=1
exec gamemoderun "$@"
