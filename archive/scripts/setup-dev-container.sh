#!/usr/bin/env bash

################################################################################
# Bazzite Development Container Setup Script - Fully Automated with Interactive Setup
#
# This script sets up a complete development environment in a distrobox
# container on Bazzite, with clean exports to the host system.
#
# Features:
# - Interactive mode: Choose what to install and configure
# - Bazzite DX rebase support (with safe DE and GPU detection)
# - Node.js dev stack: Node.js (via NVM), npm, npx, pnpm, bun
# - Python tools: UV (fast Python package manager)
# - Version control: git, GitHub CLI (gh)
# - Fully automated after selections
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
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Configuration
readonly CONTAINER_NAME="main-dev"
readonly CONTAINER_IMAGE="ubuntu:24.04"
readonly NODE_VERSION="lts"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/setup.log"
readonly REPORT_FILE="${SCRIPT_DIR}/setup-report.md"
readonly START_TIME=$(date +%s)

# User selections
REBASE_TO_DX=false
INSTALL_NODEJS=true
INSTALL_PYTHON=true
INSTALL_GIT=true
INSTALL_GITHUB_CLI=true

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

print_header() {
    clear
    separator
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║     Bazzite Development Container Setup - Interactive         ║"
    echo "║                                                               ║"
    echo "║  Node.js • Python • Git • GitHub CLI • DX Rebase             ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    separator
    echo ""
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

################################################################################
# Bazzite Detection Functions
################################################################################

detect_bazzite_info() {
    log_step "Detecting Bazzite system information..."

    if [ ! -f /etc/os-release ]; then
        log_error "Cannot find /etc/os-release"
        return 1
    fi

    # Source the os-release file
    . /etc/os-release

    # Check if this is Bazzite
    if ! echo "$NAME" | grep -qi "bazzite"; then
        log_warn "This does not appear to be a Bazzite system"
        log_warn "System: $NAME"
        return 1
    fi

    log "✓ Bazzite detected: $NAME"

    # Detect current deployment
    local current_deployment
    current_deployment=$(rpm-ostree status --json 2>/dev/null | grep -oP '"origin":\s*"\K[^"]+' | head -1 || echo "unknown")

    if [ "$current_deployment" != "unknown" ]; then
        log "Current deployment: $current_deployment"
        echo "$current_deployment"
        return 0
    else
        log_warn "Could not detect current deployment"
        return 1
    fi
}

detect_desktop_environment() {
    log "Detecting desktop environment..."

    # Check XDG_CURRENT_DESKTOP
    if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
        if echo "$XDG_CURRENT_DESKTOP" | grep -qi "kde\|plasma"; then
            echo "kde"
            log "✓ Desktop environment: KDE Plasma"
            return 0
        elif echo "$XDG_CURRENT_DESKTOP" | grep -qi "gnome"; then
            echo "gnome"
            log "✓ Desktop environment: GNOME"
            return 0
        fi
    fi

    # Fallback: Check for running processes
    if pgrep -x "plasmashell" > /dev/null; then
        echo "kde"
        log "✓ Desktop environment: KDE Plasma (detected from process)"
        return 0
    elif pgrep -x "gnome-shell" > /dev/null; then
        echo "gnome"
        log "✓ Desktop environment: GNOME (detected from process)"
        return 0
    fi

    # Check ostree deployment name
    local deployment
    deployment=$(rpm-ostree status --json 2>/dev/null | grep -oP '"origin":\s*"\K[^"]+' | head -1 || echo "")

    if echo "$deployment" | grep -q "gnome"; then
        echo "gnome"
        log "✓ Desktop environment: GNOME (from deployment)"
        return 0
    else
        echo "kde"
        log "✓ Desktop environment: KDE Plasma (default)"
        return 0
    fi
}

detect_gpu_vendor() {
    log "Detecting GPU vendor..."

    # Check for NVIDIA
    if lspci | grep -i vga | grep -qi nvidia; then
        echo "nvidia"
        log "✓ GPU: NVIDIA detected"
        return 0
    fi

    # Check for AMD
    if lspci | grep -i vga | grep -qi amd; then
        echo "amd"
        log "✓ GPU: AMD detected"
        return 0
    fi

    # Check for Intel
    if lspci | grep -i vga | grep -qi intel; then
        echo "intel"
        log "✓ GPU: Intel detected"
        return 0
    fi

    # Default to AMD/Intel (open source drivers)
    echo "amd"
    log_warn "Could not detect GPU, defaulting to AMD/Intel (open source drivers)"
    return 0
}

is_dx_variant() {
    local deployment="$1"

    if echo "$deployment" | grep -q "\-dx"; then
        return 0  # Is DX
    else
        return 1  # Not DX
    fi
}

construct_dx_rebase_target() {
    local de="$1"      # kde or gnome
    local gpu="$2"     # nvidia, amd, or intel

    local variant=""

    # Construct variant name
    if [ "$de" == "gnome" ]; then
        variant="bazzite-gnome"
    else
        variant="bazzite"
    fi

    # Add nvidia suffix if needed
    if [ "$gpu" == "nvidia" ]; then
        variant="${variant}-nvidia"
    fi

    # Add DX suffix
    variant="${variant}-dx"

    echo "$variant"
}

################################################################################
# Interactive Menu Functions
################################################################################

show_bazzite_rebase_menu() {
    print_header
    echo -e "${YELLOW}${BOLD}Bazzite Version Check${NC}\n"

    local current_deployment
    current_deployment=$(detect_bazzite_info)

    if [ $? -ne 0 ]; then
        log_warn "Not running on Bazzite or cannot detect version"
        echo -e "${YELLOW}Skipping Bazzite DX rebase...${NC}"
        sleep 2
        return 1
    fi

    if is_dx_variant "$current_deployment"; then
        echo -e "${GREEN}✓ You are already running Bazzite DX!${NC}"
        echo -e "Current: ${CYAN}$current_deployment${NC}\n"
        log "Already running DX variant, skipping rebase"
        sleep 2
        return 0
    fi

    echo -e "${CYAN}Current version:${NC} $current_deployment"
    echo -e "${YELLOW}You are running the base Bazzite version.${NC}\n"

    # Detect system info
    local de gpu dx_target
    de=$(detect_desktop_environment)
    gpu=$(detect_gpu_vendor)
    dx_target=$(construct_dx_rebase_target "$de" "$gpu")

    echo -e "${CYAN}Detected configuration:${NC}"
    echo -e "  Desktop Environment: ${GREEN}${de^^}${NC}"
    echo -e "  GPU Vendor: ${GREEN}${gpu^^}${NC}"
    echo -e "  Recommended DX variant: ${GREEN}$dx_target${NC}\n"

    separator
    echo -e "${BOLD}Bazzite DX includes additional developer tools and features:${NC}"
    echo "  • Development libraries and headers"
    echo "  • Additional command-line tools"
    echo "  • Pre-configured development environment"
    echo "  • Optimized for software development workflows"
    echo ""
    separator

    echo -e "\n${YELLOW}${BOLD}⚠️  IMPORTANT WARNING:${NC}"
    echo "  • Rebasing will modify your system image"
    echo "  • A reboot will be required after rebasing"
    echo "  • This operation is safe but takes a few minutes"
    echo "  • You can rollback if needed using rpm-ostree"
    echo ""

    # Ask user
    while true; do
        echo -en "${CYAN}${BOLD}Would you like to rebase to Bazzite DX?${NC} (y/n): "
        read -r response
        case $response in
            [Yy]* )
                REBASE_TO_DX=true
                REBASE_TARGET="$dx_target"
                log "User selected: Rebase to $dx_target"
                break
                ;;
            [Nn]* )
                REBASE_TO_DX=false
                log "User declined rebase"
                break
                ;;
            * )
                echo -e "${RED}Please answer y or n${NC}"
                ;;
        esac
    done

    echo ""
}

show_tool_selection_menu() {
    print_header
    echo -e "${YELLOW}${BOLD}Tool Selection${NC}\n"
    echo "Choose which development tools to install:"
    echo ""
    separator

    # Node.js stack
    while true; do
        echo -e "\n${CYAN}${BOLD}1. Node.js Development Stack${NC}"
        echo "   Includes: Node.js (LTS), npm, npx, pnpm, bun, NVM"
        echo "   Use for: JavaScript/TypeScript development, web apps, React, Vue, etc."
        echo -en "\n   Install Node.js stack? (Y/n): "
        read -r response
        case $response in
            [Nn]* )
                INSTALL_NODEJS=false
                log "User skipped: Node.js stack"
                break
                ;;
            * )
                INSTALL_NODEJS=true
                log "User selected: Node.js stack"
                break
                ;;
        esac
    done

    # Python tools
    while true; do
        echo -e "\n${CYAN}${BOLD}2. Python Development Tools${NC}"
        echo "   Includes: UV (fast Python package manager and resolver)"
        echo "   Use for: Python development, faster pip alternative"
        echo -en "\n   Install Python tools? (Y/n): "
        read -r response
        case $response in
            [Nn]* )
                INSTALL_PYTHON=false
                log "User skipped: Python tools"
                break
                ;;
            * )
                INSTALL_PYTHON=true
                log "User selected: Python tools"
                break
                ;;
        esac
    done

    # Git
    while true; do
        echo -e "\n${CYAN}${BOLD}3. Git Version Control${NC}"
        echo "   Includes: git (version control system)"
        echo "   Use for: Source code management, repositories"
        echo -en "\n   Install Git? (Y/n): "
        read -r response
        case $response in
            [Nn]* )
                INSTALL_GIT=false
                log "User skipped: Git"
                break
                ;;
            * )
                INSTALL_GIT=true
                log "User selected: Git"
                break
                ;;
        esac
    done

    # GitHub CLI
    while true; do
        echo -e "\n${CYAN}${BOLD}4. GitHub CLI${NC}"
        echo "   Includes: gh (GitHub command-line tool)"
        echo "   Use for: GitHub operations, PRs, issues, workflows"
        echo -en "\n   Install GitHub CLI? (Y/n): "
        read -r response
        case $response in
            [Nn]* )
                INSTALL_GITHUB_CLI=false
                log "User skipped: GitHub CLI"
                break
                ;;
            * )
                INSTALL_GITHUB_CLI=true
                log "User selected: GitHub CLI"
                break
                ;;
        esac
    done

    # Summary
    print_header
    echo -e "${GREEN}${BOLD}Installation Summary${NC}\n"
    separator
    echo ""
    echo "The following tools will be installed:"
    echo ""

    [ "$INSTALL_NODEJS" == true ] && echo -e "${GREEN}✓${NC} Node.js Development Stack (node, npm, npx, pnpm, bun, nvm)"
    [ "$INSTALL_PYTHON" == true ] && echo -e "${GREEN}✓${NC} Python Development Tools (uv)"
    [ "$INSTALL_GIT" == true ] && echo -e "${GREEN}✓${NC} Git Version Control"
    [ "$INSTALL_GITHUB_CLI" == true ] && echo -e "${GREEN}✓${NC} GitHub CLI (gh)"

    echo ""

    if [ "$INSTALL_NODEJS" == false ] && [ "$INSTALL_PYTHON" == false ] && [ "$INSTALL_GIT" == false ] && [ "$INSTALL_GITHUB_CLI" == false ]; then
        echo -e "${YELLOW}⚠️  No tools selected. Only container setup will be performed.${NC}"
    fi

    echo ""
    separator
    echo ""
    echo -en "${CYAN}${BOLD}Proceed with installation?${NC} (Y/n): "
    read -r response
    case $response in
        [Nn]* )
            echo -e "\n${YELLOW}Installation cancelled by user.${NC}"
            exit 0
            ;;
        * )
            log "User confirmed installation"
            ;;
    esac
}

################################################################################
# Rebase Functions
################################################################################

perform_rebase() {
    log_step "Rebasing to Bazzite DX..."

    local target="$REBASE_TARGET"
    local rebase_cmd="rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/${target}:stable"

    echo -e "\n${CYAN}Rebasing to:${NC} ${GREEN}${target}${NC}"
    echo -e "${CYAN}Command:${NC} $rebase_cmd\n"

    log "Executing rebase command: $rebase_cmd"

    # Show warning
    echo -e "${YELLOW}${BOLD}This will take a few minutes...${NC}\n"

    # Execute rebase
    if eval "$rebase_cmd" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Rebase completed successfully!"

        echo ""
        separator
        echo -e "\n${GREEN}${BOLD}✓ Rebase to Bazzite DX completed successfully!${NC}\n"
        echo -e "${YELLOW}${BOLD}⚠️  A REBOOT IS REQUIRED${NC}"
        echo ""
        echo "After reboot, your system will be running:"
        echo -e "  ${GREEN}${target}:stable${NC}"
        echo ""
        echo "To complete the development environment setup:"
        echo "  1. Reboot your system: ${CYAN}systemctl reboot${NC}"
        echo "  2. After reboot, run this script again to install dev tools"
        echo ""
        separator

        # Ask if user wants to reboot now
        echo ""
        while true; do
            echo -en "${CYAN}${BOLD}Reboot now?${NC} (y/n): "
            read -r response
            case $response in
                [Yy]* )
                    log "User chose to reboot now"
                    echo -e "\n${GREEN}Rebooting in 3 seconds...${NC}"
                    sleep 3
                    systemctl reboot
                    exit 0
                    ;;
                [Nn]* )
                    log "User chose to reboot later"
                    echo -e "\n${YELLOW}Please reboot when ready and run this script again.${NC}"
                    exit 0
                    ;;
                * )
                    echo -e "${RED}Please answer y or n${NC}"
                    ;;
            esac
        done
    else
        log_error "Rebase failed"
        echo -e "\n${RED}${BOLD}✗ Rebase failed${NC}"
        echo ""
        echo "Please check the log file for details: $LOG_FILE"
        echo ""
        echo "You can try manually with:"
        echo "  $rebase_cmd"
        echo ""

        # Ask if user wants to continue with tool installation anyway
        while true; do
            echo -en "${CYAN}Continue with tool installation anyway?${NC} (y/n): "
            read -r response
            case $response in
                [Yy]* )
                    log "User chose to continue despite rebase failure"
                    return 0
                    ;;
                [Nn]* )
                    log "User cancelled after rebase failure"
                    exit 1
                    ;;
                * )
                    echo -e "${RED}Please answer y or n${NC}"
                    ;;
            esac
        done
    fi
}

################################################################################
# Permission and PATH Functions
################################################################################

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
    log_step "Checking host system..."

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
    log_step "Setting up container '$CONTAINER_NAME'..."

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
    log_step "Installing container dependencies..."

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
    if [ "$INSTALL_GITHUB_CLI" != true ]; then
        log "Skipping GitHub CLI installation (not selected)"
        return 0
    fi

    log_step "Installing GitHub CLI (gh)..."

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
    if [ "$INSTALL_NODEJS" != true ]; then
        log "Skipping NVM installation (not selected)"
        return 0
    fi

    log_step "Installing NVM (Node Version Manager)..."

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
    if [ "$INSTALL_NODEJS" != true ]; then
        log "Skipping Node.js installation (not selected)"
        return 0
    fi

    log_step "Installing Node.js..."

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
    if [ "$INSTALL_NODEJS" != true ]; then
        log "Skipping pnpm installation (not selected)"
        return 0
    fi

    log_step "Installing pnpm..."

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

export_binaries() {
    log_step "Exporting binaries to host..."

    local exported=0
    local failed=0

    # Export Node.js tools if installed
    if [ "$INSTALL_NODEJS" == true ]; then
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

    log_success "Verified $verified/${#tools[@]} tools accessible from host"

    if [ $failed_verify -gt 0 ]; then
        log_warn "Some tools not accessible. You may need to restart your terminal."
        return 1
    fi

    return 0
}

################################################################################
# Report Generation (keeping the same function from before)
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
**Overall Status:** 🎉 **SUCCESS** - All selected tools installed and ready!

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
# Run the verification script
./verify-setup.sh
\`\`\`

### 3. Start Development

\`\`\`bash
# Create a new project
mkdir my-project
cd my-project
npm init -y

# Start coding!
\`\`\`

---

**Report Generated:** $(date '+%Y-%m-%d %H:%M:%S')
EOF

    log_success "Report generated: $REPORT_FILE"

    # Display summary
    separator
    echo -e "\n${GREEN}${BOLD}SETUP COMPLETE${NC}\n"
    echo "View full report: $REPORT_FILE"
    separator
}

create_helper_scripts() {
    log "Creating helper scripts..."

    # Create verification script based on selected tools
    local verify_tools=""
    [ "$INSTALL_NODEJS" == true ] && verify_tools+='check_tool "node"\ncheck_tool "npm"\ncheck_tool "npx"\ncheck_tool "pnpm"\ncheck_tool "bun"\n'
    [ "$INSTALL_GIT" == true ] && verify_tools+='check_tool "git"\n'
    [ "$INSTALL_GITHUB_CLI" == true ] && verify_tools+='check_tool "gh"\n'
    [ "$INSTALL_PYTHON" == true ] && verify_tools+='check_tool "uv"\n'

    cat > "$SCRIPT_DIR/verify-setup.sh" <<VERIFY_EOF
#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

check_tool() {
    local tool=\$1
    if command -v "\$tool" &> /dev/null; then
        local version=\$(\$tool --version 2>&1 | head -1)
        echo -e "\${GREEN}✓\${NC} \$tool: \$version"
        ((PASSED++))
    else
        echo -e "\${RED}✗\${NC} \$tool: NOT FOUND"
        ((FAILED++))
    fi
}

echo "Verifying Development Environment..."
echo "===================================="
$(echo -e "$verify_tools")
echo "===================================="
echo -e "Results: \${GREEN}\$PASSED passed\${NC}, \${RED}\$FAILED failed\${NC}"
[ \$FAILED -eq 0 ] && exit 0 || exit 1
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
    # Initialize log
    echo "Setup started at $(date)" > "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"

    # Show interactive menus
    show_bazzite_rebase_menu
    show_tool_selection_menu

    # Clear screen for main installation
    print_header
    echo -e "${GREEN}${BOLD}Starting Installation...${NC}\n"
    separator
    echo ""

    # Perform rebase if selected
    if [ "$REBASE_TO_DX" == true ]; then
        perform_rebase
        # Script will exit if rebase succeeds (requires reboot)
    fi

    # Pre-setup
    fix_permissions
    check_and_add_to_path

    # Main installation steps
    local total_steps=0
    [ "$INSTALL_NODEJS" == true ] && total_steps=$((total_steps + 6))  # NVM, Node, pnpm, bun, export, verify
    [ "$INSTALL_PYTHON" == true ] && total_steps=$((total_steps + 1))
    [ "$INSTALL_GIT" == true ] && total_steps=$((total_steps + 1))
    [ "$INSTALL_GITHUB_CLI" == true ] && total_steps=$((total_steps + 1))
    total_steps=$((total_steps + 3))  # host check, container, dependencies

    local current_step=0

    check_host_system && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    check_or_create_container && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    install_container_dependencies && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    install_git && ((current_step++)) || ((current_step++))
    [ "$INSTALL_GIT" == true ] && progress_bar $current_step $total_steps

    install_github_cli && ((current_step++)) || ((current_step++))
    [ "$INSTALL_GITHUB_CLI" == true ] && progress_bar $current_step $total_steps

    install_uv && ((current_step++)) || ((current_step++))
    [ "$INSTALL_PYTHON" == true ] && progress_bar $current_step $total_steps

    install_nvm && ((current_step++)) || ((current_step++))
    [ "$INSTALL_NODEJS" == true ] && progress_bar $current_step $total_steps

    install_nodejs && ((current_step++)) || ((current_step++))
    [ "$INSTALL_NODEJS" == true ] && progress_bar $current_step $total_steps

    install_pnpm && ((current_step++)) || ((current_step++))
    [ "$INSTALL_NODEJS" == true ] && progress_bar $current_step $total_steps

    install_bun && ((current_step++)) || ((current_step++))
    [ "$INSTALL_NODEJS" == true ] && progress_bar $current_step $total_steps

    export_binaries && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    verify_installation && ((current_step++)) || ((current_step++))
    progress_bar $current_step $total_steps

    # Post-setup
    create_helper_scripts

    # Generate report
    generate_report

    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

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
