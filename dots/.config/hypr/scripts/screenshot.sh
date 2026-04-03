#!/bin/bash
# Hyprland screenshot script - clean, no notifications
# Usage:
#   screenshot          → freeze + select + copy to clipboard
#   screenshot edit     → freeze + select + copy + open in Swappy

MODE="${1:-normal}"

# Start screen freeze (Hyprland native way - light & fast)
hyprpicker -rz &
FREEZE_PID=$!

# Small delay so the freeze kicks in before selection starts
sleep 0.15

# Take the screenshot while frozen
IMG_FILE=$(mktemp /tmp/screenshot.XXXXXX.png)
grim -g "$(slurp -d)" "$IMG_FILE"

# Stop the freeze immediately
kill $FREEZE_PID 2>/dev/null || true

# Always copy to clipboard
wl-copy < "$IMG_FILE"

# Open Swappy only in edit mode
if [ "$MODE" = "edit" ]; then
    swappy -f "$IMG_FILE"
fi

# Clean up
rm -f "$IMG_FILE"