#!/usr/bin/env bash
set -e

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'
BOLD='\033[1m'

DOTFILES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then DOTFILES_DIR="$HOME/dotfiles"; fi

SERVER_DIR="$DOTFILES_DIR/config/minecraft/server"
CLIENT_DIR="$DOTFILES_DIR/config/minecraft/client"
OUTPUT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/minecraft/releases"

mkdir -p "$OUTPUT_DIR"

echo -e "${CYAN}${BOLD}======================${NC}"
echo -e "${CYAN}${BOLD}   Modpack compiler   ${NC}"
echo -e "${CYAN}${BOLD}======================${NC}\n"

echo -e "  ${YELLOW}1)${NC} fluxd (server)"
echo -e "  ${YELLOW}2)${NC} flux (client)"
echo -e "  ${YELLOW}3)${NC} Both"
echo -n -e "\n${BLUE}${BOLD}[➜] Select target:${NC} "
read -r C

COMPILE_SERVER=0
COMPILE_CLIENT=0

case $C in
1) COMPILE_SERVER=1 ;;
2) COMPILE_CLIENT=1 ;;
3)
  COMPILE_SERVER=1
  COMPILE_CLIENT=1
  ;;
*)
  echo -e "${RED}${BOLD}[✖] Invalid selection!${NC}"
  exit 1
  ;;
esac

pacman_anim() {
  local p=$1
  local m=$2
  local f=("ᗧ · · · ·" " ᗧ · · · " "  ᗧ · ·  " "   ᗧ ·   " "    ᗧ    " "· · · · ᗤ" "· · · ᗤ  " "· · ᗤ    " "· ᗤ      ")

  tput civis
  while kill -0 "$p" 2>/dev/null; do
    for i in "${f[@]}"; do
      local cols
      cols=$(tput cols 2>/dev/null || echo 80)
      local max_len=$((cols - 18))
      local trunc_m="${m}"
      if [ ${#m} -gt $max_len ] && [ $max_len -gt 3 ]; then trunc_m="${m:0:$((max_len - 3))}..."; fi
      printf "\r\033[2K${YELLOW}${BOLD}[ %s ]${NC} ${CYAN}%s${NC}" "$i" "$trunc_m"
      sleep 0.15
      kill -0 "$p" 2>/dev/null || break
    done
  done
  printf "\r\033[2K"
  tput cnorm
}

compile_pack() {
  local TYPE=$1
  local DIR=$2
  local NAME=$3

  echo -e "\n${BLUE}${BOLD}==> Processing ${TYPE} ...${NC}"
  cd "$DIR" || exit 1

  packwiz refresh >/dev/null
  packwiz modrinth export -o "$OUTPUT_DIR/${NAME}.mrpack" >/dev/null
  echo -e "  ${GREEN}✔${NC} Generated: ${NAME}.mrpack"

  (
    cd "$OUTPUT_DIR"
    mrpack-install "${NAME}.mrpack" --server-dir "./${NAME}-raw" >/dev/null 2>&1
    zip -rq "${NAME}-raw.zip" "${NAME}-raw/"
    rm -rf "${NAME}-/"
  ) &

  PID=$!
  pacman_anim $PID "Downloading raw jars & zipping..."
  wait $PID

  echo -e "  ${GREEN}✔${NC} Generated: ${NAME}-raw.zip"
}

if [ "$COMPILE_SERVER" -eq 1 ]; then
  if [ -d "$SERVER_DIR" ]; then
    compile_pack "server" "$SERVER_DIR" "fluxd-server"
  else echo -e "${RED}[✖] Server workspace missing${NC}"; fi
fi

if [ "$COMPILE_CLIENT" -eq 1 ]; then
  if [ -d "$CLIENT_DIR" ]; then
    compile_pack "client" "$CLIENT_DIR" "flux-client"
  else echo -e "${RED}[✖] Client workspace missing${NC}"; fi
fi

echo -e "\n${GREEN}${BOLD}[✔ Done ] ${OUTPUT_DIR}${NC}"
