#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define Nerd Font icons
INFO_ICON=""
SUCCESS_ICON=""
ERROR_ICON=""

# Error flag to determine whether cleanup actions are necessary
error_occurred=false

# Create a temporary file for the certificate using mktemp
cert_output_file=$(mktemp /tmp/k8s-local-cert.XXXXXX)

# Cleanup function, executed upon script exit or error
cleanup() {
    trap - SIGINT SIGTERM ERR EXIT

    # Clean up the temporary certificate file
    if [[ -n "${cert_output_file:-}" && -f "$cert_output_file" ]]; then
        rm -f "$cert_output_file"
        log "Temporary file $cert_output_file deleted."
    fi

    # Perform additional cleanup tasks if an error occurred
    if [[ "$error_occurred" = true ]]; then
        log "Performing additional cleanup due to error..."
    fi

    success "Cleanup completed."
}

# Logging function for info messages
log() {
    printf "${BLUE}${INFO_ICON}${NC} %s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

# Logging function for success messages
success() {
    printf "${GREEN}${SUCCESS_ICON}${NC} %s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

# Logging function for error messages and sets the error flag
error() {
    printf "${RED}${ERROR_ICON}${NC} %s - ERROR: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >&2
    error_occurred=true
    exit 1
}

# Ensure required commands are available
for cmd in kubectl update-ca-certificates; do
    if ! command -v "$cmd" &>/dev/null; then
        error "$cmd could not be found. Please install $cmd and try again."
    fi
done

# Get the directory of the script for relative paths
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
log "Script directory: $script_dir"

# Prevent the script from being run as root or with sudo
if [[ "$EUID" -eq 0 ]]; then
    error "Please don't run this script as root or with sudo."
fi

# Get the current non-sudo user running the script
interactive_user="${SUDO_USER:-$USER}"
log "Script is running as $interactive_user without superuser privileges."

# Get the home directory of the current user
home_dir=$(getent passwd "$interactive_user" | cut -d: -f6)
if [[ -z "$home_dir" ]]; then
    error "Could not determine the home directory of the interactive user."
fi

###############################################################################
# Install the necessary certificates
###############################################################################

# Extract certificate from Kubernetes secret and decode into a temporary file
kubectl get secret k8s-local-cert-secret -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 --decode >"$cert_output_file"

if [[ ! -f "$cert_output_file" ]]; then
    error "Failed to extract or decode certificate from Kubernetes secret."
fi

# Ensure certificate installation requires sudo, and only use sudo if necessary
if [[ ! -w /usr/local/share/ca-certificates/ ]]; then
    log "Copying certificate to /usr/local/share/ca-certificates with sudo."
    sudo cp "$cert_output_file" /usr/local/share/ca-certificates/
    sudo update-ca-certificates
else
    log "Copying certificate to /usr/local/share/ca-certificates without sudo."
    cp "$cert_output_file" /usr/local/share/ca-certificates/
    update-ca-certificates
fi

success "Certificates installed successfully."
