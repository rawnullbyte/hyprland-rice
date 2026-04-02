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
    "hyprland" "hyprlock" "xdg-desktop-portal-hyprland"
    "kitty" "starship" "rofi" "swaync" "cava"
    "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
    "playerctl" "mpv" "swww" "pywal16" "brightnessctl"
    "wl-clipboard" "jq" "ffmpeg" "imagemagick" "polkit-kde-agent"
    "network-manager-applet" "nm-connection-editor" "bluez" "bluez-utils"
    "ttf-jetbrains-mono-nerd" "ttf-inter" "cliphist" "fastfetch"
    "zsh"
)

PACKAGES_YAY=(
    "quickshell-git"
    "swayosd-git" 
    "pywalfox-bin"
    "grim" "slurp" "hyprshot"
    "ttf-material-design-icons-git"
)

install_packages() {
    info "Updating system and installing dependencies..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --needed --noconfirm "${PACKAGES_PACMAN[@]}"
    yay -S --needed --noconfirm "${PACKAGES_YAY[@]}"
}

copy_dotfiles() {
    info "Deploying dotfiles from $DOTS_SRC..."
    
    cp -a "$DOTS_SRC/." "$HOME/"

    # Ensure scripts are executable
    if [ -d "$HOME/.config/hypr/scripts" ]; then
        chmod +x "$HOME/.config/hypr/scripts/"*.sh
    fi
    
    success "Dotfiles deployed successfully."
}

enable_services() {
    info "Enabling essential services..."
    sudo systemctl enable --now bluetooth.service
    systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
}

install_oh_my_zsh() {
    info "Installing Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        warn "Oh My Zsh is already installed, skipping..."
        return
    fi
    # Download and install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Set zsh as default shell
    info "Setting zsh as default shell..."
    sudo chsh -s /usr/bin/zsh "$USER"
}

main() {
    check_distro
    install_yay
    install_packages
    copy_dotfiles
    enable_services
    install_oh_my_zsh
    echo -e "\n${GREEN}Installation Complete!${NC}"
}

main