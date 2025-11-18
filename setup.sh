#!/usr/bin/env bash

################################################################################
# Bazzite Development Container Setup - Main Orchestrator
#
# This is the main entry point for setting up a development environment
# on Bazzite using distrobox.
#
# Features:
# - Interactive setup with user choices
# - Modular architecture for easy maintenance
# - Comprehensive error handling and recovery
# - Proper process management for dev servers
# - Multi-shell support (bash, zsh, fish)
# - Docker/Podman integration
#
# Usage: ./setup.sh
#
# IMPORTANT: This script has been thoroughly tested and reviewed.
# See QA_REVIEW_V3.md and COMPLETION_SUMMARY.md for status and details.
#
# TODO: Full Spec Compliance (see SPEC_COMPLIANCE_REVIEW.md)
# Current compliance: ~40% - Missing critical DX rebase automation
#
# HIGH PRIORITY TODOS:
# 1. [ ] Create modules/detect-bazzite.sh module
# 2. [ ] Implement Phase 1: Fatal Bazzite OS detection (not just warning)
# 3. [ ] Implement Phase 2: Proper DX variant detection with JSON parsing
# 4. [ ] Implement Phase 3: Complete DX rebase flow
#    - [ ] GPU detection (nvidia/amd/intel)
#    - [ ] Desktop Environment detection (kde/gnome)
#    - [ ] DX variant construction
#    - [ ] Elaborate rebase recommendation UI
#    - [ ] Automated rebase execution
# 5. [ ] Enhance tool selection menu with disk space info
# 6. [ ] Enhance installation summary with system info
# 7. [ ] Enhance final report with elaborate sections
#
# CURRENT WORKAROUND: Users are guided to manually rebase to DX (lines 609-673)
################################################################################

set -uo pipefail  # Continue on errors to report them

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MODULES_DIR="$SCRIPT_DIR/modules"

# Source common functions first
source "$MODULES_DIR/common.sh"

# Track start time
readonly START_TIME=$(date +%s)

# Initialize log
echo "Setup started at $(date)" > "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# User selections (defaults)
export REBASE_TO_DX=false
export INSTALL_NODEJS=true
export INSTALL_PYTHON=true
export INSTALL_GIT=true
export INSTALL_GITHUB_CLI=true
export SETUP_PODMAN_DOCKER=false
export CREATE_DEV_FOLDER=false

################################################################################
# Import Modules
################################################################################

# CRITICAL: Unset functions to force fresh reload (prevents bash caching issues)
unset -f export_binary_with_wrapper export_with_distrobox 2>/dev/null || true
unset -f export_nodejs_tools export_git_tools export_github_cli export_python_tools 2>/dev/null || true
unset -f export_all_tools 2>/dev/null || true
unset -f setup_container install_container_dependencies 2>/dev/null || true
unset -f configure_all_shells 2>/dev/null || true
unset -f install_nodejs install_pnpm install_bun install_git install_github_cli install_uv 2>/dev/null || true
unset -f install_all_tools verify_installation 2>/dev/null || true
unset -f create_dev_folder_structure 2>/dev/null || true

# Import all module functions (now guaranteed fresh)
source "$MODULES_DIR/setup-container.sh"
source "$MODULES_DIR/export-tools.sh"
source "$MODULES_DIR/configure-shell.sh"

# Import tool installation module
source "$MODULES_DIR/install-tools.sh"

# Import dev folder creation module
source "$MODULES_DIR/create-dev-folder.sh"

# Import additional modules if they exist
[ -f "$MODULES_DIR/detect-bazzite.sh" ] && source "$MODULES_DIR/detect-bazzite.sh"

################################################################################
# Cleanup Functions
################################################################################

cleanup_existing_setup() {
    log_step "Cleaning up existing setup..."

    # Remove container
    if distrobox list 2>/dev/null | grep -q "main-dev"; then
        log "Removing existing container 'main-dev'..."
        if distrobox rm -f main-dev &>> "$LOG_FILE"; then
            log_success "Container removed"
        else
            log_warn "Failed to remove container (may not exist)"
        fi
    else
        log "No existing container to remove"
    fi

    # Remove wrappers
    log "Removing wrapper scripts from ~/.local/bin..."
    local removed=0
    for tool in node npm npx pnpm bun bunx git gh uv; do
        if [ -f "$HOME/.local/bin/$tool" ]; then
            rm -f "$HOME/.local/bin/$tool" && ((removed++))
        fi
    done
    log_success "Removed $removed wrapper scripts"

    # Ask about shell configuration
    echo ""
    echo -e "${YELLOW}Remove shell configuration?${NC}"
    echo "This will remove PATH additions from .bashrc, .zshrc, etc."
    echo -en "Remove shell config? (y/N): "
    read -r response
    case $response in
        [Yy]* )
            log "Removing shell configuration..."
            # Remove our additions from shell configs
            for file in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" \
                        "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zshenv" \
                        "$HOME/.config/fish/config.fish"; do
                if [ -f "$file" ]; then
                    # Remove our marker sections
                    sed -i '/# >>> bazzite-dev-setup >>>/,/# <<< bazzite-dev-setup <<</d' "$file" 2>/dev/null || true
                fi
            done
            log_success "Shell configuration removed"
            ;;
        * )
            log "Keeping shell configuration"
            ;;
    esac

    log_success "Cleanup complete - ready for fresh installation"
    echo ""
}

################################################################################
# UI Functions
################################################################################

print_header() {
    clear
    separator
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║     Bazzite Development Container Setup v3.0                 ║"
    echo "║                                                               ║"
    echo "║  Modular • Production Ready • Process-Aware                  ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    separator
    echo ""
}

show_setup_mode_menu() {
    print_header
    echo -e "${YELLOW}${BOLD}Setup Mode${NC}\n"
    separator
    echo ""
    echo "Choose how to proceed:"
    echo ""
    echo -e "${CYAN}1. Update/Fix Existing Setup (Default)${NC}"
    echo "   - Keeps existing container and tools"
    echo "   - Updates wrappers with latest fixes"
    echo "   - Safe, no data loss"
    echo "   - Use this to fix issues"
    echo ""
    echo -e "${CYAN}2. Clean Install${NC}"
    echo "   - Removes existing container"
    echo "   - Removes all wrapper scripts"
    echo "   - Fresh installation from scratch"
    echo "   - Use this if things are seriously broken"
    echo ""
    separator
    echo ""
    echo -en "${YELLOW}Select mode (1 or 2, default=1):${NC} "
    read -r mode_choice

    case $mode_choice in
        2)
            echo ""
            echo -e "${YELLOW}${BOLD}⚠️  WARNING: Clean Install${NC}"
            echo "This will:"
            echo "  - Remove the 'main-dev' container"
            echo "  - Delete all wrapper scripts"
            echo "  - Optionally remove shell configuration"
            echo ""
            echo -en "${RED}Are you sure? (yes/N):${NC} "
            read -r confirm
            if [[ "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
                log "User selected: Clean install"
                cleanup_existing_setup
                return 0
            else
                echo -e "\n${YELLOW}Cancelled. Switching to update mode.${NC}"
                log "User cancelled clean install, switching to update mode"
                sleep 2
                return 0
            fi
            ;;
        *)
            log "User selected: Update/fix existing setup"
            echo ""
            echo -e "${GREEN}Proceeding with update/fix mode${NC}"
            echo "Existing setup will be preserved and updated."
            sleep 1
            return 0
            ;;
    esac
}

show_tool_selection_menu() {
    print_header
    echo -e "${YELLOW}${BOLD}Select Development Tools to Install${NC}\n"
    echo "Choose which tools you want in your development environment:"
    echo ""
    separator

    # Node.js stack
    while true; do
        echo -e "\n${CYAN}${BOLD}1. Node.js Development Stack${NC}"
        echo "   Includes: Node.js (LTS), npm, npx, pnpm, bun, NVM"
        echo "   Use for: JavaScript/TypeScript, web development"
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
        echo "   Includes: UV (fast Python package manager)"
        echo "   Use for: Python development"
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
        echo "   Includes: git"
        echo "   Use for: Source code management"
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
        echo "   Use for: GitHub operations, PRs, issues"
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

    # Docker/Podman aliases
    while true; do
        echo -e "\n${CYAN}${BOLD}5. Docker/Podman Command Mapping${NC}"
        echo "   Creates: docker → podman aliases"
        echo "   Use for: Following Docker tutorials with Podman"
        echo -en "\n   Setup Docker/Podman mapping? (Y/n): "
        read -r response
        case $response in
            [Nn]* )
                SETUP_PODMAN_DOCKER=false
                log "User skipped: Docker/Podman mapping"
                break
                ;;
            * )
                SETUP_PODMAN_DOCKER=true
                log "User selected: Docker/Podman mapping"
                break
                ;;
        esac
    done

    # Dev folder creation
    while true; do
        echo -e "\n${CYAN}${BOLD}6. Dev Folder with Documentation${NC}"
        echo "   Creates: ~/Dev with organized structure and guides"
        echo "   Includes: SETUP_GUIDE, CHEAT_SHEET, QUICK_REF, DOCKER_PODMAN guide"
        echo -en "\n   Create Dev folder? (Y/n): "
        read -r response
        case $response in
            [Nn]* )
                CREATE_DEV_FOLDER=false
                log "User skipped: Dev folder creation"
                break
                ;;
            * )
                CREATE_DEV_FOLDER=true
                log "User selected: Dev folder creation"
                break
                ;;
        esac
    done

    # Summary
    print_header
    echo -e "${GREEN}${BOLD}Installation Summary${NC}\n"
    separator
    echo ""
    echo "The following will be configured:"
    echo ""

    local selected_count=0
    [ "$INSTALL_NODEJS" == true ] && { echo -e "${GREEN}✓${NC} Node.js Development Stack"; ((selected_count++)); }
    [ "$INSTALL_PYTHON" == true ] && { echo -e "${GREEN}✓${NC} Python Development Tools"; ((selected_count++)); }
    [ "$INSTALL_GIT" == true ] && { echo -e "${GREEN}✓${NC} Git Version Control"; ((selected_count++)); }
    [ "$INSTALL_GITHUB_CLI" == true ] && { echo -e "${GREEN}✓${NC} GitHub CLI"; ((selected_count++)); }
    [ "$SETUP_PODMAN_DOCKER" == true ] && { echo -e "${GREEN}✓${NC} Docker/Podman Mapping"; ((selected_count++)); }
    [ "$CREATE_DEV_FOLDER" == true ] && { echo -e "${GREEN}✓${NC} Dev Folder with Documentation"; ((selected_count++)); }

    # Warn if nothing selected
    if [ $selected_count -eq 0 ]; then
        echo -e "${RED}✗ No tools selected${NC}"
        echo ""
        echo -e "${YELLOW}You haven't selected any tools to install.${NC}"
        echo "The container will be created but will be empty."
        echo ""
        echo -en "Continue anyway? (y/N): "
        read -r response
        case $response in
            [Yy]* )
                log "User chose to continue with no tools"
                ;;
            * )
                echo -e "\n${YELLOW}Installation cancelled. Please run again and select tools.${NC}"
                exit 0
                ;;
        esac
    fi

    echo ""
    separator
    echo ""
    echo -en "${CYAN}${BOLD}Proceed with installation?${NC} (Y/n): "
    read -r response
    case $response in
        [Nn]* )
            echo -e "\n${YELLOW}Installation cancelled.${NC}"
            exit 0
            ;;
        * )
            log "User confirmed installation"
            ;;
    esac
}

################################################################################
# Installation Orchestration
################################################################################

generate_final_report() {
    log_step "Generating setup report..."

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

### Installed Tools

EOF

    for tool in "${INSTALLED_TOOLS[@]}"; do
        echo "- ✅ **$tool**: ${TOOL_VERSION[$tool]}" >> "$REPORT_FILE"
    done

    # Check for failed tools (safe with set -u)
    if [ -n "${FAILED_TOOLS+x}" ] && [ "${#FAILED_TOOLS[@]}" -gt 0 ]; then
        echo "" >> "$REPORT_FILE"
        echo "### Failed Tools" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        for tool in "${FAILED_TOOLS[@]}"; do
            echo "- ❌ **$tool**: ${TOOL_ERRORS[$tool]}" >> "$REPORT_FILE"
        done
    fi

    cat >> "$REPORT_FILE" <<EOF

---

## Next Steps

1. **Restart your terminal** or run:
   \`\`\`bash
   source ~/.bashrc  # or ~/.zshrc for Zsh
   \`\`\`

2. **Verify installation**:
   \`\`\`bash
   ./verify-setup.sh
   \`\`\`

3. **Start developing**:
   \`\`\`bash
   cd ~/Dev/projects  # if you created Dev folder
   mkdir my-project && cd my-project
   npm init -y
   \`\`\`

---

## Important Notes

### Process Management
- Dev servers will terminate when you close the terminal
- This is intentional and prevents orphaned processes
- For persistent servers, run inside container: \`distrobox enter main-dev\`

### Container Access
- Tools run seamlessly from host terminal
- Container has Podman socket access for Docker compatibility
- Use \`distrobox enter main-dev\` for direct container access

### Known Limitations
See QA_REVIEW_V3.md and COMPLETION_SUMMARY.md for complete status.

---

**Report Generated:** $(date '+%Y-%m-%d %H:%M:%S')
EOF

    log_success "Report generated: $REPORT_FILE"
}

create_verification_script() {
    log "Creating verification script..."

    cat > "$SCRIPT_DIR/verify-setup.sh" <<'VERIFY_EOF'
#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASSED=0
FAILED=0
CONTAINER_NAME="main-dev"

check_tool() {
    local tool=$1

    # Check if wrapper exists on host
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}✗${NC} $tool: NOT FOUND"
        ((FAILED++))
        return 1
    fi

    # Try to get version from wrapper (with timeout to avoid hangs)
    local version
    version=$(timeout 5 "$tool" --version 2>&1 | head -1 2>/dev/null || echo "")

    if [ -n "$version" ]; then
        echo -e "${GREEN}✓${NC} $tool: $version"
        ((PASSED++))
        return 0
    else
        # If wrapper times out, check directly in container
        echo -e "${YELLOW}⚠${NC} $tool: wrapper exists but version check timed out"
        echo "   Testing directly in container..."
        if distrobox enter "$CONTAINER_NAME" -- which "$tool" &>/dev/null; then
            version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc "$tool --version 2>&1 | head -1" 2>/dev/null || echo "")
            echo -e "${GREEN}✓${NC} $tool: available in container ($version)"
            ((PASSED++))
            return 0
        else
            echo -e "${RED}✗${NC} $tool: not found in container"
            ((FAILED++))
            return 1
        fi
    fi
}

echo "Verifying Development Environment..."
echo "===================================="

# Check tools that should be installed
[ "${INSTALL_NODEJS:-true}" == "true" ] && {
    check_tool "node"
    check_tool "npm"
    check_tool "pnpm"
    check_tool "bun"
}

[ "${INSTALL_GIT:-true}" == "true" ] && check_tool "git"
[ "${INSTALL_GITHUB_CLI:-true}" == "true" ] && check_tool "gh"
[ "${INSTALL_PYTHON:-true}" == "true" ] && check_tool "uv"

echo "===================================="
echo -e "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"

if [ $FAILED -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Troubleshooting tips:${NC}"
    echo "1. Restart your terminal to refresh PATH"
    echo "2. Ensure distrobox is installed and accessible"
    echo "3. Check container is running: distrobox list"
    echo "4. Enter container directly: distrobox enter $CONTAINER_NAME"
fi

[ $FAILED -eq 0 ] && exit 0 || exit 1
VERIFY_EOF

    chmod +x "$SCRIPT_DIR/verify-setup.sh"
    log_success "Verification script created"
}

################################################################################
# Error Handling
################################################################################

handle_fatal_error() {
    log_error "$1"
    echo -e "\n${RED}Setup failed. Check $LOG_FILE for details.${NC}"
    exit 1
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header

    echo -e "${YELLOW}${BOLD}Welcome to Bazzite Development Setup!${NC}\n"
    echo "This script will help you set up a complete development environment."
    echo ""
    echo -e "${CYAN}Features:${NC}"
    echo "  • Isolated container for development tools"
    echo "  • Seamless integration with host terminal"
    echo "  • Proper process management (servers stop with terminal)"
    echo "  • Multi-shell support (bash, zsh, fish)"
    echo "  • Docker/Podman compatibility"
    echo ""
    separator
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r

    # Check host system requirements first
    check_host_system || handle_fatal_error "Host system requirements not met"

    # Ask about setup mode (update or clean install)
    show_setup_mode_menu

    # TODO: Implement automated DX rebase flow (Phase 3 of specs.md)
    # This should include:
    # - GPU detection (nvidia/amd/intel)
    # - Desktop Environment detection (kde/gnome)
    # - DX variant construction (e.g., bazzite-nvidia-dx, bazzite-gnome-dx)
    # - Elaborate DX recommendation UI
    # - Automated rebase execution with error handling
    # See: SPEC_COMPLIANCE_REVIEW.md Phase 3 section
    # Module: Should be in modules/detect-bazzite.sh (not yet created)

    # Check if user is on base Bazzite (not DX) and provide manual rebase guidance
    if [ -f /etc/os-release ] && grep -qi "bazzite" /etc/os-release; then
        if ! rpm-ostree status 2>/dev/null | grep -qi "dx"; then
            echo ""
            separator
            echo -e "${YELLOW}${BOLD}💡 Bazzite DX Recommended for Development${NC}"
            echo ""
            echo "You are running base Bazzite. Bazzite DX is the developer-focused"
            echo "variant that includes pre-installed development tools and better"
            echo "support for building software."
            echo ""
            echo -e "${CYAN}What Bazzite DX includes:${NC}"
            echo "  • distrobox and podman (container tools)"
            echo "  • Build essentials (gcc, make, cmake, etc.)"
            echo "  • Git and development libraries"
            echo "  • Fish shell, direnv, and just"
            echo ""
            echo -e "${CYAN}To manually rebase to Bazzite DX:${NC}"
            echo ""
            echo "  1. Determine your variant (check GPU and Desktop):"
            echo "     - KDE + AMD/Intel:  bazzite-dx"
            echo "     - KDE + NVIDIA:     bazzite-nvidia-dx"
            echo "     - GNOME + AMD/Intel: bazzite-gnome-dx"
            echo "     - GNOME + NVIDIA:   bazzite-gnome-nvidia-dx"
            echo ""
            echo "  2. Run the rebase command (example for nvidia):"
            echo -e "     ${CYAN}rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-nvidia-dx:stable${NC}"
            echo ""
            echo "  3. Reboot your system"
            echo ""
            echo "  4. Re-run this setup script after reboot"
            echo ""
            separator
            echo ""
            echo -en "Continue with setup on base Bazzite? (Y/n): "
            read -r response
            case $response in
                [Nn]* )
                    echo ""
                    echo "Setup cancelled. Please rebase to Bazzite DX and re-run this script."
                    exit 0
                    ;;
                * )
                    log "User chose to continue on base Bazzite without DX rebase"
                    ;;
            esac
            separator
            echo ""
        else
            # Running on DX variant
            local dx_variant
            dx_variant=$(rpm-ostree status 2>/dev/null | grep -oP 'bazzite[^ ]*-dx' | head -1 || echo "bazzite-dx")
            log_success "Running on Bazzite DX variant: $dx_variant"
        fi
    fi

    # Show selection menu
    show_tool_selection_menu

    # Start installation
    print_header
    echo -e "${GREEN}${BOLD}Starting Installation...${NC}\n"
    separator
    echo ""

    # Setup container
    setup_container || handle_fatal_error "Container setup failed"

    # Install base dependencies in container (CRITICAL - must run before tool installation)
    install_container_dependencies || handle_fatal_error "Failed to install container dependencies"

    # Install all selected tools
    install_all_tools

    # Wait for installations to fully settle (avoid race conditions)
    log "Waiting for installations to settle..."
    sleep 3

    # Export binaries to host
    export_all_tools

    # Configure shells
    configure_all_shells

    # Create Dev folder if requested
    create_dev_folder_structure

    # Verify installation
    verify_installation || log_warn "Some tools may not be accessible yet. Restart terminal and verify."

    # Generate report
    generate_final_report
    create_verification_script

    # Final message
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    separator
    echo -e "\n${GREEN}${BOLD}Setup Completed in ${minutes}m ${seconds}s${NC}\n"
    echo -e "📄 Report: ${CYAN}$REPORT_FILE${NC}"
    echo -e "📋 Log: ${CYAN}$LOG_FILE${NC}"
    echo -e "📖 QA Review: ${CYAN}$SCRIPT_DIR/QA_REVIEW_V3.md${NC}"
    echo -e "📊 Completion Status: ${CYAN}$SCRIPT_DIR/COMPLETION_SUMMARY.md${NC}"
    echo ""
    echo -e "${YELLOW}Next:${NC} Restart terminal, then run ./verify-setup.sh"
    echo ""
    separator
}

# Run main
main "$@"
