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
    sudo rm -f add_record.txt remove_record.txt
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


#------------------------------------------------------------------------------
# Install BIND9
#------------------------------------------------------------------------------

log "Installing BIND9..."
sudo apt update
sudo apt install -y bind9 bind9-utils bind9-doc bind9-host bind9-dnsutils dnsutils mmdb-bin
success "BIND9 installed."

log "Configuring BIND9..."
BIND_OPTIONS_CONF="/etc/bind/named.conf.options"

sudo tee "$BIND_OPTIONS_CONF" >/dev/null <<EOF
options {
    directory "/var/cache/bind";

    recursion yes;
    allow-recursion { any; };
    listen-on { any; };
    forwarders {
        8.8.8.8;
        8.8.4.4;
        1.1.1.1;
        1.0.0.1;
    };
    dnssec-validation auto;

    auth-nxdomain no;
    listen-on-v6 { any; };
};
EOF
success "BIND9 configuration updated."

# Get primary network interface IP address
PRIMARY_IFACE_IP=$(ip -4 addr show "$(ip route | grep default | awk '{print $5}')" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
log "Primary network interface IP: $PRIMARY_IFACE_IP"

ZONE_FILE="/etc/bind/db.k8s.local"
sudo tee "$ZONE_FILE" >/dev/null <<EOF
;
; BIND reverse data file for k8s.local zone
;
\$TTL 60
@       IN      SOA     k8s.local. root.k8s.local. (
                          2024072401 ; Serial
                          60         ; Refresh
                          60         ; Retry
                          2419200    ; Expire
                          60 )       ; Minimum

        IN      NS      ns.k8s.local.

; A record for the domain itself
k8s.local.      IN      A       $PRIMARY_IFACE_IP

; A record for the name server
ns              IN      A       $PRIMARY_IFACE_IP

; Additional A records
; api             IN      A       $PRIMARY_IFACE_IP
; web             IN      A       $PRIMARY_IFACE_IP

; CNAME records
; www             IN      CNAME   web.k8s.local.
EOF
success "Zone file for k8s.local created with ns record IP: $PRIMARY_IFACE_IP"

NAMED_CONF_LOCAL="/etc/bind/named.conf.local"

# Define variables for file paths and TSIG details
TSIG_KEY_NAME="externaldns-key"
TSIG_ALGORITHM="hmac-sha256"
TSIG_SECRET=$(tsig-keygen -a "$TSIG_ALGORITHM" "$TSIG_KEY_NAME" | awk '/secret/{print $2}' | tr -d '";')
TSIG_KEY_FILE="/etc/bind/k8s.local.key"
ZONE_FILE="/etc/bind/db.k8s.local"
NAMED_CONF_LOCAL="/etc/bind/named.conf.local"

# Generate the TSIG key file
sudo tee "$TSIG_KEY_FILE" >/dev/null <<EOF
key "$TSIG_KEY_NAME" {
    algorithm $TSIG_ALGORITHM;
    secret "$TSIG_SECRET";
};
EOF

# Update the named.conf.local file
log "Update the $NAMED_CONF_LOCAL file"
# Remove existing k8s.local zone and TSIG key block if it exists
sudo sed -i '/include "\/etc\/bind\/k8s.local.key"/,/^};/d' "$NAMED_CONF_LOCAL"

# Add the new include directive and zone configuration
sudo tee -a "$NAMED_CONF_LOCAL" >/dev/null <<EOF
include "$TSIG_KEY_FILE";

zone "k8s.local" {
    type master;
    file "$ZONE_FILE";
    allow-transfer { key "$TSIG_KEY_NAME"; };
    update-policy { grant "$TSIG_KEY_NAME" zonesub ANY; };
};
EOF

success "TSIG key and zone configuration added to $NAMED_CONF_LOCAL."

# Set permissions for TSIG key file and other necessary files
log "Setting permissions for BIND files..."

# Set ownership for all files in /etc/bind to the bind user and group
sudo chown -R bind:bind /etc/bind

# Set specific permissions for directories and files
sudo find /etc/bind -type d -exec chmod 775 {} \; # Directories writable by the group
sudo find /etc/bind -type f -exec chmod 644 {} \; # Files readable by all, writable by owner

# Ensure critical files have the correct permissions
sudo chown bind:bind /etc/bind/named.conf /etc/bind/named.conf.local /etc/bind/named.conf.options /etc/bind/k8s.local.key
sudo chmod 644 /etc/bind/named.conf /etc/bind/named.conf.local /etc/bind/named.conf.options /etc/bind/k8s.local.key

# Specific permissions for the zone file to allow updates
sudo chmod 664 /etc/bind/db.k8s.local

success "Permissions for BIND files set."


#------------------------------------------------------------------------------
# Update wsl.conf
#------------------------------------------------------------------------------

log "Updating /etc/wsl.conf..."
WSL_CONF="/etc/wsl.conf"

sudo tee "$WSL_CONF" >/dev/null <<EOF
[boot]
systemd=true

[network]
generateResolvConf = false
generateHosts = true
EOF
success "wsl.conf updated."

#------------------------------------------------------------------------------
# Disable systemd-resolved and enable bind9
#------------------------------------------------------------------------------

log "Disabling and stopping systemd-resolved service..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
success "systemd-resolved stopped and disabled."

log "Removing /etc/resolv.conf symlink..."
sudo rm -f /etc/resolv.conf
success "/etc/resolv.conf symlink removed."

#------------------------------------------------------------------------------
# Enable and start bind9 
#------------------------------------------------------------------------------

log "Creating /etc/resolv.conf with localhost as nameserver..."
sudo tee /etc/resolv.conf >/dev/null <<EOF
nameserver 127.0.0.1
EOF
success "/etc/resolv.conf created."

log "Restarting BIND9 service..."
sudo systemctl restart named
success "BIND9 service restarted."

log "Enabling BIND9 service to start on boot..."
sudo systemctl enable named
success "BIND9 service enabled to start on boot."

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
# NSUPDATE Testing - Add and Remove a Record
#------------------------------------------------------------------------------

# Define test record details
TEST_DOMAIN="test.k8s.local."
TEST_IP="192.168.1.100"

# Create a file with the nsupdate commands to add a DNS record
echo -e "server 127.0.0.1\nzone k8s.local\nupdate add $TEST_DOMAIN 60 A $TEST_IP\nsend" >add_record.txt

# Apply the nsupdate command to add the DNS record
log "Adding a test DNS record using nsupdate..."
if nsupdate -k "$TSIG_KEY_FILE" add_record.txt; then
    success "Test DNS record added successfully."
else
    error "Failed to add test DNS record."
fi

# Verify the DNS record was added
log "Verifying the added DNS record..."
if dig @127.0.0.1 $TEST_DOMAIN | grep -q "$TEST_IP"; then
    success "DNS record verification successful. Record exists."
else
    error "DNS record verification failed. Record does not exist."
fi

# Create a file with the nsupdate commands to remove the DNS record
echo -e "server 127.0.0.1\nzone k8s.local\nupdate delete $TEST_DOMAIN A\nsend" >remove_record.txt

# Apply the nsupdate command to remove the DNS record
log "Removing the test DNS record using nsupdate..."
if nsupdate -k "$TSIG_KEY_FILE" remove_record.txt; then
    success "Test DNS record removed successfully."
else
    error "Failed to remove test DNS record."
fi

# Verify the DNS record was removed
log "Verifying the removal of the DNS record..."
if ! dig @127.0.0.1 $TEST_DOMAIN | grep -q "$TEST_IP"; then
    success "DNS record removal verification successful. Record does not exist."
else
    error "DNS record removal verification failed. Record still exists."
fi

#------------------------------------------------------------------------------
# Final message
#------------------------------------------------------------------------------

log "BIND9 setup script completed."
