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
# Replace systemd-resolved with BIND9 as local DNS server
###############################################################################

log "Disabling and stopping systemd-resolved service..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
success "systemd-resolved stopped and disabled."

log "Removing /etc/resolv.conf symlink..."
sudo rm -f /etc/resolv.conf
success "/etc/resolv.conf symlink removed."

log "Installing BIND9..."
sudo apt update
sudo apt install -y bind9 bind9utils bind9-doc
success "BIND9 installed."

log "Configuring BIND9..."
BIND_OPTIONS_CONF="/etc/bind/named.conf.options"
if [[ -f "$BIND_OPTIONS_CONF" ]]; then
    log "Backing up existing named.conf.options..."
    sudo cp "$BIND_OPTIONS_CONF" "$BIND_OPTIONS_CONF.bak"
fi

sudo bash -c "cat > $BIND_OPTIONS_CONF << EOF
options {
    directory \"/var/cache/bind\";

    recursion yes;                 # enables recursive queries
    allow-recursion { any; };      # allows recursive queries from any IP address
    listen-on { any; };            # accepts DNS queries on all available interfaces
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    dnssec-validation auto;

    auth-nxdomain no;    # conform to RFC1035
    listen-on-v6 { any; };
};
EOF"
success "BIND9 configuration updated."

log "Creating /etc/resolv.conf with localhost as nameserver..."
sudo bash -c "cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
EOF"
success "/etc/resolv.conf created."

log "Restarting BIND9 service..."
sudo systemctl restart named
success "BIND9 service restarted."

log "Enabling BIND9 service to start on boot..."
sudo systemctl enable named
success "BIND9 service enabled to start on boot."

#------------------------------------------------------------------------------
# Update wsl.conf
#------------------------------------------------------------------------------

log "Updating /etc/wsl.conf..."
WSL_CONF="/etc/wsl.conf"
if [[ -f "$WSL_CONF" ]]; then
    log "Backing up existing wsl.conf..."
    sudo cp "$WSL_CONF" "$WSL_CONF.bak"
fi

sudo bash -c "cat > $WSL_CONF << EOF
[boot]
systemd=true

[network]
generateResolvConf = false
generateHosts = true
EOF"
success "wsl.conf updated."

#------------------------------------------------------------------------------
# Verify BIND9 configuration
#------------------------------------------------------------------------------

log "Verifying BIND9 DNS resolution..."
if dig @127.0.0.1 example.com | grep -q "NOERROR"; then
    success "DNS resolution with BIND9 verified successfully."
else
    error "DNS resolution with BIND9 failed."
fi

#------------------------------------------------------------------------------
# Final message
#------------------------------------------------------------------------------

success "systemd-resolved replaced with BIND9 as local DNS server successfully."
