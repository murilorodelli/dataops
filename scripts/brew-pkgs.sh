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
# Install packages
###############################################################################

# Define the packages to be installed
packages=(
    gcc
    openssl
    unzip
    curl
    wget
    git
    cmake
    make
    m4
    bison
    mandoc
    sqlite
    util-linux
    luarocks
    ripgrep
    fd
    fzf
    eza
    bat
    duf
    dust
    tldr
    procs
    zoxide
    neovim
    lazygit
    shfmt
    shellcheck
    direnv
    k3d
    kubectl
    kubectx
    krew
    kustomize
    helm
    popeye
    kubescape
    kubeconform
    k9s
    minio-mc
    jq
)

log "Updating linuxbrew..."
brew update

log "Upgrading linuxbrew..."
brew upgrade

log "Starting package installation..."

# Install each package one by one
for package in "${packages[@]}"; do
    if brew install "$package"; then
        success "Successfully installed $package"
    else
        error "Failed to install $package"
    fi
done

# Configuration file for bash
BASH_CONFIG_FILE="$HOME/.bash_profile"

# Shell completion commands for bash
COMPLETIONS=(
    'eval "$(direnv hook bash)"'
    'source <(kubectl completion bash)'
    'source <(helm completion bash)'
    'source <(rg --generate=complete-bash)'
)

# Add shell completion commands to the bash config file
echo "Adding shell completion commands to $BASH_CONFIG_FILE..."

# Ensure the configuration file exists
touch "$BASH_CONFIG_FILE"

# Add completions if they are not already present in the config file
for cmd in "${COMPLETIONS[@]}"; do
    if ! grep -Fq "$cmd" "$BASH_CONFIG_FILE"; then
        echo "$cmd" >>"$BASH_CONFIG_FILE"
        echo "Added '$cmd' to $BASH_CONFIG_FILE"
    fi
done

success "All packages and completions have been set up successfully."
