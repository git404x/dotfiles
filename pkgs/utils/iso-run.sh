#!/usr/bin/env bash

# iso-run: Total Isolation Wrapper
# Uses 'cage' (a Wayland kiosk compositor) to run applications in a totally
# isolated sandbox. The application thinks it is permanently focused, fullscreen,
# and visible, completely oblivious to your actual workspace/overlay changes.

if [ -z "$1" ]; then
    echo "Usage: iso-run <command>"
    echo "Example: iso-run zen-browser"
    exit 1
fi

# Ensure cage is available
if ! command -v cage &> /dev/null; then
    echo "Error: 'cage' is not installed."
    echo "Please add pkgs.cage to your configuration."
    exit 1
fi

# Launch cage with the target application
# -d: Disables client-side decorations (forces true fullscreen kiosk mode)
exec cage -d -- "$@"
