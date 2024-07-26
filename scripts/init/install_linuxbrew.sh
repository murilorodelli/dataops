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
# Uninstall existing Homebrew (if any) and install it to ~/.linuxbrew
###############################################################################

# Check for required dependencies
command -v curl >/dev/null 2>&1 || error "curl is required but not installed."
command -v sed >/dev/null 2>&1 || error "sed is required but not installed."

# Define the Linuxbrew installation directory
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$HOME/.linuxbrew}"
DEFAULT_HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
OTHER_COMMON_PREFIXES=("$HOME/.linuxbrew" "/usr/local/Homebrew" "/opt/homebrew")

export NONINTERACTIVE=1

remove_brew_from_shell_rc() {
    local shell_rc="$1"
    if [[ -f "$shell_rc" ]]; then
        log "Removing Homebrew initialization from $shell_rc..."
        sed -i '/# Homebrew environment setup/,/# End of Homebrew setup/d' "$shell_rc"
    fi
}

add_brew_to_shell_rc() {
    local shell_rc="$1"
    log "Applying changes to shell configuration files if they exist..."
    if [[ -f "$shell_rc" ]]; then
        remove_brew_from_shell_rc "$shell_rc"
        log "Adding Homebrew initialization to $shell_rc..."
        {
            echo "# Homebrew environment setup"
            echo "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\""
            echo "# End of Homebrew setup"
        } >>"$shell_rc"
    fi
    # shellcheck source=/dev/null
    source "$shell_rc"
}

find_brew_prefix() {
    for prefix in "$HOMEBREW_PREFIX" "$DEFAULT_HOMEBREW_PREFIX" "${OTHER_COMMON_PREFIXES[@]}"; do
        if [[ -x "$prefix/bin/brew" ]]; then
            echo "$prefix"
            return 0
        fi
    done
    return 1
}

run_brew_doctor_excluding_checks() {
    local brew_prefix="$1"
    local excluded_checks=("check_homebrew_prefix" "check_cask_quarantine_support" "check_cask_software_versions")
    local all_checks
    all_checks=$("$brew_prefix/bin/brew" doctor --list-checks)

    local checks_to_run=()
    for check in $all_checks; do
        if [[ ! ${excluded_checks[*]} =~ $check ]]; then
            checks_to_run+=("$check")
        fi
    done

    # Apply the Linuxbrew environment
    eval $("${brew_prefix}/bin/brew shellenv")

    if "$brew_prefix/bin/brew" doctor "${checks_to_run[@]}"; then
        return 0
    else
        return 1
    fi
}

#--------------------------------------------------------------------------------------
# Remove
#--------------------------------------------------------------------------------------

# Uninstall existing Homebrew if it exists
brew_prefix=$(find_brew_prefix || echo "")
log "brew_prefix is: $brew_prefix"
if [[ -n "$brew_prefix" ]]; then
    log "Existing Homebrew installation detected at $brew_prefix."

    if [[ -x "$brew_prefix/bin/brew" ]]; then
        log "Running 'brew doctor' excluding specific checks to determine the installation status..."
        if run_brew_doctor_excluding_checks "$brew_prefix"; then
            success "Homebrew is properly installed and working well (except for specified warnings). Skipping uninstallation."
            # Set up environment for Homebrew
            log "Updating shell configuration files to include Homebrew..."
            add_brew_to_shell_rc "$HOME/.profile"
            add_brew_to_shell_rc "$HOME/.bashrc"
            add_brew_to_shell_rc "$HOME/.zshrc"
            exit 0
        else
            log "Issues detected with Homebrew installation. Proceeding with uninstall..."

            # Download Homebrew removal script
            log "Downloading Homebrew removal script..."
            curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh -o brew_removal.sh || error "Failed to download Homebrew removal script"

            log "Running removal script with HOMEBREW_PREFIX set to $brew_prefix..."
            if HOMEBREW_PREFIX="$brew_prefix" /bin/bash brew_removal.sh; then
                success "Successfully uninstalled Homebrew."
            else
                error "Failed to uninstall Homebrew."
            fi
        fi
    else
        log "Homebrew binary not found. Removing directories manually..."
        rm -rf "$brew_prefix"
        success "Successfully removed Homebrew directories."
    fi
else
    log "No existing Homebrew installation detected. Skipping uninstallation."
fi

# Remove existing Homebrew directories if they still exist
log "Removing existing Homebrew directories..."
if [[ -d "$DEFAULT_HOMEBREW_PREFIX" || -d "$HOMEBREW_PREFIX" || -d "$brew_prefix" ]]; then
    rm -rf "$HOMEBREW_PREFIX" "$DEFAULT_HOMEBREW_PREFIX" "$brew_prefix"
fi

# Remove Homebrew initialization from shell configuration files
remove_brew_from_shell_rc "$HOME/.profile"
remove_brew_from_shell_rc "$HOME/.bashrc"
remove_brew_from_shell_rc "$HOME/.zshrc"

log "Uninstall complete. Proceeding to reinstallation."

#--------------------------------------------------------------------------------------
# Install
#--------------------------------------------------------------------------------------

# Get the interactive user
if [[ -n "${SUDO_USER-}" ]]; then
    interactive_user="$SUDO_USER"
else
    interactive_user="$USER"
fi

# Create the necessary directory structure and set correct permissions
log "Creating necessary directory structure and setting correct permissions..."
mkdir -p "$HOMEBREW_PREFIX"
chown -R "$interactive_user" "$HOMEBREW_PREFIX"

# Download and modify Homebrew installation script
log "Downloading Homebrew installation script..."
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o brew_install.sh || error "Failed to download installation script"

log "Modifying installation script to set HOMEBREW_PREFIX..."
sed -i "s#$DEFAULT_HOMEBREW_PREFIX#$HOMEBREW_PREFIX#g" brew_install.sh || error "Failed to modify installation script"

# Install Homebrew
log "Running Homebrew installation script..."
if /bin/bash brew_install.sh; then
    success "Successfully installed Homebrew to $HOMEBREW_PREFIX."
else
    error "Failed to install Homebrew."
fi

# Set up environment for Homebrew
log "Updating shell configuration files to include Homebrew..."
add_brew_to_shell_rc "$HOME/.profile"
add_brew_to_shell_rc "$HOME/.bashrc"
add_brew_to_shell_rc "$HOME/.zshrc"

# Verify installation and suppress warning
log "Running 'brew doctor' excluding specific checks to determine the installation status..."
if run_brew_doctor_excluding_checks "$HOMEBREW_PREFIX"; then
    success "Your system is ready to brew (with custom HOMEBREW_PREFIX)."
else
    error "There was an issue with the Homebrew installation"
fi
