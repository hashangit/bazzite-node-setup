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

# Import all module functions
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

    if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
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
NC='\033[0m'

PASSED=0
FAILED=0

check_tool() {
    local tool=$1
    if command -v "$tool" &> /dev/null; then
        local version=$($tool --version 2>&1 | head -1)
        echo -e "${GREEN}✓${NC} $tool: $version"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $tool: NOT FOUND"
        ((FAILED++))
        return 1
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

[ $FAILED -eq 0 ] && exit 0 || exit 1
VERIFY_EOF

    chmod +x "$SCRIPT_DIR/verify-setup.sh"
    log_success "Verification script created"
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
    check_host_system || {
        log_error "Host system requirements not met"
        echo -e "\n${RED}Setup cancelled. Please fix the issues above.${NC}"
        exit 1
    }

    # Check if user might want Bazzite DX (only if on base Bazzite)
    if [ -f /etc/os-release ] && grep -qi "bazzite" /etc/os-release; then
        if ! rpm-ostree status 2>/dev/null | grep -qi "dx"; then
            echo ""
            separator
            echo -e "${YELLOW}${BOLD}💡 Note: Base Bazzite Detected (Not DX)${NC}"
            echo ""
            echo "You are running base Bazzite. Bazzite DX includes additional"
            echo "developer tools and is recommended for development."
            echo ""
            echo "v3.0 does not include the DX rebase feature yet."
            echo -e "To rebase to DX, run: ${CYAN}./setup-dev-container.sh${NC} (v2.0) first,"
            echo "or manually rebase using rpm-ostree."
            echo ""
            echo -en "Continue with v3.0 setup anyway? (Y/n): "
            read -r response
            case $response in
                [Nn]* )
                    echo ""
                    echo "Setup cancelled. Run ./setup-dev-container.sh for DX rebase."
                    exit 0
                    ;;
                * )
                    log "User chose to continue without DX rebase"
                    ;;
            esac
            separator
            echo ""
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
    setup_container || {
        log_error "Container setup failed"
        echo -e "\n${RED}Setup failed. Check $LOG_FILE for details.${NC}"
        exit 1
    }

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
