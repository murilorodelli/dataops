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
# Docker installation
###############################################################################

# Get the interactive user
if [[ -n "${SUDO_USER-}" ]]; then
    interactive_user="$SUDO_USER"
else
    interactive_user="$USER"
fi

# Remove incompatible packages
log "Removing incompatible packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        sudo apt-get remove --assume-yes --quiet --autoremove "$pkg" || error "Failed to remove $pkg"
    fi
done

docker_url="https://download.docker.com/linux/ubuntu"

# Add
log "Adding ca-certificates..."
sudo apt-get update --assume-yes --quiet || error "Failed to update package list"
sudo apt-get install --assume-yes --quiet --no-install-recommends ca-certificates || error "Failed to install required packages"
sudo install -m 0755 -d /etc/apt/keyrings || error "Failed to create keyrings directory"

# Add Docker's official GPG key
log "Adding Docker's official GPG key..."
sudo curl -fsSL "$docker_url/gpg" -o /etc/apt/keyrings/docker.asc || error "Failed to download Docker's GPG key"
sudo chmod a+r /etc/apt/keyrings/docker.asc || error "Failed to set permissions on Docker's GPG key"

# Add the repository to Apt sources
log "Adding Docker's repository to Apt sources..."
arch=$(dpkg --print-architecture)
release=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.asc] $docker_url $release stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null || error "Failed to add Docker repository"
sudo apt-get update --assume-yes --quiet || error "Failed to update package list"

# Install the latest version of Docker
log "Installing the latest version of Docker..."
sudo apt-get install --assume-yes --quiet --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || error "Failed to install Docker"

# Add user to the Docker group
log "Adding user to the Docker group..."
if ! getent group docker >/dev/null; then
    sudo groupadd docker || error "Failed to create Docker group"
fi
sudo usermod -aG docker "$interactive_user" || error "Failed to add user to Docker group"

# Inform the user about the need to log out and back in
log "Please log out and back in or restart your session to apply Docker group membership changes."

# Verify installation
log "Verifying Docker installation..."
if ! sudo docker run hello-world; then
    error "Failed to run hello-world Docker container"
fi

success "Docker installation completed successfully."

# Prune unused Docker resources
log "Pruning unused Docker resources..."
docker system prune -af --volumes || error "Failed to prune Docker resources"

success "Pruning of Docker resources completed."
