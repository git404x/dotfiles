#!/usr/bin/env bash

IS_WINDOWS=false
if [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
  IS_WINDOWS=true
fi

# INSTALLER
if [ "$1" = "install" ]; then
  echo "Game Wrapper Installer"
  if [ -f "/etc/NIXOS" ] || grep -q "NixOS" /etc/os-release 2>/dev/null; then
    echo "[-] Error: You are on NixOS!"
    echo "    Do not install this imperatively. Add this script via pkgs.writeShellScriptBin."
    exit 1
  fi

  if [ "$IS_WINDOWS" = true ]; then
    mkdir -p ~/bin
    cp "$0" ~/bin/play-game
    echo "[+] Installed to ~/bin/play-game"
    echo "    (Ensure ~/bin is in your Windows environment PATH variables)"
    exit 0
  else
    mkdir -p ~/.local/bin
    cp "$0" ~/.local/bin/play-game
    chmod +x ~/.local/bin/play-game
    echo "[+] Installed to ~/.local/bin/play-game"
    exit 0
  fi
fi

MODE=$1
case "$MODE" in
  setup)
    echo "Goldberg Configure"
    INI_FILE="goldberg.ini"
    if [ ! -f "$INI_FILE" ]; then
      echo "[GoldbergSetup]" > "$INI_FILE"

      read -p "Enter Steam AppID [Default: 480]: " input_appid
      echo "AppId=${input_appid:-480}" >> "$INI_FILE"

      read -p "Enter Username [Default: NULL]: " input_uname
      echo "UserName=${input_uname:-NULL}" >> "$INI_FILE"

      echo "[+] Generated $INI_FILE."
    fi

    # Parse the INI file
    APPID=$(grep -i '^AppId=' "$INI_FILE" | cut -d'=' -f2 | tr -d '\r')
    USERNAME=$(grep -i '^UserName=' "$INI_FILE" | cut -d'=' -f2 | tr -d '\r')

    # DLL locations
    echo "[+] Scanning for steam_api.dll locations..."
    DLL_DIRS=$(find . -type f \( -iname "steam_api.dll" -o -iname "steam_api64.dll" \) -exec dirname {} \; | sort -u 2>/dev/null)

    if [ -z "$DLL_DIRS" ]; then
      echo "[-] No steam_api.dll found. Applying to current directory as fallback."
      DLL_DIRS="."
    fi

    # Apply the architecture
    for DIR in $DLL_DIRS; do
      echo " -> Configuring: $DIR"

        # setup AppID
        if [ -f "$DIR/steam_appid.txt" ]; then
          if [ "$IS_WINDOWS" = true ]; then
            attrib -R "$DIR/steam_appid.txt" >/dev/null 2>&1
          else
            chmod 644 "$DIR/steam_appid.txt" >/dev/null 2>&1
          fi
        fi

        echo "$APPID" > "$DIR/steam_appid.txt"
        if [ "$IS_WINDOWS" = true ]; then
          attrib +R "$DIR/steam_appid.txt" >/dev/null 2>&1
        else
          chmod 444 "$DIR/steam_appid.txt" >/dev/null 2>&1
        fi

        # config
        touch "$DIR/local_save.txt"
        mkdir -p "$DIR/settings"
        echo "$USERNAME" > "$DIR/settings/account_name.txt"

        if [ -f "avatar.png" ]; then
          cp "avatar.png" "$DIR/settings/avatar.png"
          echo "    [+] Avatar applied!"
        fi

        # tailscale LAN Broadcast
        TS_IP=$(tailscale ip -4 2>/dev/null)
        if [ -n "$TS_IP" ]; then
          SUBNET=$(echo "$TS_IP" | awk -F. '{print $1"."$2"."$3".255"}')
          echo "$SUBNET" > "$DIR/settings/custom_broadcasts.txt"
          echo "    [+] Tailscale Subnet Broadcast set to $SUBNET"
        fi
      done

      echo "Setup Complete!"
      exit 0
      ;;

    goldberg)
      shift
      export WINEDLLOVERRIDES="steam_api=n,steam_api64=n"
      exec gamemoderun "$@"
      ;;

    fixed)
      shift
      export WINEDLLOVERRIDES="OnlineFix=n;OnlineFix64=n;SteamOverlay=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api=n;steam_api64=n;winhttp=n,b"
      exec gamemoderun "$@"
      ;;

    base)
      shift
      exec gamemoderun "$@"
      ;;

    *)
      echo "[-] Invalid mode: $MODE"
      exit 1
      ;;
  esac
