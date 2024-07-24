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
    log "Performing cleanup tasks..."
    # Add your cleanup commands here
    success "Cleanup completed."
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

###############################################################################
# Linuxbrew Packages
###############################################################################

# Define the packages to be installed
packages=(
    gcc
    make
    git
    ripgrep
    fd
    eza
    bat
    duf
    dust
    tldr
    procs
    zoxide
    unzip
    neovim
    shfmt
    shellcheck
    direnv
    k3d
    kubectl
    helm
    k9s
)

log "Updating linuxbrew..."
brew update

log "Upgrading linuxbrew..."
brew upgrade

log "Starting package installation..."

# Install all packages at once
if brew install "${packages[@]}"; then
    success "Successfully installed all packages: ${packages[*]}"
else
    error "Failed to install one or more packages: ${packages[*]}"
fi

success "All packages have been installed successfully."
