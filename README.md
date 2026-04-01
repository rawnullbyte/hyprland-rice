# Hyprland Rice

A minimal, clean, and highly customized Hyprland desktop setup with pywal color integration.

![Preview](preview.png)

## Features

- **Window Manager**: Hyprland with smooth animations
- **Status Bar**: Custom Quickshell bar with media controls, weather, calendar
- **Lock Screen**: Hyprlock with transparent blur and pywal colors
- **App Launcher**: Minimal rofi configuration with pywal theming
- **Terminal**: Kitty with pywal integration
- **Wallpaper**: Supports static images and video wallpapers (mpvpaper)
- **Color Scheme**: Automatic color generation with pywal

## Components

| Component | Description |
|-----------|-------------|
| Hyprland | Wayland compositor with animations |
| Quickshell | Status bar with workspaces, media, weather, calendar |
| Hyprlock | Lock screen with blur and transparency |
| Rofi | App launcher with pywal colors |
| Kitty | Terminal emulator |
| Pywal | Color scheme generator |
| cava | Audio visualizer |

## Keybindings

| Key | Action |
|-----|--------|
| `Super + Enter` | Open terminal |
| `Super + D` | Application launcher |
| `Super + Q` | Close window |
| `Super + M` | Exit menu |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Super + B` | Toggle bar |
| `Print Screen` | Screenshot |
| `Super + Space` | Toggle float |

## Installation

### Prerequisites

- Arch Linux or Arch-based distribution
- Internet connection
- Basic knowledge of terminal commands

### Quick Install

```bash
git clone https://github.com/rawnullbyte/hyprland-rice.git
cd hyprland-rice
chmod +x install.sh
./install.sh
```

The install script will:
1. Install yay (AUR helper)
2. Install all required packages
3. Backup existing dotfiles
4. Copy new configurations
5. Enable necessary services

### Manual Install

If you prefer to install manually:

1. Install packages:
```bash
sudo pacman -S hyprland hyprlock hyprpaper kitty rofi fish starship \
               pipewire pipewire-pulse wireplumber cava swaync \
               playerctl swww mpvpaper pywal16 brightnessctl \
               wl-clipboard jq ffmpeg ttf-jetbrains-mono-nerd ttf-inter
```

2. Install AUR packages:
```bash
yay -S quickshell-git pywalfox-bin hyprshot
```

3. Copy dotfiles:
```bash
cp -r .config/* ~/.config/
cp -r scripts/* ~/.local/bin/
chmod +x ~/.local/bin/*.sh
```

## Usage

### Setting a Wallpaper

```bash
# Interactive selection
~/.local/bin/wallpaper.sh

# Direct path
~/.local/bin/wallpaper.sh ~/path/to/wallpaper.jpg

# Restore last wallpaper
~/.local/bin/wallpaper.sh --init
```

### Changing Colors

The color scheme is automatically generated from your wallpaper using pywal. Just change your wallpaper and everything updates automatically.

## Customization

### Bar Components

Edit files in `~/.config/quickshell/modules/bar/components/`:
- `Clock.qml` - Clock and calendar popup
- `Weather.qml` - Weather widget
- `MediaPlayer.qml` - Media controls
- `Network.qml` - Network indicator
- `Bluetooth.qml` - Bluetooth indicator

### Colors

The color scheme is stored in `~/.cache/wal/colors.json` and used by all applications.

## Directory Structure

```
~/.config/
├── hypr/
│   ├── hyprland.conf
│   ├── hyprlock.conf
│   └── wallpaper.sh
├── quickshell/
│   ├── shell.qml
│   ├── modules/
│   │   └── bar/
│   ├── services/
│   └── components/
├── rofi/
│   ├── config.rasi
│   └── colors.rasi
├── kitty/
│   └── kitty.conf
└── cava/
    └── config
```

## Troubleshooting

### Bar not showing
```bash
killall quickshell
quickshell -d
```

### Colors not updating
```bash
# Re-run wallpaper script
~/.local/bin/wallpaper.sh --init
```

### Lock screen not working
```bash
hyprlock
```

## Credits

- [MrVivekRajan/Hyprlock-Styles](https://github.com/MrVivekRajan/Hyprlock-Styles) - Lock screen style reference
- [pywal](https://github.com/dylanaraps/pywal) - Color scheme generation
- [Quickshell](https://github.com/quickshell-mirror/quickshell) - Status bar

## License

MIT
