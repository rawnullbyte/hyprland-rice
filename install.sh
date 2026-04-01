#!/bin/bash

# Hyprland Rice - Auto Install Script
# https://github.com/rawnullbyte/hyprland-rice

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# Helper functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running on Arch-based distro
check_distro() {
    if ! command -v pacman &> /dev/null; then
        error "This script requires an Arch-based distribution (pacman not found)"
        exit 1
    fi
    info "Arch-based distribution detected"
}

# Install yay (AUR helper) if not present
install_yay() {
    if command -v yay &> /dev/null; then
        success "yay is already installed"
        return
    fi

    info "Installing yay (AUR helper)..."
    
    # Install base-devel if not present
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Clone and build yay
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    rm -rf "$TEMP_DIR"
    
    success "yay installed successfully"
}

# Package lists
PACKAGES_PACMAN=(
    # Window Manager & Compositor
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "xdg-desktop-portal-hyprland"
    
    # Terminal & Shell
    "kitty"
    "fish"
    "starship"
    
    # Application Launcher
    "rofi"
    
    # Status Bar
    "quickshell-git"
    
    # Audio
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "pavucontrol"
    "cava"
    
    # Notifications
    "swaync"
    
    # Media Control
    "playerctl"
    "mpv"
    
    # Wallpapers
    "swww"
    "mpvpaper"
    
    # Color Scheme
    "pywal16"
    
    # Utilities
    "brightnessctl"
    "wl-clipboard"
    "jq"
    "ffmpeg"
    "imagemagick"
    "polkit-kde-agent"
    "network-manager-applet"
    "nm-connection-editor"
    "bluetooth"
    "bluez-utils"
    
    # Fonts
    "ttf-jetbrains-mono-nerd"
    "ttf-inter"
    "ttf-material-design-icons-git"
    
    # GTK & Theming
    "gtk3"
    "gtk4"
    "nwg-look"
)

PACKAGES_YAY=(
    # Quickshell (if not in official repos)
    "quickshell-git"
    
    # Firefox pywal theme
    "pywalfox-bin"
    
    # Screenshot tool
    "grim"
    "slurp"
    "hyprshot"
)

# Install packages
install_packages() {
    info "Updating system..."
    sudo pacman -Syu --noconfirm
    
    info "Installing pacman packages..."
    sudo pacman -S --needed --noconfirm "${PACKAGES_PACMAN[@]}"
    
    info "Installing AUR packages..."
    yay -S --needed --noconfirm "${PACKAGES_YAY[@]}"
    
    success "All packages installed"
}

# Backup existing dotfiles
backup_dotfiles() {
    local backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
    
    info "Backing up existing dotfiles to $backup_dir"
    mkdir -p "$backup_dir"
    
    # List of directories/files to backup
    local items=(
        ".config/hypr"
        ".config/quickshell"
        ".config/rofi"
        ".config/kitty"
        ".config/cava"
        ".config/fish"
        ".config/starship.toml"
    )
    
    for item in "${items[@]}"; do
        if [ -e "$HOME/$item" ]; then
            mkdir -p "$backup_dir/$(dirname "$item")"
            cp -r "$HOME/$item" "$backup_dir/$item"
        fi
    done
    
    success "Backup created at $backup_dir"
}

# Copy dotfiles
copy_dotfiles() {
    info "Copying dotfiles..."
    
    # Create directories
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/wallpapers"
    
    # Copy config directories
    cp -r "$DOTFILES_DIR/.config/hypr" "$HOME/.config/"
    cp -r "$DOTFILES_DIR/.config/quickshell" "$HOME/.config/"
    cp -r "$DOTFILES_DIR/.config/rofi" "$HOME/.config/"
    cp -r "$DOTFILES_DIR/.config/kitty" "$HOME/.config/"
    cp -r "$DOTFILES_DIR/.config/cava" "$HOME/.config/"
    
    # Copy wallpapers if they exist
    if [ -d "$DOTFILES_DIR/wallpapers" ] && [ "$(ls -A "$DOTFILES_DIR/wallpapers")" ]; then
        cp -r "$DOTFILES_DIR/wallpapers/"* "$HOME/wallpapers/"
    fi
    
    # Copy scripts
    if [ -d "$DOTFILES_DIR/scripts" ]; then
        mkdir -p "$HOME/.local/bin"
        cp -r "$DOTFILES_DIR/scripts/"* "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/"*.sh 2>/dev/null || true
    fi
    
    success "Dotfiles copied"
}

# Enable services
enable_services() {
    info "Enabling services..."
    
    # Bluetooth
    sudo systemctl enable --now bluetooth.service
    
    # PipeWire audio
    sudo systemctl enable --now pipewire.socket
    sudo systemctl enable --now pipewire-pulse.socket
    sudo systemctl enable --now wireplumber.service
    
    success "Services enabled"
}

# Setup fish shell (optional)
setup_fish() {
    if command -v fish &> /dev/null; then
        info "Setting up fish shell..."
        
        # Set fish as default shell (uncomment if desired)
        # chsh -s $(which fish)
        
        # Install Fisher (fish plugin manager)
        fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
        
        # Install plugins
        fish -c "fisher install ilancosman/tide@v5"
        
        success "Fish shell configured"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Hyprland Rice Installation Complete!            ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}What's next:${NC}"
    echo ""
    echo "  1. Set a wallpaper:"
    echo "     ~/.local/bin/wallpaper.sh"
    echo ""
    echo "  2. Start Hyprland:"
    echo "     Hyprland"
    echo ""
    echo "  3. Keybindings (Super = Meta/Super key):"
    echo "     Super + Enter     - Open terminal"
    echo "     Super + D         - Application launcher"
    echo "     Super + Q         - Close window"
    echo "     Super + 1-9       - Switch workspace"
    echo "     Super + Shift + 1-9 - Move window to workspace"
    echo "     Print Screen      - Screenshot"
    echo ""
    echo -e "${YELLOW}Note:${NC} You may need to log out and back in for all changes to take effect."
    echo ""
}

# Main installation
main() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║             Hyprland Rice - Auto Installer                ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_distro
    install_yay
    install_packages
    backup_dotfiles
    copy_dotfiles
    enable_services
    setup_fish
    print_summary
}

# Run main
main
