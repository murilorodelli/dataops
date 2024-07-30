#!/usr/bin/env bash

# Best recommended set options
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define Nerd Font icons
INFO_ICON=""
SUCCESS_ICON=""
ERROR_ICON=""
ARROW_ICON=""

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    # Perform script cleanup here
    # Example: remove temporary files, restore system state, etc.
    # log "Performing cleanup tasks..."
    # Add your cleanup commands here
    # success "Cleanup completed."
}

log() {
    printf "${BLUE}${INFO_ICON}${NC} %s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

success() {
    printf "${GREEN}${SUCCESS_ICON}${NC} %s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

error() {
    printf "${RED}${ERROR_ICON}${NC} %s - ERROR: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >&2
    exit 1
}

# Get the directory of the script
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
log "Script directory: $script_dir"

# Check if the script is running as sudo
if [[ "$EUID" -eq 0 ]]; then
    error "Please don't run this script as root or with sudo."
fi

# Get the interactive user
if [[ -n "${SUDO_USER-}" ]]; then
    interactive_user="$SUDO_USER"
else
    interactive_user="$USER"
fi

log "Script is running as $interactive_user without superuser privileges."

HOME_DIR=$(eval echo "~$interactive_user")
log "Applying changes to home directory of user $interactive_user: $HOME_DIR"

###############################################################################
# Install zsh
###############################################################################
log "Installing Zsh..."

# Install zsh
if sudo apt-get install --assume-yes --quiet --no-install-recommends zsh; then
    success "Successfully installed all packages: zsh"
else
    error "Failed to install one or more packages: zsh"
fi

# Check if Zsh is installed
if ! command -v zsh &>/dev/null; then
    error "Zsh installation failed."
else
    success "Zsh installed successfully."
fi

###############################################################################
# Install Oh My Zsh
###############################################################################
log "Installing Oh My Zsh..."
if [ -d "$HOME_DIR/.oh-my-zsh" ]; then
    log "Oh My Zsh is already installed."
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Check if Oh My Zsh installation succeeded
if [ -d "$HOME_DIR/.oh-my-zsh" ]; then
    success "Oh My Zsh installed successfully."
else
    error "Oh My Zsh installation failed."
fi

###############################################################################
# Install plugins and configure .zshrc
###############################################################################
log "Setting up plugins and configuring .zshrc..."

# Install plugins
plugins_dir="$HOME_DIR/.oh-my-zsh/custom/plugins"
mkdir -p "$plugins_dir"

# Clone zsh-autosuggestions plugin
if [ -d "$plugins_dir/zsh-autosuggestions" ]; then
    log "zsh-autosuggestions is already installed."
else
    git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
fi

# Clone zsh-syntax-highlighting plugin
if [ -d "$plugins_dir/zsh-syntax-highlighting" ]; then
    log "zsh-syntax-highlighting is already installed."
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"
fi

# Configure .zshrc
cat <<EOL >"$HOME_DIR/.zshrc"
# Path to your oh-my-zsh installation.
export ZSH="\$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Enable plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source \$ZSH/oh-my-zsh.sh
EOL

# Apply new .zshrc configuration
log "Please start a new Zsh session to apply the .zshrc configuration. You can do this by running 'zsh'."

success "Zsh and Oh My Zsh setup completed successfully!"
