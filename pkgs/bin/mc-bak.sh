#!/usr/bin/env bash
set -euo pipefail

# colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'
BOLD='\033[1m'

# env checks
[[ "$EUID" -ne 0 ]] && {
  echo -e "${RED}${BOLD}[✖ error]${NC} run with sudo!"
  exit 1
}

for cmd in tar zstd; do
  command -v "$cmd" >/dev/null || {
    echo -e "${RED}${BOLD}[✖ error]${NC} '$cmd' missing!"
    exit 1
  }
done

HAS_PV=0
command -v pv >/dev/null && HAS_PV=1

S_USER="${SUDO_USER:-$USER}"
U_HOME=$(eval echo ~"$S_USER")
U_GRP=$(id -gn "$S_USER")

# paths
if [[ -n "$SUDO_USER" && (-z "${XDG_DATA_HOME:-}" || "$XDG_DATA_HOME" == "/root/"*) ]]; then
  B_BASE="$U_HOME/.local/share/minecraft"
else
  B_BASE="${XDG_DATA_HOME:-$U_HOME/.local/share}/minecraft"
fi
B_DEST="$B_BASE/backups"

mkdir -p "$B_DEST"
chown "$S_USER:$U_GRP" "$B_DEST" "$B_BASE" 2>/dev/null || true

# targets
TARGET_NAMES=()
TARGET_PATHS=()
TARGET_MODES=()

add_target() {
  if [[ -d "$2" ]]; then
    TARGET_NAMES+=("$1")
    TARGET_PATHS+=("$2")
    TARGET_MODES+=("$3")
  fi
}

add_target ".minecraft (saves)" "$U_HOME/.minecraft" "SAVES"
add_target ".minecraft (configs)" "$U_HOME/.minecraft" "CONFIGS"
add_target "minecraft-server (user)" "$U_HOME/minecraft-server" "SERVER"

if [[ -d "/var/lib/minecraft" ]]; then
  for dir in /var/lib/minecraft/*; do
    [[ -d "$dir" ]] && add_target "$(basename "$dir") (server)" "$dir" "SERVER"
  done
fi

[[ ${#TARGET_NAMES[@]} -eq 0 ]] && {
  echo -e "${RED}${BOLD}[✖ error]${NC} no dirs found!"
  exit 1
}

# selection
echo -e "${CYAN}${BOLD}[ backup targets ]${NC}"
for i in "${!TARGET_NAMES[@]}"; do
  echo -e "  ${YELLOW}$((i + 1))${NC}) ${TARGET_NAMES[$i]}"
done
echo -e "  ${YELLOW}$((${#TARGET_NAMES[@]} + 1))${NC}) all of the above"

echo -n -e "\n${BLUE}${BOLD}[➜] select option:${NC} "
read -r choice

SELECTED_IDX=()
if [[ "$choice" =~ ^[0-9]+$ ]]; then
  if [[ "$choice" -eq $((${#TARGET_NAMES[@]} + 1)) ]]; then
    SELECTED_IDX=("${!TARGET_NAMES[@]}")
  elif [[ "$choice" -ge 1 && "$choice" -le ${#TARGET_NAMES[@]} ]]; then
    SELECTED_IDX=($((choice - 1)))
  fi
fi

[[ ${#SELECTED_IDX[@]} -eq 0 ]] && {
  echo -e "${RED}[✖ error]${NC} invalid selection!"
  exit 1
}

# progress anim
show_progress() {
  local pid=$1 msg=$2 prog=$3
  local frames=("ᗧ · · · ·" " ᗧ · · · " "  ᗧ · ·  " "   ᗧ ·   " "    ᗧ    " "· · · · ᗤ" "· · · ᗤ  " "· · ᗤ    " "· ᗤ      ")

  tput civis
  while kill -0 "$pid" 2>/dev/null; do
    for f in "${frames[@]}"; do
      kill -0 "$pid" 2>/dev/null || break
      local pct=""
      if [[ -f "$prog" ]]; then
        local val
        val=$(tail -n 1 "$prog" 2>/dev/null | tr -dc '0-9')
        [[ -n "$val" ]] && pct="[${val}%] "
      fi
      local cols
      cols=$(tput cols 2>/dev/null || echo 80)
      local max=$((cols - 18 - ${#pct}))
      local txt="$msg"
      [[ ${#txt} -gt $max && $max -gt 3 ]] && txt="${txt:0:$((max - 3))}..."
      printf "\r\033[K${YELLOW}${BOLD}[ %s ]${NC} ${GREEN}%s${NC}${CYAN}%s${NC}" "$f" "$pct" "$txt"
      sleep 0.15
    done
  done
  printf "\r\033[K"
  tput cnorm
}

# pv warning
[[ "$HAS_PV" -eq 0 ]] && echo -e "${YELLOW}[⚠ warning]${NC} 'pv' not found. percentage tracking disabled.\n"

# backup
DATE=$(date +'%Y-%m-%d_%H-%M-%S')

for i in "${SELECTED_IDX[@]}"; do
  name="${TARGET_NAMES[$i]}"
  src="${TARGET_PATHS[$i]}"
  mode="${TARGET_MODES[$i]}"

  safe_name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed 's/^-//;s/-$//')
  DEST_FILE="$B_DEST/${safe_name}_${DATE}.tar.zst"

  [[ ! -d "$src" ]] && {
    echo -e "${RED}[✖ error]${NC} cannot read $src. skipping..."
    continue
  }
  cd "$src" || continue

  EXCLUDES=()
  INCLUDES=()

  case "$mode" in
  SAVES)
    INCLUDES=("saves")
    ;;
  CONFIGS)
    EXCLUDES=("--exclude=sessions" "--exclude=crash_assistant" "--exclude=*.xwmc" "--exclude=*.outdated")
    shopt -s nullglob
    INCLUDES=(config options*.txt servers.dat *profiles*.json usercache.json)
    shopt -u nullglob
    ;;
  SERVER)
    INCLUDES=(".")
    EXCLUDES=(
      "--exclude=mods" "--exclude=cache" "--exclude=logs"
      "--exclude=crash-reports" "--exclude=*.jar" "--exclude=plugins/spark/tmp"
      "--exclude=.fabric" "--exclude=.mixin.out" "--exclude=libraries" "--exclude=versions"
    )
    ;;
  esac

  [[ ${#INCLUDES[@]} -eq 0 ]] && {
    echo -e "${YELLOW}[⚠ warning]${NC} no data found in $src. skipping..."
    continue
  }

  PROG_FILE="/tmp/mc-bak-prog-$$.txt"
  ERR_FILE="/tmp/mc-bak-err-$$.txt"
  : > "$PROG_FILE"
  : > "$ERR_FILE"

  (
    set -o pipefail
    if [[ "$HAS_PV" -eq 1 ]]; then
      bytes=$(du -sb -c "${INCLUDES[@]}" 2>/dev/null | awk 'END{print $1}' || echo "")
      pv_opt=("-n")
      [[ "$bytes" =~ ^[0-9]+$ ]] && pv_opt+=("-s" "$bytes")
      tar -cf - "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>"$ERR_FILE" | pv "${pv_opt[@]}" 2>"$PROG_FILE" | zstd -T0 -10 >"$DEST_FILE"
    else
      tar -cf - "${EXCLUDES[@]}" "${INCLUDES[@]}" 2>"$ERR_FILE" | zstd -T0 -10 >"$DEST_FILE"
    fi
  ) &
  pid=$!

  show_progress "$pid" "compressing $name..." "$PROG_FILE"
  wait "$pid"
  EXIT_CODE=$?

  FILE_SIZE=$(stat -c %s "$DEST_FILE" 2>/dev/null || stat -f %z "$DEST_FILE" 2>/dev/null || echo 0)

  if [[ "$EXIT_CODE" -ne 0 || "$FILE_SIZE" -lt 100 ]]; then
    if [[ "$FILE_SIZE" -lt 100 && "$EXIT_CODE" -eq 0 ]]; then
      echo -e "${YELLOW}${BOLD}[⚠ warning]${NC} target directory is empty. skipping $name."
      rm -f "$DEST_FILE"
    elif [[ "$FILE_SIZE" -lt 100 ]]; then
      echo -e "${RED}${BOLD}[✖ error]${NC} backup failed for $name!"
      [[ -s "$ERR_FILE" ]] && {
        echo -e "${YELLOW}details:${NC}"
        sed 's/^/  /' "$ERR_FILE"
      }
      echo -e "${RED}archive corrupt. deleting...${NC}"
      rm -f "$DEST_FILE"
    else
      echo -e "${YELLOW}${BOLD}[⚠ warning]${NC} completed with minor warnings for $name!"
      [[ -s "$ERR_FILE" ]] && {
        echo -e "${YELLOW}details:${NC}"
        sed 's/^/  /' "$ERR_FILE"
      }
      chown "$S_USER:$U_GRP" "$DEST_FILE" 2>/dev/null || true
      echo -e "${YELLOW}saved to $DEST_FILE${NC}"
    fi
  else
    chown "$S_USER:$U_GRP" "$DEST_FILE" 2>/dev/null || true
    echo -e "${GREEN}${BOLD}[✔ success]${NC} $DEST_FILE"
  fi

  rm -f "$PROG_FILE" "$ERR_FILE"
done

echo -e "\n${CYAN}${BOLD}[ finished ]${NC}"
