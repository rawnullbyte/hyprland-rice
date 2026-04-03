#!/usr/bin/env bash

# Get current workspace
current_workspace=$(hyprctl activeworkspace -j | jq '.id')

# Function to map key to target workspace
# Logic: ranges 1-10, 11-20, 21-30, etc.
get_target_workspace() {
    local key=$1
    
    # Calculate tens based on range: 1-10→0, 11-20→10, 21-30→20, etc.
    local tens=$(( ((current_workspace - 1) / 10) * 10 ))
    
    # 0 maps to tens+10, key maps to tens+key
    if [ "$key" -eq 0 ]; then
        echo $((tens + 10))
    else
        echo $((tens + key))
    fi
}

# Main logic
if [ $# -ne 2 ]; then
    echo "Usage: $0 <switch|move> <key>"
    exit 1
fi

action=$1
key=$2

target=$(get_target_workspace $key)

# Perform the action
if [ "$action" = "switch" ]; then
    hyprctl dispatch workspace $target
elif [ "$action" = "move" ]; then
    hyprctl dispatch movetoworkspace $target
fi