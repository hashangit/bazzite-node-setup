#!/usr/bin/env bash

################################################################################
# Container Setup Module
# Creates and configures the development container with proper access
################################################################################

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/modules/common.sh"

check_host_system() {
    log_step "Checking host system requirements..."

    local all_checks_passed=true

    # Check if distrobox is installed
    if ! command -v distrobox &> /dev/null; then
        log_error "distrobox is not installed"
        echo ""
        echo "Please install distrobox first. On Bazzite, it should be pre-installed."
        echo "If missing, install with: rpm-ostree install distrobox"
        echo ""
        record_tool_status "distrobox" "failed" "N/A" "distrobox command not found"
        return 1
    fi

    local distrobox_version
    distrobox_version=$(distrobox version 2>&1 | head -n1 || echo "unknown")
    log_success "distrobox is available ($distrobox_version)"
    record_tool_status "distrobox" "success" "$distrobox_version"

    # Check if we're on Bazzite
    if [ -f /etc/os-release ]; then
        if grep -qi "bazzite" /etc/os-release; then
            log_success "Running on Bazzite"
        else
            log_warn "Not running on Bazzite - this tool is designed for Bazzite"
            log_warn "It may work on other distrobox-compatible systems, but is untested"
            all_checks_passed=false
        fi
    fi

    # Check available disk space
    local free_space
    free_space=$(df -BG "$HOME" | tail -1 | awk '{print $4}' | tr -d 'G')
    if [ "$free_space" -lt 5 ]; then
        log_error "Insufficient disk space: ${free_space}GB available"
        log_error "At least 5GB free space is required"
        return 1
    else
        log_success "Sufficient disk space: ${free_space}GB available"
    fi

    # Check if podman is available (for socket mounting)
    if ! command -v podman &> /dev/null; then
        log_warn "podman not found - Docker/Podman integration will not work"
        log "Install podman if you need Docker compatibility"
        all_checks_passed=false
    else
        local podman_version
        podman_version=$(podman --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
        log_success "podman is available ($podman_version)"
    fi

    if [ "$all_checks_passed" = false ]; then
        echo ""
        log_warn "Some checks failed or showed warnings"
        echo -en "Continue anyway? (y/N): "
        read -r response
        case $response in
            [Yy]* )
                log "User chose to continue despite warnings"
                return 0
                ;;
            * )
                log "User cancelled due to failed checks"
                return 1
                ;;
        esac
    fi

    return 0
}

check_podman_socket() {
    log "Checking for podman socket..."

    local podman_socket_dir="/run/user/$UID/podman"
    local podman_socket_path="$podman_socket_dir/podman.sock"

    # Check if directory exists
    if [ ! -d "$podman_socket_dir" ]; then
        log_warn "Podman socket directory not found at $podman_socket_dir"
        log "Container will be created WITHOUT podman socket access"
        log "To enable: systemctl --user start podman.socket"
        return 1
    fi

    # Check if socket file exists
    if [ ! -S "$podman_socket_path" ]; then
        log_warn "Podman socket file not found at $podman_socket_path"
        log "Container will be created WITHOUT podman socket access"
        log "To enable: systemctl --user start podman.socket"
        return 1
    fi

    log_success "Podman socket found and accessible"
    return 0
}

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

    # Check if podman socket is available
    local mount_podman_socket=false
    if check_podman_socket; then
        mount_podman_socket=true
    fi

    # Build container creation command
    local create_cmd="distrobox create --name $CONTAINER_NAME --image $CONTAINER_IMAGE"

    # Add podman socket mount if available
    if [ "$mount_podman_socket" = true ]; then
        # Use direct variable expansion (not escaped) since we're not in quotes
        create_cmd="$create_cmd --volume /run/user/$UID/podman:/run/user/$UID/podman:rw"
        log "Including podman socket mount for Docker compatibility"
    fi

    create_cmd="$create_cmd --yes"

    # Create container with retry logic
    if try_with_retry "$create_cmd" "Container creation"; then
        if [ "$mount_podman_socket" = true ]; then
            log_success "Container '$CONTAINER_NAME' created with podman socket access"
        else
            log_success "Container '$CONTAINER_NAME' created"
        fi
        record_tool_status "container" "success" "new"

        # Wait for container to be fully ready with proper retry logic
        log "Waiting for container to be ready..."
        local max_attempts=30
        local attempt=1
        local wait_time=1

        while [ $attempt -le $max_attempts ]; do
            if distrobox enter "$CONTAINER_NAME" -- echo "test" &> /dev/null 2>&1; then
                log_success "Container is ready (attempt $attempt)"
                return 0
            fi

            sleep $wait_time
            ((attempt++))

            # Increase wait time after 10 attempts
            if [ $attempt -eq 10 ]; then
                wait_time=2
            fi
        done

        log_error "Container created but not accessible after $max_attempts attempts"
        record_tool_status "container" "failed" "N/A" "Container not accessible after creation"
        return 1
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
export -f check_host_system check_podman_socket setup_container install_container_dependencies
