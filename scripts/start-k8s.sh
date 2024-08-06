#!/usr/bin/env bash

# Best recommended set options
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR

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
    trap - SIGINT SIGTERM ERR

    # Cleanup commands
    log "Performing cleanup tasks..."
    if k3d cluster list | grep -q 'local'; then
        log "Removing existing k3d cluster 'local'..."
        k3d cluster delete local || error "Failed to delete existing k3d cluster."
        success "Existing k3d cluster 'local' removed."
    fi
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

# Get the home directory of the interactive user
home_dir=$(getent passwd "$interactive_user" | cut -d: -f6)
if [[ -z "$home_dir" ]]; then
    error "Could not determine the home directory of the interactive user."
fi

###############################################################################
# Start K3D cluster
###############################################################################

conf_dir="$script_dir/../conf"
if [[ ! -d "$conf_dir" ]]; then
    error "Could not determine the config directory of k3d."
fi

# Ensure the data and registry directories exist
mkdir -p "${home_dir}"/.k3d/{data,registry}

log "Checking for existing k3d cluster..."
if k3d cluster list | grep -q 'local'; then
    log "Existing k3d cluster 'local' found. Deleting..."
    k3d cluster delete local || error "Failed to delete existing k3d cluster."
    success "Existing k3d cluster 'local' deleted."
fi

log "Creating k3d cluster 'local'..."
k3d cluster create local --config "$conf_dir/k3d/config.yaml" --verbose || error "Failed to create k3d cluster 'local'."
success "Cluster 'local' created successfully."
