#!/usr/bin/env bash

################################################################################
# Tool Export Module
# Exports binaries from container to host with proper process management
################################################################################

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/modules/common.sh"

# Export a binary with process-aware wrapper
# This ensures dev servers terminate when the terminal closes
export_binary_with_wrapper() {
    local tool_name=$1
    local binary_path=$2
    local container=$3

    log "Exporting $tool_name with process management..."

    # Remove existing export if present
    rm -f "$HOME/.local/bin/$tool_name" 2>/dev/null

    # Create process-aware wrapper
    # IMPORTANT: Do NOT use 'exec' as it discards trap handlers
    cat > "$HOME/.local/bin/$tool_name" <<'WRAPPER_EOF'
#!/usr/bin/env bash
# Auto-generated wrapper for TOOL_NAME
# Ensures process termination when terminal closes

# Create a process group so we can kill all children
set -m

# Track the background process PID
CHILD_PID=""

# Cleanup function to kill process tree
cleanup() {
    if [ -n "$CHILD_PID" ]; then
        # Kill the entire process group
        kill -- -$CHILD_PID 2>/dev/null || true
        # Wait a moment for graceful shutdown
        sleep 0.5
        # Force kill if still alive
        kill -9 -- -$CHILD_PID 2>/dev/null || true
    fi
    exit
}

# Trap all terminal close signals
trap cleanup EXIT TERM INT HUP QUIT

# Run command in container as background process (NOT exec!)
# This preserves the wrapper shell and its trap handlers
distrobox-enter -n "CONTAINER_NAME" -- "BINARY_PATH" "$@" &
CHILD_PID=$!

# Verify process started (wait briefly and check)
sleep 0.1
if ! kill -0 $CHILD_PID 2>/dev/null; then
    echo "Error: Failed to start TOOL_NAME in container" >&2
    exit 1
fi

# Wait for the process to complete
# This blocks but allows traps to work
wait $CHILD_PID
EXIT_CODE=$?

# Clean up and exit with same code
cleanup
exit $EXIT_CODE
WRAPPER_EOF

    # Replace placeholders with actual values
    # Use @ as delimiter to avoid conflicts with paths containing |
    sed -i "s@TOOL_NAME@$tool_name@g" "$HOME/.local/bin/$tool_name"
    sed -i "s@CONTAINER_NAME@$container@g" "$HOME/.local/bin/$tool_name"
    sed -i "s@BINARY_PATH@$binary_path@g" "$HOME/.local/bin/$tool_name"

    chmod +x "$HOME/.local/bin/$tool_name"

    # Verify wrapper was created
    if [ -x "$HOME/.local/bin/$tool_name" ]; then
        log "✓ $tool_name wrapper created"
        return 0
    else
        log_warn "✗ $tool_name wrapper creation failed"
        return 1
    fi
}

# Export a tool using distrobox-export (for simple cases where process management isn't critical)
export_with_distrobox() {
    local binary_path=$1
    local container=$2

    if distrobox-export --bin "$binary_path" \
        --export-path "$HOME/.local/bin" \
        --container "$container" &>> "$LOG_FILE"; then
        return 0
    else
        return 1
    fi
}

export_nodejs_tools() {
    if [ "${INSTALL_NODEJS:-true}" != true ]; then
        log "Skipping Node.js tools export (not selected)"
        return 0
    fi

    log_step "Exporting Node.js tools..."

    local exported=0
    local failed=0

    # Get Node.js binary paths using login shell (-lc) for proper environment
    local node_path npm_path npx_path pnpm_path

    node_path=$(distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; which node' 2>/dev/null | tr -d '\r\n' | xargs)
    npm_path=$(distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; which npm' 2>/dev/null | tr -d '\r\n' | xargs)
    npx_path=$(distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; which npx' 2>/dev/null | tr -d '\r\n' | xargs)
    pnpm_path=$(distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; which pnpm' 2>/dev/null | tr -d '\r\n' | xargs)

    # Validate and export node with process management
    if [ -n "$node_path" ] && [[ "$node_path" =~ ^/ ]]; then
        if export_binary_with_wrapper "node" "$node_path" "$CONTAINER_NAME"; then
            ((exported++))
        else
            ((failed++))
        fi
    else
        log_warn "✗ node path not found or invalid: '$node_path'"
        ((failed++))
    fi

    # Export npm
    if [ -n "$npm_path" ] && [[ "$npm_path" =~ ^/ ]]; then
        if export_binary_with_wrapper "npm" "$npm_path" "$CONTAINER_NAME"; then
            ((exported++))
        else
            ((failed++))
        fi
    else
        log_warn "✗ npm path not found or invalid: '$npm_path'"
        ((failed++))
    fi

    # Export npx
    if [ -n "$npx_path" ] && [[ "$npx_path" =~ ^/ ]]; then
        if export_binary_with_wrapper "npx" "$npx_path" "$CONTAINER_NAME"; then
            ((exported++))
        else
            ((failed++))
        fi
    else
        log_warn "✗ npx path not found or invalid: '$npx_path'"
        ((failed++))
    fi

    # Export pnpm
    if [ -n "$pnpm_path" ] && [[ "$pnpm_path" =~ ^/ ]]; then
        if export_binary_with_wrapper "pnpm" "$pnpm_path" "$CONTAINER_NAME"; then
            ((exported++))
        else
            ((failed++))
        fi
    else
        log_warn "✗ pnpm path not found or invalid: '$pnpm_path'"
        ((failed++))
    fi

    # Export bun
    local bun_path="$HOME/.bun/bin/bun"
    if distrobox enter "$CONTAINER_NAME" -- bash -c "[ -f $bun_path ]" 2>/dev/null; then
        if export_binary_with_wrapper "bun" "$bun_path" "$CONTAINER_NAME"; then
            ((exported++))
        else
            ((failed++))
        fi
    else
        log_warn "✗ bun not found at $bun_path"
        ((failed++))
    fi

    # Export bunx
    local bunx_path="$HOME/.bun/bin/bunx"
    if distrobox enter "$CONTAINER_NAME" -- bash -c "[ -f $bunx_path ]" 2>/dev/null; then
        if export_binary_with_wrapper "bunx" "$bunx_path" "$CONTAINER_NAME"; then
            ((exported++))
        else
            ((failed++))
        fi
    else
        log_warn "✗ bunx not found at $bunx_path"
        ((failed++))
    fi

    log_success "Exported $exported Node.js tools, $failed failed"

    if [ $failed -gt 0 ]; then
        log_warn "Some Node.js exports failed - check logs for details"
        RECOVERY_ACTIONS["node-exports"]="Tools available in container. Access with: distrobox enter $CONTAINER_NAME"
        return 1
    fi

    return 0
}

export_git_tools() {
    if [ "${INSTALL_GIT:-true}" != true ]; then
        log "Skipping Git export (not selected)"
        return 0
    fi

    log_step "Exporting Git..."

    local git_path
    git_path=$(distrobox enter "$CONTAINER_NAME" -- which git 2>/dev/null | tr -d '\r\n' | xargs)

    # Validate path
    if [ -n "$git_path" ] && [[ "$git_path" =~ ^/ ]]; then
        if export_binary_with_wrapper "git" "$git_path" "$CONTAINER_NAME"; then
            local git_version
            git_version=$(distrobox enter "$CONTAINER_NAME" -- git --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
            log_success "Git $git_version exported"
            record_tool_status "git" "success" "$git_version"
            return 0
        fi
    fi

    log_error "Failed to export Git - path not found or invalid"
    record_tool_status "git" "failed" "N/A" "Export failed"
    return 1
}

export_github_cli() {
    if [ "${INSTALL_GITHUB_CLI:-true}" != true ]; then
        log "Skipping GitHub CLI export (not selected)"
        return 0
    fi

    log_step "Exporting GitHub CLI..."

    local gh_path
    gh_path=$(distrobox enter "$CONTAINER_NAME" -- which gh 2>/dev/null | tr -d '\r\n' | xargs)

    # Validate path
    if [ -n "$gh_path" ] && [[ "$gh_path" =~ ^/ ]]; then
        if export_binary_with_wrapper "gh" "$gh_path" "$CONTAINER_NAME"; then
            local gh_version
            gh_version=$(distrobox enter "$CONTAINER_NAME" -- gh --version 2>&1 | head -1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
            log_success "GitHub CLI $gh_version exported"
            record_tool_status "gh" "success" "$gh_version"
            return 0
        fi
    fi

    log_error "Failed to export GitHub CLI - path not found or invalid"
    record_tool_status "gh" "failed" "N/A" "Export failed"
    return 1
}

export_python_tools() {
    if [ "${INSTALL_PYTHON:-true}" != true ]; then
        log "Skipping Python tools export (not selected)"
        return 0
    fi

    log_step "Exporting Python tools..."

    local uv_path="$HOME/.local/bin/uv"

    if distrobox enter "$CONTAINER_NAME" -- bash -c "[ -f $uv_path ]" 2>/dev/null; then
        if export_binary_with_wrapper "uv" "$uv_path" "$CONTAINER_NAME"; then
            local uv_version
            uv_version=$(distrobox enter "$CONTAINER_NAME" -- "$uv_path" --version 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
            log_success "UV $uv_version exported"
            record_tool_status "uv" "success" "$uv_version"
            return 0
        fi
    fi

    log_error "Failed to export UV - not found or export failed"
    record_tool_status "uv" "failed" "N/A" "Export failed"
    return 1
}

export_all_tools() {
    log_step "Exporting all tools to host..."

    # Ensure ~/.local/bin exists
    mkdir -p "$HOME/.local/bin"

    local success=true

    # Export each tool category
    export_nodejs_tools || success=false
    export_git_tools || success=false
    export_github_cli || success=false
    export_python_tools || success=false

    if [ "$success" = true ]; then
        log_success "All tools exported successfully"
        return 0
    else
        log_warn "Some tools failed to export - check details above"
        return 1
    fi
}

# Export functions
export -f export_binary_with_wrapper export_with_distrobox
export -f export_nodejs_tools export_git_tools export_github_cli export_python_tools
export -f export_all_tools
