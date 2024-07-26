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

# Shell completion commands
declare -A bash_completions=(
    ["kubectl"]="source <(kubectl completion bash)"
    ["helm"]="source <(helm completion bash)"
    ["ripgrep"]="source <(rg --generate=complete-bash)"
)

declare -A zsh_completions=(
    ["kubectl"]="source <(kubectl completion zsh)"
    ["helm"]="source <(helm completion zsh)"
    ["ripgrep"]="source <(rg --generate=complete-zsh)"
)

# Configuration files for different shells
declare -A config_files=(
    ["bash"]="$HOME/.bashrc"
    ["zsh"]="$HOME/.zshrc"
)

log "Adding shell completion commands..."
for shell in "${!config_files[@]}"; do
    config_file="${config_files[$shell]}"
    if [[ -f "$config_file" ]]; then
        if [[ "$shell" == "bash" ]]; then
            # Ensure bash_completion is sourced before adding other completions
            if ! grep -Fq 'source /etc/bash_completion' "$config_file"; then
                echo 'source /etc/bash_completion' >>"$config_file"
                log "Added source /etc/bash_completion to $config_file"
            fi
        fi
        declare -n completions="${shell}_completions"
        for cmd in "${completions[@]}"; do
            if ! grep -Fq "$cmd" "$config_file"; then
                echo "$cmd" >>"$config_file"
                log "Added $cmd to $config_file"
            fi
        done
    else
        log "Configuration file $config_file does not exist."
    fi
done

success "All packages and completions have been set up successfully."
