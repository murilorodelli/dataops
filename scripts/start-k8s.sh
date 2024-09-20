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

# OLM Version
OLM_VERSION="${OLM_VERSION:-v0.28.0}"

# Error flag
error_occurred=false

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT

    # Clean up the temporary file
    if [[ -n "${tmpfile:-}" && -f "$tmpfile" ]]; then
        rm -f "$tmpfile"
        log "Temporary file $tmpfile deleted."
    fi

    # Perform k3d cleanup only if an error occurred
    if [[ "$error_occurred" = true ]]; then
        log "Performing cleanup tasks..."
        if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
            log "Removing existing k3d cluster '${CLUSTER_NAME}'..."
            k3d cluster delete "$CLUSTER_NAME" || error "Failed to delete existing k3d cluster."
            success "Existing k3d cluster '${CLUSTER_NAME}' removed."
        fi
    fi

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
    error_occurred=true
    exit 1
}

# Check for required dependencies
for cmd in curl k3d mktemp kubectl helm; do
    if ! command -v "$cmd" &>/dev/null; then
        error "$cmd could not be found. Please install $cmd and try again."
    fi
done

# Get the directory of the script
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
log "Script directory: $script_dir"

# Check if the script is running as sudo
if [[ "$EUID" -eq 0 ]]; then
    error "Please don't run this script as root or with sudo."
fi

# Get the interactive user
interactive_user="${SUDO_USER:-$USER}"
log "Script is running as $interactive_user without superuser privileges."

# Get the home directory of the interactive user
home_dir=$(getent passwd "$interactive_user" | cut -d: -f6)
if [[ -z "$home_dir" ]]; then
    error "Could not determine the home directory of the interactive user."
fi

###############################################################################
# Start K3D cluster
###############################################################################

CLUSTER_NAME="${CLUSTER_NAME:-local}"
CONF_DIR="${CONF_DIR:-$script_dir/../conf}"

if [[ ! -d "$CONF_DIR" ]]; then
    error "Config directory $CONF_DIR not found."
fi

# Ensure the data and registry directories exist
mkdir -p "${home_dir}/.k3d/data" "${home_dir}/.k3d/registry"

log "Checking for existing k3d cluster..."
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    log "Existing k3d cluster '$CLUSTER_NAME' found. Deleting..."
    k3d cluster delete "$CLUSTER_NAME" || error "Failed to delete existing k3d cluster."
    success "Existing k3d cluster '$CLUSTER_NAME' deleted."
fi

log "Creating k3d cluster '$CLUSTER_NAME'..."
k3d cluster create "$CLUSTER_NAME" --config "$CONF_DIR/k3d/config.yaml" || error "Failed to create k3d cluster '$CLUSTER_NAME'."
success "Cluster '$CLUSTER_NAME' created successfully."

###############################################################################
# Install Operator Lifecycle Manager (OLM)
###############################################################################

log "Installing Operator Lifecycle Manager (OLM) version $OLM_VERSION..."

# Create a temporary file to hold the install script
tmpfile=$(mktemp) || error "Failed to create temporary file."

# Fetch the install script and run it
install_script_url="https://github.com/operator-framework/operator-lifecycle-manager/releases/download/$OLM_VERSION/install.sh"
if curl -sL "$install_script_url" -o "$tmpfile"; then
    if bash "$tmpfile" "$OLM_VERSION"; then
        success "OLM version $OLM_VERSION installed successfully."
    else
        error "Failed to install OLM version $OLM_VERSION."
    fi
else
    error "Failed to download OLM install script from $install_script_url."
fi

###############################################################################
# Install Strimzi Kafka Operator
###############################################################################

log "Installing Strimzi Kafka Operator..."

if kubectl create -f https://operatorhub.io/install/strimzi-kafka-operator.yaml; then
    success "Strimzi Kafka Operator installed successfully."
else
    error "Failed to install Strimzi Kafka Operator."
fi

###############################################################################
# Install Apicurio Registry Operator
###############################################################################

# log "Installing Apicurio Registry Operator..."

# if kubectl create -f https://operatorhub.io/install/apicurio-registry.yaml; then
#     success "Apicurio Registry Operator installed successfully."
# else
#     error "Failed to install Apicurio Registry Operator."
# fi

###############################################################################
# Install Cert Manager Operator
###############################################################################

# log "Installing Cert Manager Operator..."

# if kubectl create -f https://operatorhub.io/install/cert-manager.yaml; then
#     success "Cert Manager Operator installed successfully."
# else
#     error "Failed to install Cert Manager Operator."
# fi

##############################################################################
# Install Flink Operator
##############################################################################

log "Installing Flink Operator..."

if kubectl create -f https://operatorhub.io/install/alpha/flink-kubernetes-operator.yaml; then
    success "Flink Operator installed successfully."
else
    error "Failed to install Flink Operator."
fi

###############################################################################
# Install Ingress NGINX
###############################################################################

log "Installing Ingress NGINX using Helm..."

helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx --create-namespace \
    --set controller.enableSSLPassthrough=true ||
    echo "Failed to install Ingress NGINX."

success "Ingress NGINX installed successfully."
