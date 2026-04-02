# Hyprland Rice

A minimal, clean, and highly customized Hyprland desktop setup with pywal color integration.

![Preview](preview.png)

## Features

- **Window Manager**: Hyprland with smooth animations
- **Status Bar**: Custom Quickshell bar with media controls, weather, calendar
- **Lock Screen**: Hyprlock with transparent blur and pywal colors
- **App Launcher**: Minimal rofi configuration with pywal theming
- **Terminal**: Kitty with pywal integration
- **Wallpaper**: Supports static images and video wallpapers (awww & mpvpaper)
- **Color Scheme**: Automatic color generation with pywal

## Keybindings

| Key | Action |
| :--- | :--- |
| `Super + T` | Open terminal |
| `Super_L` (Tap) | Application launcher (Rofi) |
| `Super + Q` | Close active window |
| `Super + M` | Exit Hyprland |
| `Super + E` | Open file manager |
| `Super + W` | Toggle floating mode |
| `Super + F` | Toggle fullscreen |
| `Super + L` | Lock screen |
| `Super + V` | Clipboard history (Rofi) |
| `Super + 0-9` | Switch workspace |
| `Super + Alt + 0-9` | Move window to workspace |
| `Alt + W` | Change wallpaper |
| `Super + Shift + S / PRTSC` | Screenshot region to clipboard |
| `Super + Arrow Keys` | Move focus (Left, Right, Up, Down) |

---

### Mouse Controls

| Key | Action |
| :--- | :--- |
| `Super + Left Click` | Move window |
| `Super + Right Click` | Resize window |
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

## Credits

- [MrVivekRajan/Hyprlock-Styles](https://github.com/MrVivekRajan/Hyprlock-Styles) - Lock screen style reference
- [pywal](https://github.com/dylanaraps/pywal) - Color scheme generation
- [Quickshell](https://github.com/quickshell-mirror/quickshell) - Status bar

## License

MIT
