#!/usr/bin/env bash

# Get current workspace
current_workspace=$(hyprctl activeworkspace -j | jq '.id')

# Function to map key to target workspace
get_target_workspace() {
    local key=$1
    
    if [ $current_workspace -ge 1 ] && [ $current_workspace -le 10 ]; then
        # Map 1-9 directly, 0 maps to 10
        if [ "$key" -eq 0 ]; then
            echo 10
        else
            echo $key
        fi
    elif [ $current_workspace -eq 11 ]; then
        # Map 1-9 to 11-19, 0 maps to 20
        if [ "$key" -eq 0 ]; then
            echo 20
        else
            echo $((10 + key))
        fi
    else
        # Default behavior for other workspaces
        if [ "$key" -eq 0 ]; then
            echo 10
        else
            echo $key
        fi
    fi
}

# Main logic
if [ $# -ne 2 ]; then
    echo "Usage: $0 <switch|move> <key>"
    echo "  switch - Switch to the workspace"
    echo "  move   - Move current window to workspace"
    echo "  key    - Should be 1-9 or 0"
    exit 1
fi

action=$1
key=$2

# Validate action
if [ "$action" != "switch" ] && [ "$action" != "move" ]; then
    echo "Error: Action must be 'switch' or 'move'"
    echo "Usage: $0 <switch|move> <key>"
    exit 1
fi

# Validate key
if ! [[ "$key" =~ ^[0-9]$ ]]; then
    echo "Error: Key must be a number between 0-9"
    exit 1
fi

target=$(get_target_workspace $key)

# Perform the action
if [ "$action" = "switch" ]; then
    hyprctl dispatch workspace $target
elif [ "$action" = "move" ]; then
    hyprctl dispatch movetoworkspace $target
fi