#!/usr/bin/env bash
set -e

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'
BOLD='\033[1m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}${BOLD}[✖ Error]${NC} Execute with sudo!"
  exit 1
fi

if [ -n "$SUDO_USER" ]; then
  S_USER="$SUDO_USER"
  U_HOME=$(eval echo ~"$SUDO_USER")
else
  S_USER="$USER"
  U_HOME=$HOME
fi
U_GRP=$(id -gn "$S_USER")

B_BASE="${XDG_DATA_HOME:-$U_HOME/.local/share}/minecraft"
B_DEST="$B_BASE/backups"
DATE=$(date +'%Y-%m-%d_%H-%M-%S')

mkdir -p "$B_DEST"
chown -R "$S_USER":"$U_GRP" "$B_BASE" 2>/dev/null || true

TARGET_NAMES=()
TARGET_PATHS=()

P_CLIENT="$U_HOME/.minecraft"
if [ -d "$P_CLIENT" ]; then
  TARGET_NAMES+=(".minecraft (Saves Only)")
  TARGET_PATHS+=("$P_CLIENT|SAVES")

  TARGET_NAMES+=(".minecraft (Configs & Launchers)")
  TARGET_PATHS+=("$P_CLIENT|CONFIGS")
fi

P_HM_SERVER="$U_HOME/minecraft-server"
if [ -d "$P_HM_SERVER" ]; then
  TARGET_NAMES+=("minecraft-server (user)")
  TARGET_PATHS+=("$P_HM_SERVER|SERVER")
fi

P_SERVER_BASE="/var/lib/minecraft"
if [ -d "$P_SERVER_BASE" ]; then
  while IFS= read -r dir; do
    if [ -n "$dir" ]; then
      server_name=$(basename "$dir")
      if [[ "$server_name" == .* ]]; then continue; fi
      TARGET_NAMES+=("$server_name (Server)")
      TARGET_PATHS+=("$dir|SERVER")
    fi
  done < <(find "$P_SERVER_BASE" -mindepth 1 -maxdepth 1 -type d)
fi

if [ ${#TARGET_NAMES[@]} -eq 0 ]; then
  echo -e "${RED}${BOLD}[✖ Error]${NC} No Minecraft directories found!"
  exit 1
fi

echo -e "${CYAN}${BOLD}[ Backup Targets ]${NC}"
for i in "${!TARGET_NAMES[@]}"; do
  echo -e "  ${YELLOW}$((i + 1))${NC}) ${TARGET_NAMES[$i]}"
done
echo -e "  ${YELLOW}$((${#TARGET_NAMES[@]} + 1))${NC}) All of the above"

echo -n -e "\n${BLUE}${BOLD}[➜] Select option:${NC} "
read -r C

SELECTED_NAMES=()
SELECTED_PATHS=()

if [[ "$C" =~ ^[0-9]+$ ]]; then
  if [ "$C" -eq $((${#TARGET_NAMES[@]} + 1)) ]; then
    SELECTED_NAMES=("${TARGET_NAMES[@]}")
    SELECTED_PATHS=("${TARGET_PATHS[@]}")
  elif [ "$C" -ge 1 ] && [ "$C" -le "${#TARGET_NAMES[@]}" ]; then
    idx=$((C - 1))
    SELECTED_NAMES=("${TARGET_NAMES[$idx]}")
    SELECTED_PATHS=("${TARGET_PATHS[$idx]}")
  else
    echo -e "${RED}[✖ Error]${NC} Invalid selection!"
    exit 1
  fi
else
  echo -e "${RED}[✖ Error]${NC} Invalid selection!"
  exit 1
fi

pacman_anim_with_pct() {
  local p=$1
  local m=$2
  local prog_file=$3
  local f=("ᗧ · · · ·" " ᗧ · · · " "  ᗧ · ·  " "   ᗧ ·   " "    ᗧ    " "· · · · ᗤ" "· · · ᗤ  " "· · ᗤ    " "· ᗤ      ")

  tput civis
  while kill -0 "$p" 2>/dev/null; do
    for i in "${f[@]}"; do
      local cols
      cols=$(tput cols 2>/dev/null || echo 80)
      local pct=""

      if [ -f "$prog_file" ]; then
        local val
        val=$(tail -n 1 "$prog_file" 2>/dev/null | tr -dc '0-9')
        if [ -n "$val" ]; then pct="[${val}%] "; fi
      fi

      local max_len=$((cols - 18 - ${#pct}))
      local trunc_m="${m}"
      if [ ${#m} -gt $max_len ] && [ $max_len -gt 3 ]; then
        trunc_m="${m:0:$((max_len - 3))}..."
      fi

      printf "\r\033[2K${YELLOW}${BOLD}[ %s ]${NC} ${GREEN}%s${NC}${CYAN}%s${NC}" "$i" "$pct" "$trunc_m"
      sleep 0.15
      kill -0 "$p" 2>/dev/null || break
    done
  done
  printf "\r\033[2K"
  tput cnorm
}

echo ""

for idx in "${!SELECTED_NAMES[@]}"; do
  NAME="${SELECTED_NAMES[$idx]}"
  RAW_PATH="${SELECTED_PATHS[$idx]}"

  SRC_DIR="${RAW_PATH%|*}"
  MODE="${RAW_PATH##*|}"

  SAFE_NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')
  A_N="${SAFE_NAME}_${DATE}.tar.zst"

  EXCLUDES=()
  INCLUDES=()

  cd "$SRC_DIR" || continue

  if [ "$MODE" == "SAVES" ]; then
    INCLUDES=("saves")

  elif [ "$MODE" == "CONFIGS" ]; then
    EXCLUDES=("--exclude=sessions" "--exclude=crash_assistant" "--exclude=*.xwmc" "--exclude=*.outdated")

    shopt -s nullglob
    for item in config options*.txt servers.dat *profiles*.json usercache.json; do
      INCLUDES+=("$item")
    done
    shopt -u nullglob

  elif [ "$MODE" == "SERVER" ]; then
    INCLUDES=(".")
    EXCLUDES=("--exclude=cache" "--exclude=logs" "--exclude=*.jar" "--exclude=plugins/spark/tmp")
  fi

  if [ ${#INCLUDES[@]} -eq 0 ]; then
    echo -e "${YELLOW}[⚠ Warning]${NC} Target data missing in [$SRC_DIR]. Skipping..."
    continue
  fi

  TOTAL_BYTES=$(du -sb -c "${INCLUDES[@]}" 2>/dev/null | tail -n 1 | awk '{print $1}')
  PROG_FILE="/tmp/mc-bak-prog-$$.txt"
  touch "$PROG_FILE"

  tar -cf - "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>/dev/null | pv -n -s "$TOTAL_BYTES" 2>"$PROG_FILE" | zstd -T0 -10 >"$B_DEST/$A_N" &
  PID=$!

  pacman_anim_with_pct $PID "compressing $NAME..." "$PROG_FILE"
  wait $PID

  chown "$S_USER":"$U_GRP" "$B_DEST/$A_N" 2>/dev/null || true
  rm -f "$PROG_FILE"
  echo -e "${GREEN}${BOLD}[✔ Success]${NC}: $B_DEST/$A_N"
done

echo -e "\n${CYAN}${BOLD}[ Backup finalized. ]${NC}"
