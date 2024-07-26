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
# Call Individual Install Scripts
###############################################################################

# List of install scripts to call
install_scripts=(
    # system packages installation
    "sudo $script_dir/init/install_system_pkgs.sh"
    # call home sanitizer script first
    "$script_dir/init/home_sanitizer.sh"
    # BIND9 installation
    "sudo $script_dir/init/install_bind9.sh"
    # docker installation
    "sudo $script_dir/init/install_docker.sh"
    # homebrew installation - no sudo
    "$script_dir/init/install_linuxbrew.sh"
)

log "Starting installation of individual scripts..."

# Call each install script
for script in "${install_scripts[@]}"; do
    log "Running install script: $script"
    if eval "$script"; then
        success "Successfully ran: $script"
    else
        error "Failed to run: $script"
    fi
done

success "All install scripts have been executed successfully."

# Define the attention banner content
banner="
###############################################################################
#                                                                             #
#                             ATTENTION REQUIRED                              #
#                                                                             #
###############################################################################
#                                                                             #
# Please log out of your current terminal and session and log back in again.  #
#                                                                             #
# Instructions:                                                               #
#                                                                             #
# 1. For WSL (Windows Subsystem for Linux):                                   #
#    - Close the current terminal window.                                     #
#    - Open a new terminal window.                                            #
#                                                                             #
# 2. For native Ubuntu:                                                       #
#    - Log out of your current session:                                       #
#      Click on the system menu (top-right corner) and select 'Log Out'.      #
#    - Log back in with your user credentials.                                #
#                                                                             #
###############################################################################
"

# Print the banner
echo "$banner"
