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
if [[ "$EUID" -ne 0 ]]; then
    error "Please run this script as root or with sudo."
fi

log "Script is running with superuser privileges."

###############################################################################
# System Packages
###############################################################################

# Update package list

log "Updating package list..."
sudo apt-get update --assume-yes --quiet || error "Failed to update package list"
log "Package list has been updated successfully."

log "Upgrading system packages..."
sudo apt-get full-upgrade --assume-yes --quiet || error "Failed to upgrade system packages"
log "System packages have been upgraded successfully."

# Define the packages to be installed
packages=(
    curl
    wget
    direnv
    shellcheck
    shfmt
    pigz
    nftables
    git
    build-essential
    bash
    bash-completion
    python3-venv
    file
    xattr
    net-tools
    procps
    mysql-client
)

log "Starting package installation..."

# Install all packages at once
if sudo apt-get install --assume-yes --quiet --no-install-recommends "${packages[@]}"; then
    success "Successfully installed all packages: ${packages[*]}"
else
    error "Failed to install one or more packages: ${packages[*]}"
fi

success "All packages have been installed successfully."
