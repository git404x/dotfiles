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
  U_HOME=$(eval echo ~"$SUDO_USER")
  B_DEST="${2:-${XDG_DATA_HOME:-$U_HOME/.local/share}/minecraft_backups}"
  U_GRP=$(id -gn "$SUDO_USER")
else
  B_DEST="${2:-${XDG_DATA_HOME:-$HOME/.local/share}/minecraft_backups}"
  U_GRP=$(id -gn)
fi

B_DIR="${1:-/var/lib/minecraft}"
DATE=$(date +'%Y-%m-%d_%H-%M-%S')

mkdir -p "$B_DEST"

if [ ! -d "$B_DIR" ]; then
  echo -e "${RED}${BOLD}[✖ Error]${NC} Directory [${B_DIR}] is missing!"
  exit 1
fi

mapfile -t W < <(find "$B_DIR" -mindepth 1 -maxdepth 1 -type d -not -name ".*" -printf "%f\n")

if [ ${#W[@]} -eq 0 ]; then
  echo -e "${YELLOW}${BOLD}[✦ Info]${NC} No worlds found in [${B_DIR}]"
  exit 0
fi

clear
echo -e "${CYAN}${BOLD}==========================================${NC}"
echo -e "${GREEN}${BOLD} [✦] Detected Worlds in [${B_DIR}] ${NC}"
echo -e "${CYAN}${BOLD}==========================================${NC}"

for i in "${!W[@]}"; do
  echo -e "  ${YELLOW}${BOLD}[$((i + 1))]${NC} ${W[$i]}"
done

echo -e "  ${YELLOW}${BOLD}[A]${NC} Backup ALL Worlds"
echo -e "  ${RED}${BOLD}[Q]${NC} Quit"
echo -e "${CYAN}${BOLD}==========================================${NC}"
echo -en "${BLUE}${BOLD}[➜] Select option:${NC} "
read -r C

T=()
if [[ "$C" =~ ^[Aa]$ ]]; then
  T=("${W[@]}")
elif [[ "$C" =~ ^[Qq]$ ]]; then
  exit 0
elif [[ "$C" =~ ^[0-9]+$ ]] && [ "$C" -ge 1 ] && [ "$C" -le "${#W[@]}" ]; then
  T=("${W[$((C - 1))]}")
else
  echo -e "${RED}${BOLD}[✖ Error]${NC} Invalid selection!"
  exit 1
fi

pacman_anim() {
  local p=$1
  local m=$2
  local f=("ᗧ · · · ·" " ᗧ · · ·" "  ᗧ · ·" "   ᗧ ·" "    ᗧ" "· · · · ᗤ" "· · · ᗤ  " "· · ᗤ    " "· ᗤ      ")

  tput civis
  while kill -0 "$p" 2>/dev/null; do
    for i in "${f[@]}"; do
      printf "\r${YELLOW}${BOLD}[ %s ]${NC} ${CYAN}%s${NC}" "$i" "$m"
      sleep 0.15
      kill -0 "$p" 2>/dev/null || break
    done
  done
  printf "\r\033[2K"
  tput cnorm
}

echo ""
for w in "${T[@]}"; do
  A_N="${w}_backup_${DATE}.tar.zst"
  A_P="${B_DEST}/${A_N}"

  tar --exclude='logs/*' \
    --exclude='cache/*' \
    --exclude='crash-reports/*' \
    --exclude='bluemap/web/data/*' \
    --exclude='*.jar' \
    --exclude='libraries/*' \
    --exclude='versions/*' \
    --exclude='.fabric/*' \
    -I 'zstd -11 -T0' \
    -cf "$A_P" -C "$B_DIR" "$w" >/dev/null 2>&1 &

  pid=$!
  pacman_anim "$pid" "Compressing [${w}] ➜ [${A_N}]..."
  wait "$pid"

  if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$U_GRP" "$A_P"
  fi

  echo -e "${GREEN}${BOLD}[✔ Success]${NC} [${w}] ➜ [${A_P}]"
done

if [ -n "$SUDO_USER" ]; then
  chown "$SUDO_USER:$U_GRP" "$B_DEST"
fi

echo -e "\n${BLUE}${BOLD}[✦ Done]${NC} Vault located at: [${B_DEST}]"
