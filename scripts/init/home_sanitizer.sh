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

# Function to add guard variable if necessary
add_guard() {
    local file=$1
    local guard_var=$2
    local temp_file

    # Check if the file exists
    if [ ! -f "$file" ]; then
        return 1
    fi

    # Check if the guard variable is already present in the file
    if ! grep -q "export $guard_var=" "$file"; then
        log "Adding guard variable in $file"
        # Create a temporary file
        temp_file=$(mktemp)

        # Add the guard variable at the top of the file
        cat <<EOL >"$temp_file"
# Guard variable to prevent multiple sourcing
if [ -n "\${$guard_var:-}" ]; then
    return 0
fi
export $guard_var=1

EOL
        cat "$file" >>"$temp_file"
        mv "$temp_file" "$file" || error "Failed to add guard variable in $file"
    fi
    return 0
}

# Function to source a file if necessary
add_source() {
    local file=$1
    local source_file=$2
    local source_guard=${3:-SOURCE_GUARD}
    local temp_file

    log "Checking if $file exists"
    # Check if the file exists
    if [ ! -f "$file" ]; then
        log "File $file does not exist"
        return 1
    fi

    # Replace $HOME_DIR with '$HOME' in source_file
    local source_file_replaced="${source_file/#$HOME_DIR/\$HOME}"

    # Simplify the check to see if the source command is already present
    log "Checking if $source_file_replaced is already sourced in $file"
    if grep -qF "$source_file_replaced" "$file"; then
        log "Source $source_file_replaced already present in $file"
    else
        log "Adding source $source_file_replaced in $file"
        # Create a temporary file
        temp_file=$(mktemp)

        # Add the source command at the top of the file
        cat <<EOL >"$temp_file"
if [ -z "\${$source_guard:-}" ] && [ -f "$source_file_replaced" ]; then
    . "$source_file_replaced"
fi

EOL
        cat "$file" >>"$temp_file"
        mv "$temp_file" "$file" || error "Failed to add source $source_file_replaced in $file"
    fi
    return 0
}

update_shell_rc() {
    local profile_file="$HOME_DIR/.profile"
    local profile_guard="PROFILE_SOURCED"

    # Ensure the guard is added to .profile as well
    add_guard "$profile_file" "$profile_guard"

    # List of files to update
    files_to_update=(
        "$HOME_DIR/.bash_profile"
        "$HOME_DIR/.bash_login"
        "$HOME_DIR/.bashrc"
        "$HOME_DIR/.zprofile"
        "$HOME_DIR/.zlogin"
        "$HOME_DIR/.zshrc"
        "$HOME_DIR/.xprofile"
        "$HOME_DIR/.xinitrc"
        "$HOME_DIR/.kshrc"
        "$HOME_DIR/.mkshrc"
        "$HOME_DIR/.cshrc"
        "$HOME_DIR/.tcshrc"
    )

    # Corresponding guard variables for each file
    guard_vars=(
        "BASHPROFILE_SOURCED"
        "BASHLOGIN_SOURCED"
        "BASHRC_SOURCED"
        "ZPROFILE_SOURCED"
        "ZLOGIN_SOURCED"
        "ZSHRC_SOURCED"
        "XPROFILE_SOURCED"
        "XINITRC_SOURCED"
        "KSHRC_SOURCED"
        "MKSHRC_SOURCED"
        "CSHRC_SOURCED"
        "TCSHRC_SOURCED"
    )

    # Loop through each file and add the source and guard if file exists
    for i in "${!files_to_update[@]}"; do
        if [ -f "${files_to_update[$i]}" ]; then
            add_source "${files_to_update[$i]}" "$profile_file" "$profile_guard" || error "Failed to add source $profile_file to ${files_to_update[$i]}"
            add_guard "${files_to_update[$i]}" "${guard_vars[$i]}" || error "Failed to add guard to ${files_to_update[$i]}"
        fi
    done

    echo "source /etc/bash_completion" >> "$HOME_DIR/.bashrc"
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

update_shell_rc

success "Comprehensive home directory cleanup and fixes completed."
