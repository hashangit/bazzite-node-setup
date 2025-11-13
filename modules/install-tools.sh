#!/usr/bin/env bash

################################################################################
# Tool Installation Module
# Handles installation of development tools in the container
################################################################################

# This file should be sourced, not executed directly
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    echo "This script should be sourced, not executed directly."
    exit 1
fi

################################################################################
# Git Installation
################################################################################

install_git() {
    if [ "$INSTALL_GIT" != true ]; then
        log "Skipping Git installation (not selected)"
        return 0
    fi

    log_step "Installing Git..."

    # Git should already be installed from dependencies, verify and export
    local git_version
    git_version=$(distrobox enter "$CONTAINER_NAME" -- git --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")

    if [ "$git_version" != "unknown" ]; then
        log "Git version $git_version found in container"
        record_tool_status "git" "success" "$git_version"
        return 0
    else
        log_error "Git not found"
        record_tool_status "git" "failed" "N/A" "Not found in container"
        RECOVERY_ACTIONS["git"]="Enter container and run: sudo apt-get install -y git"
        return 1
    fi
}

################################################################################
# GitHub CLI Installation
################################################################################

install_github_cli() {
    if [ "$INSTALL_GITHUB_CLI" != true ]; then
        log "Skipping GitHub CLI installation (not selected)"
        return 0
    fi

    log_step "Installing GitHub CLI (gh)..."

    local install_gh='
        set -e

        # Add GitHub CLI repository
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

        # Install gh
        sudo apt-get update -qq
        sudo apt-get install -y -qq gh

        gh --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_gh" >> "$LOG_FILE" 2>&1; then
        local gh_version
        gh_version=$(distrobox enter "$CONTAINER_NAME" -- gh --version 2>&1 | head -1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_success "GitHub CLI version $gh_version installed"
        record_tool_status "gh" "success" "$gh_version"
        return 0
    else
        log_error "Failed to install GitHub CLI"
        record_tool_status "gh" "failed" "N/A" "Installation failed"
        RECOVERY_ACTIONS["gh"]="Install manually: https://cli.github.com/manual/installation"
        return 1
    fi
}

################################################################################
# Python UV Installation
################################################################################

install_uv() {
    if [ "$INSTALL_PYTHON" != true ]; then
        log "Skipping UV installation (not selected)"
        return 0
    fi

    log_step "Installing UV (Python package manager)..."

    local install_uv='
        set -e
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        uv --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_uv" >> "$LOG_FILE" 2>&1; then
        local uv_version
        uv_version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc "uv --version" 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_success "UV version $uv_version installed"
        record_tool_status "uv" "success" "$uv_version"
        return 0
    else
        log_error "Failed to install UV"
        record_tool_status "uv" "failed" "N/A" "Installation failed"
        RECOVERY_ACTIONS["uv"]="Install manually: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
}

################################################################################
# Node.js Stack Installation
################################################################################

install_nodejs() {
    if [ "$INSTALL_NODEJS" != true ]; then
        log "Skipping Node.js installation (not selected)"
        return 0
    fi

    log_step "Installing Node.js LTS (via NodeSource)..."

    local install_node='
        set -e

        # Install Node.js LTS via NodeSource repository (simple and reliable)
        echo "Setting up NodeSource repository..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

        echo "Installing Node.js and npm..."
        sudo apt-get install -y nodejs

        # Verify installation
        node --version
        npm --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_node" >> "$LOG_FILE" 2>&1; then
        local node_version npm_version
        node_version=$(distrobox enter "$CONTAINER_NAME" -- node --version 2>&1 || echo "unknown")
        npm_version=$(distrobox enter "$CONTAINER_NAME" -- npm --version 2>&1 || echo "unknown")

        log_success "Node.js $node_version installed"
        log_success "npm $npm_version installed"

        record_tool_status "node" "success" "$node_version"
        record_tool_status "npm" "success" "$npm_version"
        record_tool_status "npx" "success" "$npm_version"
        return 0
    else
        log_error "Failed to install Node.js"
        record_tool_status "node" "failed" "N/A" "Installation failed"
        record_tool_status "npm" "failed" "N/A" "Installation failed"
        record_tool_status "npx" "failed" "N/A" "Installation failed"
        RECOVERY_ACTIONS["node"]="Enter container and run: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash - && sudo apt-get install -y nodejs"
        return 1
    fi
}

install_pnpm() {
    if [ "$INSTALL_NODEJS" != true ]; then
        log "Skipping pnpm installation (not selected)"
        return 0
    fi

    log_step "Installing pnpm..."

    local install_pnpm='
        set -e

        # Check if already installed
        if command -v pnpm &> /dev/null; then
            echo "pnpm already installed"
            pnpm --version
            exit 0
        fi

        # Ensure ~/.local/bin exists
        mkdir -p "$HOME/.local/bin"

        # PRIMARY METHOD: Corepack with user directory (NO SUDO NEEDED!)
        # This avoids permission issues by installing to user directory
        echo "Enabling pnpm via Corepack (user directory)..."
        if corepack enable --install-directory "$HOME/.local/bin" 2>/dev/null; then
            # Add to PATH for this session
            export PATH="$HOME/.local/bin:$PATH"

            # Verify installation
            if pnpm --version 2>/dev/null; then
                echo "✓ pnpm installed via Corepack"
                pnpm --version
                exit 0
            fi
        fi

        # FALLBACK: Standalone installer if Corepack fails
        echo "Corepack method failed, using standalone installer..."
        curl -fsSL https://get.pnpm.io/install.sh | sh -

        # Reload PATH and verify
        export PNPM_HOME="$HOME/.local/share/pnpm"
        export PATH="$PNPM_HOME:$PATH"
        pnpm --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_pnpm" >> "$LOG_FILE" 2>&1; then
        local pnpm_version
        pnpm_version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc "pnpm --version" 2>&1 || echo "unknown")
        log_success "pnpm $pnpm_version installed"
        record_tool_status "pnpm" "success" "$pnpm_version"
        return 0
    else
        log_error "Failed to install pnpm"
        record_tool_status "pnpm" "failed" "N/A" "Installation failed"
        RECOVERY_ACTIONS["pnpm"]="Install manually: curl -fsSL https://get.pnpm.io/install.sh | sh -"
        return 1
    fi
}

install_bun() {
    if [ "$INSTALL_NODEJS" != true ]; then
        log "Skipping bun installation (not selected)"
        return 0
    fi

    log_step "Installing bun..."

    local install_bun='
        set -e

        # Check if already installed
        if [ -f "$HOME/.bun/bin/bun" ]; then
            echo "bun already installed"
            $HOME/.bun/bin/bun --version
            exit 0
        fi

        # Install bun
        curl -fsSL https://bun.sh/install | bash

        # Verify
        $HOME/.bun/bin/bun --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_bun" >> "$LOG_FILE" 2>&1; then
        local bun_version
        bun_version=$(distrobox enter "$CONTAINER_NAME" -- bash -c '$HOME/.bun/bin/bun --version' 2>&1 || echo "unknown")
        log_success "bun $bun_version installed"
        record_tool_status "bun" "success" "$bun_version"
        record_tool_status "bunx" "success" "$bun_version"
        return 0
    else
        log_error "Failed to install bun"
        record_tool_status "bun" "failed" "N/A" "Installation failed"
        record_tool_status "bunx" "failed" "N/A" "Installation failed"
        RECOVERY_ACTIONS["bun"]="Install manually: curl -fsSL https://bun.sh/install | bash"
        return 1
    fi
}

################################################################################
# Installation Orchestration
################################################################################

install_all_tools() {
    log_step "Installing all selected tools..."

    local total_steps=0
    local completed_steps=0

    # Count steps
    [ "$INSTALL_NODEJS" == true ] && total_steps=$((total_steps + 3))  # node, pnpm, bun
    [ "$INSTALL_PYTHON" == true ] && total_steps=$((total_steps + 1))  # uv
    [ "$INSTALL_GIT" == true ] && total_steps=$((total_steps + 1))     # git
    [ "$INSTALL_GITHUB_CLI" == true ] && total_steps=$((total_steps + 1))  # gh

    # Node.js stack
    if [ "$INSTALL_NODEJS" == true ]; then
        install_nodejs && ((completed_steps++))
        progress_bar $completed_steps $total_steps

        install_pnpm && ((completed_steps++))
        progress_bar $completed_steps $total_steps

        install_bun && ((completed_steps++))
        progress_bar $completed_steps $total_steps
    fi

    # Python tools
    if [ "$INSTALL_PYTHON" == true ]; then
        install_uv && ((completed_steps++))
        progress_bar $completed_steps $total_steps
    fi

    # Git
    if [ "$INSTALL_GIT" == true ]; then
        install_git && ((completed_steps++))
        progress_bar $completed_steps $total_steps
    fi

    # GitHub CLI
    if [ "$INSTALL_GITHUB_CLI" == true ]; then
        install_github_cli && ((completed_steps++))
        progress_bar $completed_steps $total_steps
    fi

    log_success "Tool installation phase complete"
    return 0
}

################################################################################
# Verification
################################################################################

verify_installation() {
    log_step "Verifying installation..."

    local tools=()
    [ "$INSTALL_NODEJS" == true ] && tools+=("node" "npm" "npx" "pnpm" "bun")
    [ "$INSTALL_GIT" == true ] && tools+=("git")
    [ "$INSTALL_GITHUB_CLI" == true ] && tools+=("gh")
    [ "$INSTALL_PYTHON" == true ] && tools+=("uv")

    if [ ${#tools[@]} -eq 0 ]; then
        log "No tools to verify (none were selected)"
        return 0
    fi

    local verified=0
    local failed_verify=0

    for tool in "${tools[@]}"; do
        # Check if wrapper exists on host
        if command -v "$tool" &> /dev/null; then
            # Get version directly from container to avoid wrapper overhead/timeouts
            local version
            case "$tool" in
                node|npm|npx)
                    version=$(distrobox enter "$CONTAINER_NAME" -- bash -c "$tool --version 2>&1 | head -1" 2>/dev/null | tr -d '\r\n' || echo "")
                    ;;
                pnpm|bun|bunx)
                    version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc "$tool --version 2>&1 | head -1" 2>/dev/null | tr -d '\r\n' || echo "")
                    ;;
                git)
                    version=$(distrobox enter "$CONTAINER_NAME" -- git --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "")
                    ;;
                gh)
                    version=$(distrobox enter "$CONTAINER_NAME" -- gh --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' || echo "")
                    ;;
                uv)
                    version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc "uv --version 2>&1" 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "")
                    ;;
                *)
                    version=""
                    ;;
            esac

            if [ -n "$version" ]; then
                log "✓ $tool is accessible ($version)"
            else
                log "✓ $tool is accessible ()"
            fi
            ((verified++))
        else
            log_warn "✗ $tool is NOT accessible from host"
            ((failed_verify++))
        fi
    done

    log_success "Verified $verified/${#tools[@]} tools accessible from host"

    if [ $failed_verify -gt 0 ]; then
        log_warn "Some tools not accessible. You may need to restart your terminal."
        return 1
    fi

    return 0
}

# Export functions
export -f install_git install_github_cli install_uv
export -f install_nodejs install_pnpm install_bun
export -f install_all_tools verify_installation
