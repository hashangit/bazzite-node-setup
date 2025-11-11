#!/usr/bin/env bash

################################################################################
# Bazzite Development Container Setup Script - Fully Automated
#
# This script sets up a complete development environment in a distrobox
# container on Bazzite, with clean exports to the host system.
#
# Features:
# - Node.js dev stack: Node.js (via NVM), npm, npx, pnpm, bun
# - Python tools: UV (fast Python package manager)
# - Version control: git, GitHub CLI (gh)
# - Fully automated with no user prompts
# - Comprehensive error reporting and recovery
# - Preemptive permission fixes
# - Detailed final report
#
# Usage: ./setup-dev-container.sh
################################################################################

set -uo pipefail  # Don't exit on error - we want to report all errors

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

# Configuration
readonly CONTAINER_NAME="main-dev"
readonly CONTAINER_IMAGE="ubuntu:24.04"
readonly NODE_VERSION="lts"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/setup.log"
readonly REPORT_FILE="${SCRIPT_DIR}/setup-report.md"
readonly START_TIME=$(date +%s)

# State tracking
declare -A TOOL_STATUS=()
declare -A TOOL_VERSION=()
declare -A TOOL_ERRORS=()
declare -A RECOVERY_ACTIONS=()
declare -a WARNINGS=()
declare -a INSTALLED_TOOLS=()
declare -a FAILED_TOOLS=()

################################################################################
# Helper Functions
################################################################################

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"
    echo "[$timestamp] [INFO] $*" >> "$LOG_FILE"
}

log_warn() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
    echo "[$timestamp] [WARN] $*" >> "$LOG_FILE"
    WARNINGS+=("$*")
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
    echo "[$timestamp] [ERROR] $*" >> "$LOG_FILE"
}

log_success() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$LOG_FILE"
    echo "[$timestamp] [SUCCESS] $*" >> "$LOG_FILE"
}

log_step() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $*"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo "" >> "$LOG_FILE"
    echo "============================================================" >> "$LOG_FILE"
    echo "STEP: $*" >> "$LOG_FILE"
    echo "============================================================" >> "$LOG_FILE"
}

separator() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))

    printf "\r${CYAN}Progress: [${NC}"
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "${CYAN}] ${percentage}%%${NC}"

    if [ $current -eq $total ]; then
        echo ""
    fi
}

record_tool_status() {
    local tool=$1
    local status=$2
    local version=${3:-"N/A"}
    local error=${4:-""}

    TOOL_STATUS["$tool"]=$status
    TOOL_VERSION["$tool"]=$version

    if [ -n "$error" ]; then
        TOOL_ERRORS["$tool"]=$error
    fi

    if [ "$status" == "success" ]; then
        INSTALLED_TOOLS+=("$tool")
    elif [ "$status" == "failed" ]; then
        FAILED_TOOLS+=("$tool")
    fi
}

try_with_retry() {
    local max_attempts=3
    local attempt=1
    local cmd="$1"
    local description="$2"

    while [ $attempt -le $max_attempts ]; do
        log "Attempt $attempt/$max_attempts: $description"

        if eval "$cmd" >> "$LOG_FILE" 2>&1; then
            log_success "$description - succeeded"
            return 0
        fi

        log_warn "$description - failed (attempt $attempt/$max_attempts)"
        attempt=$((attempt + 1))

        if [ $attempt -le $max_attempts ]; then
            local wait_time=$((2 ** (attempt - 1)))
            log "Waiting ${wait_time}s before retry..."
            sleep $wait_time
        fi
    done

    log_error "$description - failed after $max_attempts attempts"
    return 1
}

fix_permissions() {
    log_step "Preemptively fixing permissions..."

    # Ensure ~/.local/bin exists with correct permissions
    if [ ! -d "$HOME/.local/bin" ]; then
        mkdir -p "$HOME/.local/bin"
        log "Created ~/.local/bin"
    fi

    chmod 755 "$HOME/.local/bin"
    log "Set permissions on ~/.local/bin"

    # Ensure proper ownership
    if [ -d "$HOME/.local" ]; then
        chown -R "$USER:$USER" "$HOME/.local" 2>/dev/null || true
        log "Set ownership on ~/.local"
    fi
}

check_and_add_to_path() {
    log_step "Checking and configuring PATH..."

    local path_line='export PATH="$HOME/.local/bin:$PATH"'
    local shell_rc_files=("$HOME/.bashrc" "$HOME/.zshrc")

    for rc_file in "${shell_rc_files[@]}"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q "\.local/bin" "$rc_file"; then
                echo "" >> "$rc_file"
                echo "# Added by Bazzite Node Setup" >> "$rc_file"
                echo "$path_line" >> "$rc_file"
                log "Added PATH to $rc_file"
            else
                log "PATH already configured in $rc_file"
            fi
        fi
    done

    # Add to current session
    export PATH="$HOME/.local/bin:$PATH"
    log "PATH configured for current session"
}

################################################################################
# Installation Functions
################################################################################

check_host_system() {
    log_step "Step 1/12: Checking host system"

    if ! command -v distrobox &> /dev/null; then
        log_error "distrobox is not installed"
        record_tool_status "distrobox" "failed" "N/A" "distrobox command not found"
        return 1
    fi

    local distrobox_version
    distrobox_version=$(distrobox version 2>&1 | head -n1 || echo "unknown")
    log_success "distrobox is available (version: $distrobox_version)"
    record_tool_status "distrobox" "success" "$distrobox_version"

    # Check OS
    if [ -f /etc/os-release ]; then
        if grep -qi "bazzite" /etc/os-release; then
            log "✓ Running on Bazzite"
        else
            log_warn "Not running on Bazzite, but distrobox is available"
        fi
    fi

    # Check resources
    local free_space
    free_space=$(df -BG "$HOME" | tail -1 | awk '{print $4}' | tr -d 'G')
    if [ "$free_space" -lt 5 ]; then
        log_warn "Low disk space: ${free_space}GB available (recommended: 5GB+)"
    else
        log "✓ Sufficient disk space: ${free_space}GB available"
    fi

    return 0
}

check_or_create_container() {
    log_step "Step 2/12: Setting up container '$CONTAINER_NAME'"

    if distrobox list 2>/dev/null | grep -q "^$CONTAINER_NAME"; then
        log "Container '$CONTAINER_NAME' already exists"

        # Verify it's accessible
        if distrobox enter "$CONTAINER_NAME" -- echo "test" &> /dev/null; then
            log_success "Container is accessible"
            record_tool_status "container" "success" "existing"
            return 0
        else
            log_warn "Container exists but is not accessible, recreating..."
            distrobox rm "$CONTAINER_NAME" --force &> /dev/null || true
        fi
    fi

    log "Creating container '$CONTAINER_NAME'..."

    if try_with_retry \
        "distrobox create --name '$CONTAINER_NAME' --image '$CONTAINER_IMAGE' --yes" \
        "Container creation"; then
        log_success "Container '$CONTAINER_NAME' created"
        record_tool_status "container" "success" "new"
        return 0
    else
        log_error "Failed to create container"
        record_tool_status "container" "failed" "N/A" "Creation failed after retries"
        RECOVERY_ACTIONS["container"]="Try manually: distrobox create --name $CONTAINER_NAME --image $CONTAINER_IMAGE"
        return 1
    fi
}

install_container_dependencies() {
    log_step "Step 3/12: Installing container dependencies"

    local install_script='
        set -e
        export DEBIAN_FRONTEND=noninteractive

        # Update package lists
        apt-get update -qq

        # Install essential packages
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
            python3-venv

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

install_git() {
    log_step "Step 4/12: Installing Git"

    # Git should already be installed from dependencies, verify and export
    local git_version
    git_version=$(distrobox enter "$CONTAINER_NAME" -- git --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")

    if [ "$git_version" != "unknown" ]; then
        log "Git version $git_version found in container"

        # Export git
        if distrobox enter "$CONTAINER_NAME" -- which git | xargs -I {} distrobox-export --bin {} --export-path "$HOME/.local/bin" --container "$CONTAINER_NAME" &>> "$LOG_FILE"; then
            log_success "Git exported to host"
            record_tool_status "git" "success" "$git_version"
            return 0
        else
            log_warn "Git export failed, but available in container"
            record_tool_status "git" "partial" "$git_version" "Export failed"
            return 0
        fi
    else
        log_error "Git not found"
        record_tool_status "git" "failed" "N/A" "Not found in container"
        return 1
    fi
}

install_github_cli() {
    log_step "Step 5/12: Installing GitHub CLI (gh)"

    local install_gh='
        set -e

        # Add GitHub CLI repository
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg
        chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

        # Install gh
        apt-get update -qq
        apt-get install -y -qq gh

        gh --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_gh" >> "$LOG_FILE" 2>&1; then
        local gh_version
        gh_version=$(distrobox enter "$CONTAINER_NAME" -- gh --version 2>&1 | head -1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log "GitHub CLI version $gh_version installed"

        # Export gh
        if distrobox enter "$CONTAINER_NAME" -- which gh | xargs -I {} distrobox-export --bin {} --export-path "$HOME/.local/bin" --container "$CONTAINER_NAME" &>> "$LOG_FILE"; then
            log_success "GitHub CLI exported to host"
            record_tool_status "gh" "success" "$gh_version"
            return 0
        else
            log_warn "GitHub CLI export failed"
            record_tool_status "gh" "partial" "$gh_version" "Export failed"
            return 0
        fi
    else
        log_error "Failed to install GitHub CLI"
        record_tool_status "gh" "failed" "N/A" "Installation failed"
        RECOVERY_ACTIONS["gh"]="Install manually: https://cli.github.com/manual/installation"
        return 1
    fi
}

install_uv() {
    log_step "Step 6/12: Installing UV (Python package manager)"

    local install_uv='
        set -e
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        uv --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_uv" >> "$LOG_FILE" 2>&1; then
        local uv_version
        uv_version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc "uv --version" 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log "UV version $uv_version installed"

        # Export uv
        if distrobox enter "$CONTAINER_NAME" -- bash -c "[ -f \$HOME/.local/bin/uv ] && echo \$HOME/.local/bin/uv" | xargs -I {} distrobox-export --bin {} --export-path "$HOME/.local/bin" --container "$CONTAINER_NAME" &>> "$LOG_FILE"; then
            log_success "UV exported to host"
            record_tool_status "uv" "success" "$uv_version"
            return 0
        else
            log_warn "UV export failed"
            record_tool_status "uv" "partial" "$uv_version" "Export failed"
            return 0
        fi
    else
        log_error "Failed to install UV"
        record_tool_status "uv" "failed" "N/A" "Installation failed"
        RECOVERY_ACTIONS["uv"]="Install manually: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
}

install_nvm() {
    log_step "Step 7/12: Installing NVM (Node Version Manager)"

    local install_nvm='
        set -e

        # Check if NVM already installed
        if [ -d "$HOME/.nvm" ]; then
            echo "NVM already installed"
            exit 0
        fi

        # Install NVM
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

        # Verify
        nvm --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_nvm" >> "$LOG_FILE" 2>&1; then
        local nvm_version
        nvm_version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm --version' 2>&1 || echo "unknown")
        log_success "NVM version $nvm_version installed"
        record_tool_status "nvm" "success" "$nvm_version"
        return 0
    else
        log_error "Failed to install NVM"
        record_tool_status "nvm" "failed" "N/A" "Installation failed"
        RECOVERY_ACTIONS["nvm"]="Install manually: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
        return 1
    fi
}

install_nodejs() {
    log_step "Step 8/12: Installing Node.js"

    local install_node='
        set -e

        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

        # Install Node.js
        nvm install '$NODE_VERSION'
        nvm use '$NODE_VERSION'
        nvm alias default '$NODE_VERSION'

        # Verify
        node --version
        npm --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_node" >> "$LOG_FILE" 2>&1; then
        local node_version npm_version
        node_version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; node --version' 2>&1 || echo "unknown")
        npm_version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; npm --version' 2>&1 || echo "unknown")

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
        RECOVERY_ACTIONS["node"]="Enter container and run: nvm install --lts"
        return 1
    fi
}

install_pnpm() {
    log_step "Step 9/12: Installing pnpm"

    local install_pnpm='
        set -e

        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

        # Check if already installed
        if command -v pnpm &> /dev/null; then
            echo "pnpm already installed"
            pnpm --version
            exit 0
        fi

        # Install pnpm
        npm install -g pnpm

        # Verify
        pnpm --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_pnpm" >> "$LOG_FILE" 2>&1; then
        local pnpm_version
        pnpm_version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; pnpm --version' 2>&1 || echo "unknown")
        log_success "pnpm $pnpm_version installed"
        record_tool_status "pnpm" "success" "$pnpm_version"
        return 0
    else
        log_error "Failed to install pnpm"
        record_tool_status "pnpm" "failed" "N/A" "Installation failed"
        RECOVERY_ACTIONS["pnpm"]="Install manually: npm install -g pnpm"
        return 1
    fi
}

install_bun() {
    log_step "Step 10/12: Installing bun"

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

export_binaries() {
    log_step "Step 11/12: Exporting binaries to host"

    local exported=0
    local failed=0

    # Export node
    log "Exporting node..."
    if distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; which node' 2>/dev/null | xargs -I {} distrobox-export --bin {} --export-path "$HOME/.local/bin" --container "$CONTAINER_NAME" &>> "$LOG_FILE"; then
        log "✓ node exported"
        ((exported++))
    else
        log_warn "✗ node export failed"
        ((failed++))
    fi

    # Export npm
    log "Exporting npm..."
    if distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; which npm' 2>/dev/null | xargs -I {} distrobox-export --bin {} --export-path "$HOME/.local/bin" --container "$CONTAINER_NAME" &>> "$LOG_FILE"; then
        log "✓ npm exported"
        ((exported++))
    else
        log_warn "✗ npm export failed"
        ((failed++))
    fi

    # Export npx
    log "Exporting npx..."
    if distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; which npx' 2>/dev/null | xargs -I {} distrobox-export --bin {} --export-path "$HOME/.local/bin" --container "$CONTAINER_NAME" &>> "$LOG_FILE"; then
        log "✓ npx exported"
        ((exported++))
    else
        log_warn "✗ npx export failed"
        ((failed++))
    fi

    # Export pnpm
    log "Exporting pnpm..."
    if distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; which pnpm' 2>/dev/null | xargs -I {} distrobox-export --bin {} --export-path "$HOME/.local/bin" --container "$CONTAINER_NAME" &>> "$LOG_FILE"; then
        log "✓ pnpm exported"
        ((exported++))
    else
        log_warn "✗ pnpm export failed"
        ((failed++))
    fi

    # Export bun
    log "Exporting bun..."
    if distrobox enter "$CONTAINER_NAME" -- bash -c '[ -f $HOME/.bun/bin/bun ] && echo $HOME/.bun/bin/bun' 2>/dev/null | xargs -I {} distrobox-export --bin {} --export-path "$HOME/.local/bin" --container "$CONTAINER_NAME" &>> "$LOG_FILE"; then
        log "✓ bun exported"
        ((exported++))
    else
        log_warn "✗ bun export failed"
        ((failed++))
    fi

    # Export bunx
    log "Exporting bunx..."
    if distrobox enter "$CONTAINER_NAME" -- bash -c '[ -f $HOME/.bun/bin/bunx ] && echo $HOME/.bun/bin/bunx' 2>/dev/null | xargs -I {} distrobox-export --bin {} --export-path "$HOME/.local/bin" --container "$CONTAINER_NAME" &>> "$LOG_FILE"; then
        log "✓ bunx exported"
        ((exported++))
    else
        log_warn "✗ bunx export failed"
        ((failed++))
    fi

    log_success "Exported $exported binaries, $failed failed"

    if [ $failed -gt 0 ]; then
        log_warn "Some exports failed. Tools will work inside container but may not be accessible from host."
        RECOVERY_ACTIONS["exports"]="Re-run export section or use tools inside container with: distrobox enter $CONTAINER_NAME"
        return 1
    fi

    return 0
}

verify_installation() {
    log_step "Step 12/12: Verifying installation"

    local tools=("node" "npm" "npx" "pnpm" "bun" "git" "gh" "uv")
    local verified=0
    local failed_verify=0

    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            local version
            version=$("$tool" --version 2>&1 | head -1 || echo "unknown")
            log "✓ $tool is accessible (${version})"
            ((verified++))
        else
            log_warn "✗ $tool is NOT accessible from host"
            ((failed_verify++))
        fi
    done

    log_success "Verified $verified/$((${#tools[@]})) tools accessible from host"

    if [ $failed_verify -gt 0 ]; then
        log_warn "Some tools not accessible. You may need to restart your terminal."
        return 1
    fi

    return 0
}

################################################################################
# Report Generation
################################################################################

generate_report() {
    log_step "Generating final report..."

    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    cat > "$REPORT_FILE" <<EOF
# Bazzite Development Container Setup Report

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Duration:** ${minutes}m ${seconds}s
**Container:** $CONTAINER_NAME
**Image:** $CONTAINER_IMAGE

---

## Summary

EOF

    # Count statuses
    local success_count=0
    local failed_count=0
    local partial_count=0

    for tool in "${!TOOL_STATUS[@]}"; do
        case "${TOOL_STATUS[$tool]}" in
            success) ((success_count++)) ;;
            failed) ((failed_count++)) ;;
            partial) ((partial_count++)) ;;
        esac
    done

    cat >> "$REPORT_FILE" <<EOF
- ✅ **Successful:** $success_count tools
- ⚠️  **Partial:** $partial_count tools
- ❌ **Failed:** $failed_count tools
- 📝 **Warnings:** ${#WARNINGS[@]}

EOF

    # Overall status
    if [ $failed_count -eq 0 ] && [ $partial_count -eq 0 ]; then
        cat >> "$REPORT_FILE" <<EOF
**Overall Status:** 🎉 **SUCCESS** - All tools installed and ready!

Your development environment is fully configured and ready to use.

EOF
    elif [ $failed_count -eq 0 ]; then
        cat >> "$REPORT_FILE" <<EOF
**Overall Status:** ✅ **MOSTLY SUCCESS** - Core functionality available

Some exports may have failed, but all tools are available in the container.

EOF
    else
        cat >> "$REPORT_FILE" <<EOF
**Overall Status:** ⚠️  **PARTIAL SUCCESS** - Some tools failed

The setup completed but some tools could not be installed. See details below.

EOF
    fi

    cat >> "$REPORT_FILE" <<EOF
---

## Installation Details

### ✅ Successfully Installed Tools

EOF

    for tool in "${!TOOL_STATUS[@]}"; do
        if [ "${TOOL_STATUS[$tool]}" == "success" ]; then
            echo "- **$tool**: ${TOOL_VERSION[$tool]}" >> "$REPORT_FILE"
        fi
    done

    if [ $partial_count -gt 0 ]; then
        cat >> "$REPORT_FILE" <<EOF

### ⚠️ Partially Installed Tools

EOF
        for tool in "${!TOOL_STATUS[@]}"; do
            if [ "${TOOL_STATUS[$tool]}" == "partial" ]; then
                echo "- **$tool**: ${TOOL_VERSION[$tool]}" >> "$REPORT_FILE"
                if [ -n "${TOOL_ERRORS[$tool]}" ]; then
                    echo "  - Error: ${TOOL_ERRORS[$tool]}" >> "$REPORT_FILE"
                fi
            fi
        done
    fi

    if [ $failed_count -gt 0 ]; then
        cat >> "$REPORT_FILE" <<EOF

### ❌ Failed Tools

EOF
        for tool in "${!TOOL_STATUS[@]}"; do
            if [ "${TOOL_STATUS[$tool]}" == "failed" ]; then
                echo "- **$tool**" >> "$REPORT_FILE"
                if [ -n "${TOOL_ERRORS[$tool]}" ]; then
                    echo "  - Error: ${TOOL_ERRORS[$tool]}" >> "$REPORT_FILE"
                fi
                if [ -n "${RECOVERY_ACTIONS[$tool]}" ]; then
                    echo "  - Recovery: \`${RECOVERY_ACTIONS[$tool]}\`" >> "$REPORT_FILE"
                fi
            fi
        done
    fi

    if [ ${#WARNINGS[@]} -gt 0 ]; then
        cat >> "$REPORT_FILE" <<EOF

---

## Warnings

EOF
        for warning in "${WARNINGS[@]}"; do
            echo "- $warning" >> "$REPORT_FILE"
        done
    fi

    cat >> "$REPORT_FILE" <<EOF

---

## Next Steps

### 1. Activate Your Environment

\`\`\`bash
# Restart your terminal, or run:
export PATH="\$HOME/.local/bin:\$PATH"
\`\`\`

### 2. Verify Installation

\`\`\`bash
# Check tools are accessible
node --version
npm --version
pnpm --version
bun --version
git --version
gh --version
uv --version

# Or run the verification script
./verify-setup.sh
\`\`\`

### 3. Start Development

\`\`\`bash
# Create a new project
mkdir my-project
cd my-project
npm init -y

# Install packages
npm install express

# Start coding!
\`\`\`

---

## Available Tools

### Node.js Development
- **node** - JavaScript runtime
- **npm** - Package manager
- **npx** - Package executor
- **pnpm** - Fast package manager (saves disk space)
- **bun** - Ultra-fast JavaScript runtime
- **bunx** - Bun package executor

### Python Development
- **uv** - Fast Python package manager and resolver

### Version Control
- **git** - Version control system
- **gh** - GitHub CLI

### Version Management
- **nvm** - Node version manager (available in container)

---

## Quick Reference

### Install Packages
\`\`\`bash
npm install <package>   # Using npm
pnpm add <package>      # Using pnpm (faster)
bun add <package>       # Using bun (fastest)
\`\`\`

### Run Scripts
\`\`\`bash
npm run dev    # or
pnpm dev       # or
bun dev
\`\`\`

### Switch Node Versions
\`\`\`bash
distrobox enter $CONTAINER_NAME
nvm install 18
nvm use 18
exit
\`\`\`

### Python with UV
\`\`\`bash
uv pip install <package>
uv venv
uv pip compile requirements.in
\`\`\`

---

## Troubleshooting

EOF

    if [ ${#RECOVERY_ACTIONS[@]} -gt 0 ]; then
        cat >> "$REPORT_FILE" <<EOF
### Recovery Actions

EOF
        for tool in "${!RECOVERY_ACTIONS[@]}"; do
            echo "**$tool:**" >> "$REPORT_FILE"
            echo "\`\`\`bash" >> "$REPORT_FILE"
            echo "${RECOVERY_ACTIONS[$tool]}" >> "$REPORT_FILE"
            echo "\`\`\`" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        done
    fi

    cat >> "$REPORT_FILE" <<EOF

### Common Issues

1. **Commands not found:** Restart terminal or run \`export PATH="\$HOME/.local/bin:\$PATH"\`
2. **Permission denied:** Run \`chmod +x ~/.local/bin/*\`
3. **Container issues:** Run \`distrobox list\` and verify container status
4. **Export failures:** Tools still work inside container with \`distrobox enter $CONTAINER_NAME\`

For detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Support

- 📖 **Documentation:** [README.md](README.md)
- 👤 **User Guide:** [USER_GUIDE.md](USER_GUIDE.md)
- 🔧 **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 📝 **Detailed Log:** \`cat setup.log\`

---

**Report Generated:** $(date '+%Y-%m-%d %H:%M:%S')
EOF

    log_success "Report generated: $REPORT_FILE"

    # Display report
    separator
    echo -e "\n${GREEN}${BOLD}SETUP COMPLETE${NC}\n"
    cat "$REPORT_FILE"
}

create_helper_scripts() {
    log "Creating helper scripts..."

    # Create verification script
    cat > "$SCRIPT_DIR/verify-setup.sh" <<'VERIFY_EOF'
#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

check_tool() {
    local tool=$1
    if command -v "$tool" &> /dev/null; then
        local version=$($tool --version 2>&1 | head -1)
        echo -e "${GREEN}✓${NC} $tool: $version"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $tool: NOT FOUND"
        ((FAILED++))
    fi
}

echo "Verifying Development Environment..."
echo "===================================="
check_tool "node"
check_tool "npm"
check_tool "npx"
check_tool "pnpm"
check_tool "bun"
check_tool "git"
check_tool "gh"
check_tool "uv"
echo "===================================="
echo -e "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
[ $FAILED -eq 0 ] && exit 0 || exit 1
VERIFY_EOF

    chmod +x "$SCRIPT_DIR/verify-setup.sh"

    # Create uninstall script
    cat > "$SCRIPT_DIR/uninstall.sh" <<'UNINSTALL_EOF'
#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="main-dev"

echo "⚠️  WARNING: This will remove the container and all exported binaries"
read -p "Are you sure? (yes/NO): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Uninstall cancelled"
    exit 0
fi

echo "Removing exported binaries..."
rm -f ~/.local/bin/{node,npm,npx,pnpm,bun,bunx,git,gh,uv,nvm}

echo "Removing container..."
distrobox rm "$CONTAINER_NAME" --force || true

echo "✓ Uninstall complete"
UNINSTALL_EOF

    chmod +x "$SCRIPT_DIR/uninstall.sh"

    log "Helper scripts created"
}

################################################################################
# Main Execution
################################################################################

main() {
    separator
    echo -e "${CYAN}
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     Bazzite Development Container Setup - Fully Automated    ║
║                                                               ║
║  Node.js • Python • Git • GitHub CLI                          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
${NC}"
    separator

    # Initialize log
    echo "Setup started at $(date)" > "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"

    # Pre-setup
    fix_permissions
    check_and_add_to_path

    # Main installation steps
    local total_steps=12
    local current_step=0

    check_host_system && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    check_or_create_container && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    install_container_dependencies && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    install_git && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    install_github_cli && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    install_uv && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    install_nvm && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    install_nodejs && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    install_pnpm && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    install_bun && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    export_binaries && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    verify_installation && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    # Post-setup
    create_helper_scripts

    # Generate report
    generate_report

    log "Setup log saved to: $LOG_FILE"

    # Final message
    separator
    echo -e "\n${GREEN}✓ Setup completed in ${minutes}m ${seconds}s${NC}\n"
    echo -e "📄 Detailed report: ${CYAN}$REPORT_FILE${NC}"
    echo -e "📋 Setup log: ${CYAN}$LOG_FILE${NC}\n"
    separator
}

# Run main function
main "$@"
