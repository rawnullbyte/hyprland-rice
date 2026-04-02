#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_SRC="$SCRIPT_DIR/dots"

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_distro() {
    if ! command -v pacman &> /dev/null; then
        error "This script requires an Arch-based distribution (pacman not found)"
        exit 1
    fi
}

install_yay() {
    if command -v yay &> /dev/null; then
        success "yay is already installed"
        return
    fi
    info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    rm -rf "$TEMP_DIR"
}

PACKAGES_PACMAN=(
    # Core Hyprland & Wayland
    "hyprland" "hyprlock" "xdg-desktop-portal-hyprland" "qt5-wayland" "qt6-wayland"
    
    # Terminal & Shell
    "kitty" "zsh" "starship" "fastfetch"
    
    # Desktop Components & Navigation
    "rofi-wayland" "swaync" "dolphin" "polkit-kde-agent"
    
    # Media & Audio (Powers your wpctl and playerctl binds)
    "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol" "playerctl" "mpv"
    
    # Utilities (Brightness, Clipboard, and Screenshots)
    "brightnessctl" "wl-clipboard" "cliphist" "grim" "slurp" "swappy"
    "jq" "ffmpeg" "imagemagick"
    
    # Appearance & Networking
    "cava" "cmatrix" "python-pywal" "ttf-jetbrains-mono-nerd" "ttf-inter"
    "network-manager-applet" "nm-connection-editor" "bluez" "bluez-utils"
)

PACKAGES_YAY=(
    "quickshell-git"                # For desktop widgets/shell
    "swayosd-git"                   # On-screen display for volume/brightness
    "pywalfox-bin"                  # Connects pywal colors to Firefox
    "hyprshot"                      # Alternative screenshot utility
    "ttf-material-design-icons-git" # Required for many status bar icons
    "mpvpaper"                      # For video wallpapers
)

install_packages() {
    info "Updating system and installing dependencies..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --needed --noconfirm "${PACKAGES_PACMAN[@]}"
    yay -S --needed --noconfirm "${PACKAGES_YAY[@]}"
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        warn "Oh My Zsh is already installed, skipping..."
    else
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Install Plugins
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    
    info "Installing ZSH Plugins..."
    # Syntax Highlighting
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    
    # Auto-suggestions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    # Set zsh as default shell
    if [ "$SHELL" != "/usr/bin/zsh" ]; then
        info "Setting zsh as default shell..."
        sudo chsh -s /usr/bin/zsh "$USER"
    fi
}

copy_dotfiles() {
    info "Deploying dotfiles from $DOTS_SRC..."
    
    # We use -a to preserve permissions and -f to overwrite the default .zshrc
    if [ -d "$DOTS_SRC" ]; then
        cp -af "$DOTS_SRC/." "$HOME/"
    fi

    # Ensure scripts are executable
    if [ -d "$HOME/.config/hypr/scripts" ]; then
        chmod +x "$HOME/.config/hypr/scripts/"*.sh
    fi
    
    success "Dotfiles deployed successfully."
}

enable_services() {
    info "Configuring groups and services..."

    # Enable Bluetooth
    sudo systemctl enable --now bluetooth.service
    
    # Enable Audio Services (User Level)
    systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
}

main() {
    check_distro
    install_yay
    install_packages
    install_oh_my_zsh
    copy_dotfiles
    enable_services
    echo -e "\n${GREEN}Installation Complete!${NC}"
    echo -e "${YELLOW}IMPORTANT: You MUST reboot now for group permissions (SwayOSD) to take effect.${NC}"
}

main