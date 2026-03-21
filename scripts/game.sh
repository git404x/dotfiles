#!/usr/bin/env bash

IS_WINDOWS=false
if [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
  IS_WINDOWS=true
fi

# INSTALLER
if [ "$1" = "install" ]; then
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

MODE=$1
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
  echo "[-] Invalid mode: $MODE"
  exit 1
  ;;
esac

export MANGOHUD=1
exec gamemoderun "$@"
