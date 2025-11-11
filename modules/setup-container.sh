#!/usr/bin/env bash

################################################################################
# Container Setup Module
# Creates and configures the development container with proper access
################################################################################

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/modules/common.sh"

setup_container() {
    log_step "Setting up development container..."

    # Check if container already exists
    if distrobox list 2>/dev/null | grep -q "^$CONTAINER_NAME"; then
        log "Container '$CONTAINER_NAME' already exists"

        # Verify it's accessible
        if distrobox enter "$CONTAINER_NAME" -- echo "test" &> /dev/null 2>&1; then
            log_success "Container is accessible"
            record_tool_status "container" "success" "existing"
            return 0
        else
            log_warn "Container exists but not accessible, recreating..."
            distrobox rm "$CONTAINER_NAME" --force &> /dev/null || true
        fi
    fi

    log "Creating container '$CONTAINER_NAME'..."

    # Create container with podman socket access for Docker/Podman support
    local create_cmd="distrobox create \
        --name '$CONTAINER_NAME' \
        --image '$CONTAINER_IMAGE' \
        --volume /run/user/\$UID/podman:/run/user/\$UID/podman:rw \
        --yes"

    if try_with_retry "$create_cmd" "Container creation"; then
        log_success "Container '$CONTAINER_NAME' created with podman socket access"
        record_tool_status "container" "success" "new"

        # Wait for container to be fully ready
        sleep 2

        # Verify container is actually working
        if ! distrobox enter "$CONTAINER_NAME" -- echo "Container ready" &> /dev/null; then
            log_error "Container created but not accessible"
            record_tool_status "container" "failed" "N/A" "Container not accessible after creation"
            return 1
        fi

        return 0
    else
        log_error "Failed to create container"
        record_tool_status "container" "failed" "N/A" "Creation failed after retries"
        RECOVERY_ACTIONS["container"]="Try manually: distrobox create --name $CONTAINER_NAME --image $CONTAINER_IMAGE"
        return 1
    fi
}

install_container_dependencies() {
    log_step "Installing container dependencies..."

    local install_script='
        set -e
        export DEBIAN_FRONTEND=noninteractive

        # Update package lists
        echo "Updating package lists..."
        apt-get update -qq

        # Install essential packages
        echo "Installing essential packages..."
        apt-get install -y -qq --no-install-recommends \
            curl \
            wget \
            git \
            build-essential \
            ca-certificates \
            unzip \
            zip \
            gnupg \
            lsb-release \
            software-properties-common \
            apt-transport-https \
            python3 \
            python3-pip \
            python3-venv \
            procps \
            psmisc

        echo "Dependencies installed successfully"
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_script" >> "$LOG_FILE" 2>&1; then
        log_success "Container dependencies installed"
        record_tool_status "dependencies" "success" "installed"
        return 0
    else
        log_error "Failed to install container dependencies"
        record_tool_status "dependencies" "failed" "N/A" "apt-get install failed"
        RECOVERY_ACTIONS["dependencies"]="Enter container and run: sudo apt-get update && sudo apt-get install -y curl wget git build-essential"
        return 1
    fi
}

# Export functions
export -f setup_container install_container_dependencies
