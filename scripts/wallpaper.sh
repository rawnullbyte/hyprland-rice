#!/bin/bash

# Wallpaper setter with pywal integration
# Supports images and videos (with mpvpaper)

set -e

# --- CONFIG ---
WALLPAPER_DIR="$HOME/wallpapers"
CAVA_CONFIG="$HOME/.config/cava/config"
CACHE_PATH="$HOME/wallpapers/current.jpg"
VIDEO_CACHE_DIR="$HOME/wallpapers/cache"

# --- COLORS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }

# Create directories if they don't exist
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$VIDEO_CACHE_DIR"

# 1. SELECT WALLPAPER
if [ "$1" = "--init" ] && [ -f "$CACHE_PATH" ]; then
    selected_wallpaper="$CACHE_PATH"
    info "Using cached wallpaper"
elif [ -n "$1" ]; then
    # Direct file path provided
    if [ -f "$1" ]; then
        selected_wallpaper="$1"
    else
        echo "File not found: $1"
        exit 1
    fi
else
    # Use rofi to select
    if ! command -v rofi &> /dev/null; then
        echo "rofi not found, please provide wallpaper path as argument"
        exit 1
    fi
    
    selected_wallpaper=$(find "$WALLPAPER_DIR" -type f \( \
        -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
        -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" -o \
        -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o \
        -iname "*.avi" -o -iname "*.mov" \) | rofi -dmenu -i -p "Wallpaper:")
fi

[[ -z "$selected_wallpaper" ]] && exit 0

# 2. CHECK IF FILE IS A VIDEO
is_video=false
file_ext="${selected_wallpaper##*.}"
file_ext_lower=$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')

if [[ "$file_ext_lower" =~ ^(mp4|webm|mkv|avi|mov)$ ]]; then
    is_video=true
fi

# 3. SET WALLPAPER
if [ "$is_video" = true ]; then
    info "Video wallpaper detected"
    
    # Extract frame for pywal
    mkdir -p "$VIDEO_CACHE_DIR"
    cache_filename="frame_$(echo "$selected_wallpaper" | md5sum | cut -d' ' -f1).jpg"
    cache_path="$VIDEO_CACHE_DIR/$cache_filename"
    
    if [ ! -f "$cache_path" ]; then
        info "Extracting frame for color generation..."
        ffmpeg -i "$selected_wallpaper" -vframes 1 -vf "scale=1920:1080:force_original_aspect_ratio=decrease" -y "$cache_path" 2>/dev/null
    fi
    
    color_source="$cache_path"
    
    # Set animated wallpaper
    if command -v mpvpaper &> /dev/null; then
        pkill mpvpaper 2>/dev/null || true
        monitor_output=$(hyprctl monitors -j | jq -r '.[0].name' 2>/dev/null || echo "eDP-1")
        mpvpaper -f -o "no-audio loop" "$monitor_output" "$selected_wallpaper" >/dev/null 2>&1 &
        success "Video wallpaper set with mpvpaper"
    else
        warn "mpvpaper not installed, using static frame"
        if command -v swww &> /dev/null; then
            swww img "$cache_path" --transition-type fade --transition-duration 0.5
        fi
    fi
else
    color_source="$selected_wallpaper"
    pkill mpvpaper 2>/dev/null || true
    
    # Set static wallpaper
    if command -v swww &> /dev/null; then
        swww img "$selected_wallpaper" --transition-type fade --transition-duration 0.5
        success "Wallpaper set with swww"
    elif command -v hyprpaper &> /dev/null; then
        # Kill existing hyprpaper
        pkill hyprpaper 2>/dev/null || true
        sleep 0.1
        # Start hyprpaper with new wallpaper
        monitor=$(hyprctl monitors -j | jq -r '.[0].name' 2>/dev/null || echo "eDP-1")
        hyprpaper --preload "$selected_wallpaper" &
        sleep 0.5
        hyprctl hyprpaper wallpaper "$monitor,$selected_wallpaper"
        success "Wallpaper set with hyprpaper"
    elif command -v feh &> /dev/null; then
        feh --bg-fill "$selected_wallpaper"
        success "Wallpaper set with feh"
    else
        warn "No wallpaper utility found (swww, hyprpaper, or feh)"
    fi
fi

# 4. GENERATE PYWAL COLORS
info "Generating color scheme..."
wal -i "$color_source" -n -q 2>/dev/null || wal -i "$color_source" -n

# 5. UPDATE ROFI THEME
if [ -f "$HOME/.cache/wal/colors-rofi-dark.rasi" ]; then
    cp "$HOME/.cache/wal/colors-rofi-dark.rasi" "$HOME/.config/rofi/colors.rasi"
    success "Rofi theme updated"
fi

# 6. UPDATE HYPLOCK COLORS
if [ -f "$HOME/.cache/wal/colors.sh" ]; then
    source "$HOME/.cache/wal/colors.sh"
    if [ -f "$HOME/.config/hypr/hyprlock.conf" ]; then
        sed -i "s/color = \${color4:-rgba(255, 185, 0, 0.9)}/color = ${color4}/g" "$HOME/.config/hypr/hyprlock.conf" 2>/dev/null || true
        sed -i "s/check_color = \${color7:-rgba(255, 255, 255, 0.7)}/check_color = ${color7}/g" "$HOME/.config/hypr/hyprlock.conf" 2>/dev/null || true
        sed -i "s/fail_color = \${color1:-rgba(255, 100, 100, 0.7)}/fail_color = ${color1}/g" "$HOME/.config/hypr/hyprlock.conf" 2>/dev/null || true
        success "Hyprlock colors updated"
    fi
fi

# 7. RELOAD QUICKSHELL
if command -v quickshell &> /dev/null; then
    killall -USR1 quickshell 2>/dev/null || true
    sleep 0.3
    quickshell -d >/dev/null 2>&1 &
    success "Quickshell reloaded"
fi

# 8. UPDATE KITTY THEME
if [ -f "$HOME/.cache/wal/colors-kitty.conf" ]; then
    cp "$HOME/.cache/wal/colors-kitty.conf" "$HOME/.config/kitty/current-theme.conf"
    kitty @ set-colors -a "$HOME/.cache/wal/colors-kitty.conf" 2>/dev/null &
    success "Kitty theme updated"
fi

# 9. UPDATE CAVA COLORS
if [ -f "$HOME/.cache/wal/colors.sh" ] && [ -f "$CAVA_CONFIG" ]; then
    source "$HOME/.cache/wal/colors.sh"
    sed -i "s/^gradient_color_1 = .*/gradient_color_1 = '$color2'/" "$CAVA_CONFIG"
    sed -i "s/^gradient_color_2 = .*/gradient_color_2 = '$color3'/" "$CAVA_CONFIG"
    pkill -USR2 cava 2>/dev/null || true
    success "Cava colors updated"
fi

# 10. REFRESH NOTIFICATIONS & FIREFOX
swaync-client --reload-css 2>/dev/null &
pywalfox update 2>/dev/null &

# 11. CACHE CURRENT WALLPAPER
cp "$color_source" "$CACHE_PATH"

success "Done!"
