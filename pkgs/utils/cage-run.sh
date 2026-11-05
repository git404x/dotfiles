#!/usr/bin/env bash
set -euo pipefail

# cage-run: run command in isolated Cage session or open launcher if empty
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "usage: cage-run [cmd | -l]"
  exit 0
fi

if [ $# -eq 0 ] || [ "${1:-}" = "-l" ] || [ "${1:-}" = "--launcher" ]; then
  exec fuzzel --launch-prefix="cage-run" -p "Isolated > "
fi

exec cage -d -- "$@"
