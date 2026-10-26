#!/usr/bin/env bash

# cage-run: Run application in an isolated Cage Wayland session
if [ -z "$1" ]; then
  echo "Usage: cage-run <command>"
  echo "Example: cage-run zen-browser"
  exit 1
fi

exec cage -d -- "$@"
