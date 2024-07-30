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

###############################################################################
# Sanitize
###############################################################################

HOME_DIR=$(eval echo "~$interactive_user")
log "Applying changes to home directory of user $interactive_user: $HOME_DIR"

# Function to change ownership of all files in the home directory
chown_home_files() {
    log "Changing ownership of all files in the home directory to $interactive_user..."
    sudo chown -R "$interactive_user:$interactive_user" "$HOME_DIR" || error "Failed to change ownership of home files"
    success "Ownership of all files in the home directory changed."
}

# Function to disable UFW
disable_ufw() {
    log "Disabling UFW in WSL because it only makes things more difficult..."
    sudo ufw disable || error "Failed to disable UFW"
    success "UFW disabled."
}

# Function to fix file and folder permissions
fix_permissions() {
    log "Fixing file and folder permissions..."
    find "$HOME_DIR" -type d -exec chmod 755 {} \; || error "Failed to set permissions for directories"
    find "$HOME_DIR" -type f ! -perm -111 -exec chmod 644 {} \; || error "Failed to set permissions for files"
    find "$HOME_DIR" -type f -perm -111 -exec chmod 755 {} \; || error "Failed to set execute permissions for files"

    if [[ -d "$HOME_DIR/.ssh" ]]; then
        chmod 700 "$HOME_DIR/.ssh" || error "Failed to set permissions for .ssh directory"
        find "$HOME_DIR/.ssh" -type f -exec chmod 600 {} \; || error "Failed to set permissions for files in .ssh directory"
    fi

    success "File and folder permissions fixed."
}

# Function to clean up temporary files
clean_temp_files() {
    log "Cleaning up temporary files..."
    [[ -d "$HOME_DIR/tmp" ]] && rm -rf "$HOME_DIR/tmp/*"
    [[ -d "$HOME_DIR/.cache" ]] && rm -rf "$HOME_DIR/.cache/*"
    [[ -d "$HOME_DIR/.local/share/Trash" ]] && rm -rf "$HOME_DIR/.local/share/Trash/*"

    # Remove empty directories
    while IFS= read -r -d '' dir; do
        log "Removing empty directory: $dir"
        rm -rf "$dir" 2>/dev/null || error "Failed to remove directory: $dir"
    done < <(find "$HOME_DIR" -type d -empty -print0)

    success "Temporary files and empty directories cleaned up."
}

# Function to clean up old log files
clean_log_files() {
    log "Cleaning up old log files..."
    [[ -d "$HOME_DIR/.local/share" ]] && find "$HOME_DIR/.local/share/" -name "*.log" -type f -mtime +30 -exec rm -f {} \;
    success "Old log files cleaned up."
}

# Function to clean up old backups
clean_old_backups() {
    log "Cleaning up old backup files..."
    find "$HOME_DIR" -name "*.bak" -type f -mtime +30 -exec rm -f {} \;
    success "Old backup files cleaned up."
}

# Function to clean WSL specific files
clean_wsl_files() {
    if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
        log "Detected WSL environment. Cleaning up WSL specific files..."
        [[ -f "$HOME_DIR/.wslconfig" ]] && rm -f "$HOME_DIR/.wslconfig"
        success "WSL specific files cleaned up."
    fi
}

# Function to clean VS Code remote development files
clean_vscode_remote_files() {
    log "Cleaning up VS Code remote development files..."
    [[ -d "$HOME_DIR/.vscode-server/data/tmp" ]] && rm -rf "$HOME_DIR/.vscode-server/data/tmp/*"
    success "VS Code remote development files cleaned up."
}

# Function to clean Docker and Kubernetes files
clean_docker_k8s_files() {
    log "Cleaning up Docker and Kubernetes files..."
    [[ -d "$HOME_DIR/.kube/cache" ]] && rm -rf "$HOME_DIR/.kube/cache/*"
    [[ -d "$HOME_DIR/.docker/tmp" ]] && rm -rf "$HOME_DIR/.docker/tmp/*"
    success "Docker and Kubernetes files cleaned up."
}

# Function to clean Linuxbrew files
clean_linuxbrew_files() {
    if [[ -d "$HOME_DIR/.linuxbrew" ]]; then
        log "Cleaning up Linuxbrew files..."
        rm -rf "$HOME_DIR/.linuxbrew/Library/Taps/*"
        success "Linuxbrew files cleaned up."
    fi
}

# Function to clean cloud development environment files
clean_cloud_dev_files() {
    log "Cleaning up cloud development environment files..."
    [[ -d "$HOME_DIR/.cloudshell" ]] && rm -rf "$HOME_DIR/.cloudshell/*"
    success "Cloud development environment files cleaned up."
}

log "Starting comprehensive cleanup process..."

#disable_ufw
chown_home_files
fix_permissions

clean_temp_files
clean_log_files
clean_old_backups
clean_wsl_files
clean_vscode_remote_files
clean_docker_k8s_files
clean_linuxbrew_files
clean_cloud_dev_files

success "Comprehensive home directory cleanup and fixes completed."
