#!/bin/bash

# --- CONFIG ---
WALLPAPER_DIR="$HOME/wallpapers/walls"
CAVA_CONFIG="$HOME/.config/cava/config"
CACHE_PATH="$HOME/wallpapers/pywallpaper.jpg"
VIDEO_CACHE_DIR="$HOME/wallpapers/cache"

# Video file extensions
VIDEO_EXTENSIONS="mp4|webm|mkv|avi|mov|gifv"

# Start awww daemon if not running
if ! pgrep -x "awww-daemon" >/dev/null; then
  awww-daemon >/dev/null 2>&1 &
  sleep 1
fi

# Select wallpaper
if [ "$1" = "--init" ] && [ -f "$CACHE_PATH" ]; then
    selected_wallpaper="$CACHE_PATH"
else
    selected_wallpaper=$(find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \) | rofi -dmenu -i -p "Wallpaper:")
fi

[[ -z "$selected_wallpaper" ]] && exit 0

# Check if file is a video
is_video=false
file_ext="${selected_wallpaper##*.}"
file_ext_lower=$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')

if [[ "$file_ext_lower" =~ ^(mp4|webm|mkv|avi|mov)$ ]]; then
    is_video=true
fi

# Extract frame from video for pywal
if [ "$is_video" = true ]; then
    # Create cache directory if it doesn't exist
    mkdir -p "$VIDEO_CACHE_DIR"
    
    # Extract first frame from video
    cache_filename="frame_$(echo "$selected_wallpaper" | md5sum | cut -d' ' -f1).jpg"
    cache_path="$VIDEO_CACHE_DIR/$cache_filename"
    
    # Extract frame if not already cached
    if [ ! -f "$cache_path" ]; then
        ffmpeg -i "$selected_wallpaper" -vframes 1 -vf "scale=1920:1080:force_original_aspect_ratio=decrease" -y "$cache_path" 2>/dev/null
    fi
    
    color_source="$cache_path"
    
    # Set animated wallpaper using mpvpaper if available, else use extracted frame
    if command -v mpvpaper &> /dev/null; then
        # Kill any existing mpvpaper instances
        pkill mpvpaper 2>/dev/null
        
        # Get monitor output
        monitor_output=$(hyprctl monitors -j | jq -r '.[0].name')
        
        # Use mpvpaper for video wallpapers (fork mode, loop, no audio)
        mpvpaper -f -o "no-audio loop" "$monitor_output" "$selected_wallpaper" >/dev/null 2>&1 &
    else
        # Fall back to static frame with awww
        awww img "$color_source" --transition-type any --transition-fps 60 --transition-duration .5 >/dev/null 2>&1 &
    fi
else
    color_source="$selected_wallpaper"
    # Kill mpvpaper if switching from video to image
    pkill mpvpaper 2>/dev/null
    # Apply static wallpaper
    awww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5 >/dev/null 2>&1 &
fi

# Generate Pywal colors
# Delete cached color scheme for this image to force regeneration
SCHEME_BASE=$(echo "$color_source" | sed 's|/|_|g; s|\.|_|g')
find "$HOME/.cache/wal/schemes/" -name "${SCHEME_BASE}*" -delete 2>/dev/null
wal -i "$color_source" -q

# Generate Rofi colors
if [ -f "$HOME/.cache/wal/colors-rofi-dark.rasi" ]; then
    cat "$HOME/.cache/wal/colors-rofi-dark.rasi" > "$HOME/.config/rofi/colors.rasi"
fi

# Update hyprlock colors
if [ -f "$HOME/.cache/wal/colors.sh" ]; then
    source "$HOME/.cache/wal/colors.sh"
    
    # Update the hyprlock config with pywal colors
    sed -i "s/color = \${color4:-rgba(255, 185, 0, 0.6)}/color = ${color4}/g" "$HOME/.config/hypr/hyprlock.conf" 2>/dev/null
    sed -i "s/check_color = \${color7:-rgba(255, 255, 255, 0.8)}/check_color = ${color7}/g" "$HOME/.config/hypr/hyprlock.conf" 2>/dev/null
    sed -i "s/fail_color = \${color1:-rgba(255, 100, 100, 0.8)}/fail_color = ${color1}/g" "$HOME/.config/hypr/hyprlock.conf" 2>/dev/null
fi

# 8. Reload quickshell colors
killall -USR1 quickshell 2>/dev/null &
sleep 0.5
quickshell -d >/dev/null 2>&1 &

# 9. REFRESH KITTY THEME
if [ -f "$HOME/.cache/wal/colors-kitty.conf" ]; then
    cat "$HOME/.cache/wal/colors-kitty.conf" > "$HOME/.config/kitty/current-theme.conf"
    kitty @ set-colors -a "$HOME/.cache/wal/colors-kitty.conf" &
fi

# 10. UPDATE CAVA
if [ -f "$HOME/.cache/wal/colors.sh" ]; then
  source "$HOME/.cache/wal/colors.sh"
  if [ -f "$CAVA_CONFIG" ]; then
    sed -i "s/^gradient_color_1 = .*/gradient_color_1 = '$color2'/" "$CAVA_CONFIG"
    sed -i "s/^gradient_color_2 = .*/gradient_color_2 = '$color3'/" "$CAVA_CONFIG"
    pkill -USR2 cava 2>/dev/null
  fi
fi

# 11. REFRESH OTHER SERVICES
(swaync-client --reload-css && pywalfox update) >/dev/null 2>&1 &

# 12. SYNC FOR STARSHIP/SCRIPTS
cp "$color_source" "$CACHE_PATH"
