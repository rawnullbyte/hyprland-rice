# Apply Pywal colors to the current terminal session
(cat ~/.cache/wal/sequences &)

# Source the color variables for scripts/Starship
source ~/.cache/wal/colors.sh

# Initialize Starship (This will now finally show up!)
eval "$(starship init zsh)"

# Fastfetch on startup
fastfetch --config hypr