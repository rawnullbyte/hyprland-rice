export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Apply Pywal colors to the current terminal session
(cat ~/.cache/wal/sequences &)

# Source the color variables for scripts/Starship
source ~/.cache/wal/colors.sh

# Initialize Starship (This will now finally show up!)
eval "$(starship init zsh)"

# Fastfetch on startup
fastfetch --config hypr

# terminal-wakatime setup
export PATH="$HOME/.wakatime:$PATH"
eval "$(terminal-wakatime init)"