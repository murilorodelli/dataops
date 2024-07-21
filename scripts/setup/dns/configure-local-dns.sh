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
    log "Performing cleanup tasks..."
    # Add your cleanup commands here if necessary
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
if [[ "$EUID" -ne 0 ]]; then
    error "Please run this script as root or with sudo."
fi

log "Script is running with superuser privileges."

###############################################################################
# Setup 'local' domain DNS resolution with systemd-resolved
###############################################################################

log "Checking if NetworkManager is running..."
if systemctl is-active --quiet NetworkManager; then
    error "NetworkManager is running. This setup applies only to systemd-resolved."
fi

#------------------------------------------------------------------------------
# wsl.conf
#------------------------------------------------------------------------------

log "Updating /etc/wsl.conf to stop automatic generation of /etc/resolv.conf..."
WSL_CONF="/etc/wsl.conf"
if [[ -f "$WSL_CONF" ]]; then
    sudo cp "$script_dir/wsl.conf" /etc/
fi

#------------------------------------------------------------------------------
# systemd-resolved service
#------------------------------------------------------------------------------

log "Checking if systemd-resolved is running..."
if ! systemctl is-active --quiet systemd-resolved; then
    log "Starting systemd-resolved service..."
    sudo systemctl start systemd-resolved
    sudo systemctl enable systemd-resolved
    success "systemd-resolved started and enabled."
fi

#------------------------------------------------------------------------------
# systemd-resolved conf
#------------------------------------------------------------------------------

log "Updating /etc/systemd/resolved.conf to default..."
RESOLVED_CONF="/etc/systemd/resolved.conf"

if [[ -f "$RESOLVED_CONF" ]]; then
    log "Backing up existing resolved.conf..."
    sudo cp "$RESOLVED_CONF" "$RESOLVED_CONF.bak"
    sudo cp "$script_dir/resolved.conf" /etc/systemd/
fi

log "Ensuring /etc/resolv.conf points to /run/systemd/resolve/stub-resolv.conf..."
sudo rm -f /etc/resolv.conf
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

log "Ensuring /etc/systemd/resolved.conf.d/ subdirectory exists..."
RESOLVED_CONF_DIR="/etc/systemd/resolved.conf.d/"
sudo mkdir -p "$RESOLVED_CONF_DIR"

#------------------------------------------------------------------------------
# systemd-resolved dns providers
#------------------------------------------------------------------------------

log "Copying google-dns.conf to $RESOLVED_CONF_DIR..."
sudo cp "$script_dir/google-dns.conf" "$RESOLVED_CONF_DIR"

log "Copying cloudflare-dns.conf to $RESOLVED_CONF_DIR..."
sudo cp "$script_dir/cloudflare-dns.conf" "$RESOLVED_CONF_DIR"

#------------------------------------------------------------------------------
# systemd-resolved restart
#------------------------------------------------------------------------------

log "Restarting systemd-resolved service..."
sudo systemctl restart systemd-resolved

#------------------------------------------------------------------------------
# systemd-resolved verify
#------------------------------------------------------------------------------

expected_dns_servers=("8.8.8.8" "8.8.4.4" "1.1.1.1" "1.0.0.1")

log "Verifying DNS configuration..."
mapfile -t actual_dns_servers < <(resolvectl dns | sed -e 's/Global[^:]*://g' -e 's/Link[^:]*://g' -e 's/^ *//' -e '/^$/d' | awk '{gsub(/ /,"\n"); print}')

for server in "${expected_dns_servers[@]}"; do
    found=false
    for actual_server in "${actual_dns_servers[@]}"; do
        # Extract just the IP address part of the actual server
        actual_server_ip="${actual_server%%#*}"
        if [[ "$server" == "$actual_server_ip" ]]; then
            found=true
            break
        fi
    done

    if [[ "$found" == false ]]; then
        error "DNS server $server not found in systemd-resolved configuration."
    fi
done

success "DNS configuration verified successfully. All expected DNS servers are present."

#------------------------------------------------------------------------------
# Final message
#------------------------------------------------------------------------------

success "DNS resolution setup completed successfully."
