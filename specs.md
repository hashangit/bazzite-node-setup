Bazzite Development Environment Setup - Technical Specification
Document Version

Version: 4.0
Date: 2025-01-18
Status: Specification
1. Overview
1.1 Purpose

This specification defines the complete workflow for setting up a containerized development environment on Bazzite OS using distrobox, with intelligent system detection, automatic DX variant recommendations, and comprehensive tool installation.
1.2 Key Features

    Automatic Bazzite and Bazzite DX detection
    Intelligent GPU and Desktop Environment detection
    Automated DX rebase recommendations
    Containerized tool isolation (Ubuntu 24.04 in distrobox)
    Process-aware binary wrappers for clean server termination
    Multi-shell support (bash, zsh, fish)
    Docker/Podman compatibility layer
    Comprehensive documentation generation

2. System Requirements Check Flow
2.1 Phase 1: Bazzite OS Detection (CRITICAL - FIRST CHECK)

Objective: Verify the host is running Bazzite OS

Process:

1. Check /etc/os-release file exists
2. Parse file and check if NAME or ID contains "bazzite"
3. Decision:
   - IF Bazzite detected:
     → Log success: "✓ Running on Bazzite"
     → PROCEED to Phase 2
   
   - IF NOT Bazzite:
     → Display error message:
       ╔═══════════════════════════════════════════════════════════════╗
       ║                     NOT BAZZITE DETECTED                      ║
       ╚═══════════════════════════════════════════════════════════════╝
       
       This setup tool is specifically designed for Bazzite OS.
       
       Current system: <detected OS name>
       
       This tool uses Bazzite-specific features and configurations
       that may not work correctly on other distributions.
       
       For installation on other systems, please refer to:
       • General Linux setup: docs/GENERAL_LINUX_SETUP.md
       • Manual installation: docs/MANUAL_INSTALLATION.md
       • Distrobox documentation: https://distrobox.it
       
       Setup cannot continue.
     
     → Log error: "Not running on Bazzite - exiting"
     → EXIT with code 1

Implementation:

check_bazzite_os() {
    log_step "Checking if running on Bazzite OS..."
    
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot find /etc/os-release"
        display_not_bazzite_error "Unknown OS"
        return 1
    fi
    
    source /etc/os-release
    
    if ! echo "$NAME" | grep -qi "bazzite"; then
        log_error "Not running on Bazzite OS"
        display_not_bazzite_error "$NAME"
        return 1
    fi
    
    log_success "Bazzite OS detected: $NAME"
    return 0
}

2.2 Phase 2: Bazzite DX Variant Detection

Objective: Determine if running Bazzite DX or base Bazzite

Process:

1. Get current OSTree deployment using rpm-ostree status
2. Parse deployment origin string
3. Check if origin contains "-dx" suffix
4. Decision:
   
   - IF DX variant detected:
     → Log: "✓ Running Bazzite DX: <variant-name>"
     → Display confirmation:
       ╔═══════════════════════════════════════════════════════════════╗
       ║              BAZZITE DX DETECTED - READY TO GO                ║
       ╚═══════════════════════════════════════════════════════════════╝
       
       Current variant: <full-variant-name>
       
       Your system is already running Bazzite DX with:
       ✓ Developer tools and libraries pre-installed
       ✓ distrobox and podman included
       ✓ Optimized for development workflows
       
       Press Enter to continue with tool installation...
     
     → PROCEED to Phase 4 (Tool Installation)
   
   - IF base Bazzite (NOT DX):
     → PROCEED to Phase 3 (DX Rebase Flow)

Implementation:

detect_bazzite_variant() {
    log_step "Detecting Bazzite variant..."
    
    local current_deployment
    current_deployment=$(rpm-ostree status --json 2>/dev/null | \
                        jq -r '.deployments[0].origin' 2>/dev/null || echo "")
    
    if [ -z "$current_deployment" ]; then
        log_error "Cannot determine current deployment"
        return 1
    fi
    
    log "Current deployment: $current_deployment"
    
    if echo "$current_deployment" | grep -q "\-dx"; then
        log_success "Bazzite DX variant detected"
        return 0  # Is DX
    else
        log "Base Bazzite detected (not DX variant)"
        return 1  # Not DX
    fi
}

2.3 Phase 3: DX Rebase Flow (Only if NOT DX)

Objective: Intelligently recommend and perform DX rebase
2.3.1 System Detection

GPU Detection:

detect_gpu_vendor() {
    log "Detecting GPU vendor..."
    
    local gpu_info
    gpu_info=$(lspci | grep -i vga)
    
    if echo "$gpu_info" | grep -qi nvidia; then
        echo "nvidia"
        log "✓ GPU: NVIDIA detected"
    elif echo "$gpu_info" | grep -qi amd; then
        echo "amd"
        log "✓ GPU: AMD detected"
    elif echo "$gpu_info" | grep -qi intel; then
        echo "intel"
        log "✓ GPU: Intel detected"
    else
        # Default to AMD/Intel (open-source drivers)
        echo "amd"
        log_warn "GPU vendor unclear, defaulting to AMD (open drivers)"
    fi
}

Desktop Environment Detection:

detect_desktop_environment() {
    log "Detecting desktop environment..."
    
    # Method 1: Check XDG_CURRENT_DESKTOP
    if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
        if echo "$XDG_CURRENT_DESKTOP" | grep -qi "kde\|plasma"; then
            echo "kde"
            log "✓ Desktop: KDE Plasma (from XDG_CURRENT_DESKTOP)"
            return 0
        elif echo "$XDG_CURRENT_DESKTOP" | grep -qi "gnome"; then
            echo "gnome"
            log "✓ Desktop: GNOME (from XDG_CURRENT_DESKTOP)"
            return 0
        fi
    fi
    
    # Method 2: Check running processes
    if pgrep -x "plasmashell" > /dev/null; then
        echo "kde"
        log "✓ Desktop: KDE Plasma (from running process)"
        return 0
    elif pgrep -x "gnome-shell" > /dev/null; then
        echo "gnome"
        log "✓ Desktop: GNOME (from running process)"
        return 0
    fi
    
    # Method 3: Check deployment name
    local deployment
    deployment=$(rpm-ostree status --json 2>/dev/null | \
                jq -r '.deployments[0].origin' 2>/dev/null || echo "")
    
    if echo "$deployment" | grep -q "gnome"; then
        echo "gnome"
        log "✓ Desktop: GNOME (from deployment name)"
    else
        echo "kde"
        log "✓ Desktop: KDE Plasma (default for Bazzite)"
    fi
}

2.3.2 DX Variant Construction

Variant Naming Logic:

Format: bazzite[-gnome][-nvidia]-dx

Examples:
- KDE + AMD/Intel    → bazzite-dx
- KDE + NVIDIA       → bazzite-nvidia-dx
- GNOME + AMD/Intel  → bazzite-gnome-dx
- GNOME + NVIDIA     → bazzite-gnome-nvidia-dx

Implementation:

construct_dx_variant() {
    local de=$1      # "kde" or "gnome"
    local gpu=$2     # "nvidia", "amd", or "intel"
    
    local variant="bazzite"
    
    # Add GNOME if not KDE
    if [ "$de" == "gnome" ]; then
        variant="${variant}-gnome"
    fi
    
    # Add NVIDIA if needed
    if [ "$gpu" == "nvidia" ]; then
        variant="${variant}-nvidia"
    fi
    
    # Add DX suffix
    variant="${variant}-dx"
    
    echo "$variant"
}

2.3.3 User Confirmation Flow

Display:

╔═══════════════════════════════════════════════════════════════╗
║            BAZZITE DX REBASE RECOMMENDED                      ║
╚═══════════════════════════════════════════════════════════════╝

Current Version: bazzite (Base)
Recommended:     bazzite-nvidia-dx

═══════════════════════════════════════════════════════════════

DETECTED SYSTEM CONFIGURATION:

  Desktop Environment:  KDE Plasma
  GPU Vendor:          NVIDIA GeForce RTX 3080
  Recommended Variant: bazzite-nvidia-dx

═══════════════════════════════════════════════════════════════

WHAT IS BAZZITE DX?

Bazzite DX is the developer-focused variant that includes:

  ✓ Development Tools & Libraries
    • gcc, g++, make, cmake, and build essentials
    • Development headers for system libraries
    • Git, curl, wget pre-installed
    
  ✓ Container Tools
    • distrobox (seamless container integration)
    • podman (Docker-compatible container runtime)
    • docker-compose compatibility
    
  ✓ Additional CLI Tools
    • Fish shell
    • direnv (environment management)
    • just (command runner)
    
  ✓ Development-Optimized Configuration
    • Extended timeout for compilation tasks
    • Pre-configured development workflows
    • Better suited for building software

═══════════════════════════════════════════════════════════════

REBASE PROCESS:

  1. Download DX variant image (~2-5 minutes)
  2. Apply changes to system (~1-2 minutes)
  3. Reboot required to activate DX variant
  4. After reboot, re-run this script to install dev tools

Total time: ~5-10 minutes
Disk space needed: ~2GB

IMPORTANT NOTES:

  ⚠  System will download and stage the DX variant
  ⚠  A reboot is REQUIRED after rebase completes
  ⚠  You can rollback anytime with: rpm-ostree rollback
  ⚠  Current system state is preserved as rollback point

═══════════════════════════════════════════════════════════════

Would you like to rebase to Bazzite DX? (y/N): _

User Decision Tree:

IF user enters 'y' or 'yes':
  → Set REBASE_TO_DX=true
  → Set REBASE_TARGET="bazzite-nvidia-dx"
  → PROCEED to Phase 3.4 (Rebase Execution)

IF user enters 'n' or 'no':
  → Display:
    ╔═══════════════════════════════════════════════════════╗
    ║         CONTINUING WITHOUT DX REBASE                  ║
    ╚═══════════════════════════════════════════════════════╝
    
    You chose to continue with base Bazzite.
    
    The setup will now verify and install required tools:
    • distrobox (if not present)
    • podman (if not present)
    • Development dependencies
    
    Note: Some features may require manual installation.
  
  → Set REBASE_TO_DX=false
  → PROCEED to Phase 3.5 (Manual System Checks)

IF user enters anything else:
  → Display: "Please answer y or n"
  → Re-prompt

2.3.4 Rebase Execution (If User Approved)

Process:

perform_rebase() {
    log_step "Rebasing to Bazzite DX..."
    
    local target="$REBASE_TARGET"
    local rebase_cmd="rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/${target}:stable"
    
    echo ""
    separator
    echo -e "${CYAN}Rebasing to:${NC} ${GREEN}${target}:stable${NC}"
    echo -e "${CYAN}Command:${NC} $rebase_cmd"
    separator
    echo ""
    
    echo -e "${YELLOW}This will take 5-10 minutes...${NC}"
    echo -e "${YELLOW}Download progress will be shown below:${NC}"
    echo ""
    
    # Execute rebase with output visible to user
    if $rebase_cmd 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Rebase completed successfully!"
        
        echo ""
        separator
        echo -e "${GREEN}${BOLD}✓ REBASE TO BAZZITE DX COMPLETED${NC}"
        separator
        echo ""
        echo "New variant: ${GREEN}${target}:stable${NC}"
        echo ""
        echo -e "${RED}${BOLD}⚠  REBOOT REQUIRED TO ACTIVATE${NC}"
        echo ""
        echo "After rebooting:"
        echo "  1. Your system will be running Bazzite DX"
        echo "  2. Re-run this script to install development tools"
        echo "  3. All your data and settings are preserved"
        echo ""
        separator
        echo ""
        
        # Offer immediate reboot
        while true; do
            echo -en "${CYAN}${BOLD}Reboot now?${NC} (y/N): "
            read -r response
            case $response in
                [Yy]*)
                    log "User chose to reboot immediately"
                    echo ""
                    echo -e "${GREEN}Rebooting in 5 seconds...${NC}"
                    echo "Press Ctrl+C to cancel"
                    sleep 5
                    systemctl reboot
                    exit 0
                    ;;
                *)
                    log "User chose to reboot later"
                    echo ""
                    echo -e "${YELLOW}Please reboot when ready:${NC}"
                    echo "  systemctl reboot"
                    echo ""
                    echo "Then re-run this script to complete setup."
                    exit 0
                    ;;
            esac
        done
    else
        log_error "Rebase failed"
        
        echo ""
        separator
        echo -e "${RED}${BOLD}✗ REBASE FAILED${NC}"
        separator
        echo ""
        echo "Check the log for details: $LOG_FILE"
        echo ""
        echo "Common issues:"
        echo "  • Network connectivity problems"
        echo "  • Insufficient disk space"
        echo "  • Invalid variant name"
        echo ""
        echo "You can try manually:"
        echo "  $rebase_cmd"
        echo ""
        
        # Offer to continue without DX
        while true; do
            echo -en "${CYAN}Continue with base Bazzite setup anyway?${NC} (y/N): "
            read -r response
            case $response in
                [Yy]*)
                    log "User chose to continue despite rebase failure"
                    return 0  # Continue to manual checks
                    ;;
                *)
                    log "User cancelled after rebase failure"
                    exit 1
                    ;;
            esac
        done
    fi
}

2.3.5 Manual System Checks (If User Declined DX or Rebase Failed)

Objective: Verify and install required tools on base Bazzite

Process:

1. Check distrobox:
   - Command: command -v distrobox
   - IF NOT FOUND:
     → Display:
       distrobox is not installed.
       
       Installing distrobox is required for this setup.
       
       Install command:
         rpm-ostree install distrobox
         systemctl reboot
       
       After reboot, re-run this script.
     
     → EXIT with code 1
   
   - IF FOUND:
     → Get version: distrobox version
     → Log: "✓ distrobox version X.Y.Z found"

2. Check podman:
   - Command: command -v podman
   - IF NOT FOUND:
     → Display warning:
       podman is not installed.
       
       podman provides Docker-compatible container runtime.
       
       Install command:
         rpm-ostree install podman
         systemctl reboot
       
       Continue without podman? (y/N):
     
     → IF user declines: EXIT
     → IF user accepts: Log warning and continue
   
   - IF FOUND:
     → Get version: podman --version
     → Log: "✓ podman version X.Y.Z found"
     → Check podman socket:
       • Check: /run/user/$UID/podman/podman.sock exists
       • IF NOT: Offer to start: systemctl --user start podman.socket

3. Check disk space:
   - Command: df -BG $HOME
   - Minimum required: 5GB
   - IF < 5GB:
     → Display error:
       Insufficient disk space: X GB available
       Minimum required: 5 GB
       
       Free up space and try again.
     → EXIT with code 1
   
   - IF >= 5GB:
     → Log: "✓ Sufficient disk space: X GB available"

4. All checks passed:
   → Log: "✓ All system requirements met"
   → PROCEED to Phase 4 (Tool Installation)

2.4 Decision Flow Diagram

START
  ↓
[Check: Is Bazzite?]
  ├─ NO → Display "Not Bazzite" error → EXIT(1)
  └─ YES → Log "✓ Bazzite detected"
      ↓
  [Check: Is DX variant?]
      ├─ YES → Display "✓ DX detected" → GOTO Tool Installation (Phase 4)
      └─ NO → Log "Base Bazzite detected"
          ↓
      [Detect GPU and Desktop]
          ↓
      [Construct recommended DX variant]
          ↓
      [Display DX rebase recommendation]
          ↓
      [Ask user: Rebase to DX?]
          ├─ YES → [Perform rebase]
          │         ├─ SUCCESS → Display "Reboot required" → EXIT(0)
          │         └─ FAILED → [Ask: Continue anyway?]
          │                       ├─ YES → GOTO Manual Checks
          │                       └─ NO → EXIT(1)
          └─ NO → Display "Continuing without DX"
              ↓
          [Manual System Checks]
              ├─ Check distrobox
              │   ├─ NOT FOUND → Display install instructions → EXIT(1)
              │   └─ FOUND → Continue
              ├─ Check podman
              │   ├─ NOT FOUND → [Ask: Continue without podman?]
              │   │                ├─ YES → Log warning, continue
              │   │                └─ NO → EXIT(1)
              │   └─ FOUND → Check socket availability
              └─ Check disk space
                  ├─ < 5GB → Display error → EXIT(1)
                  └─ >= 5GB → Continue
                      ↓
                  [All checks passed]
                      ↓
                  GOTO Tool Installation (Phase 4)

3. Tool Installation Phase
3.1 Interactive Tool Selection

Display Enhanced Selection Menu:

╔═══════════════════════════════════════════════════════════════╗
║              SELECT DEVELOPMENT TOOLS TO INSTALL              ║
╚═══════════════════════════════════════════════════════════════╝

Configure your development environment by selecting the tools
you need. Each tool will be installed in an isolated container
and seamlessly integrated with your host system.

═══════════════════════════════════════════════════════════════

1. NODE.JS DEVELOPMENT STACK

   Includes:
   • Node.js (LTS version via NodeSource)
   • npm (Node package manager)
   • npx (Package executor)
   • pnpm (Fast, efficient package manager)
   • bun (Ultra-fast all-in-one JavaScript runtime)
   
   Use for:
   • JavaScript/TypeScript development
   • Web applications (React, Vue, Angular)
   • Backend APIs (Express, Fastify)
   • Build tools and automation
   
   Disk space: ~500MB
   
   Install Node.js stack? (Y/n): _

═══════════════════════════════════════════════════════════════

2. PYTHON DEVELOPMENT TOOLS

   Includes:
   • UV (Modern, fast Python package manager)
     - Replaces pip with 10-100x faster performance
     - Better dependency resolution
     - Virtual environment management
   
   Use for:
   • Python development
   • Data science and ML projects
   • Automation scripts
   
   Disk space: ~100MB
   
   Install Python tools? (Y/n): _

═══════════════════════════════════════════════════════════════

3. VERSION CONTROL - GIT

   Includes:
   • git (Distributed version control system)
   
   Use for:
   • Source code management
   • Collaboration and versioning
   • Integration with GitHub, GitLab, etc.
   
   Disk space: ~50MB
   
   Install Git? (Y/n): _

═══════════════════════════════════════════════════════════════

4. GITHUB CLI

   Includes:
   • gh (Official GitHub command-line tool)
   
   Use for:
   • Managing repositories, PRs, issues
   • GitHub Actions workflows
   • Authentication and permissions
   
   Requires: Git (will be installed if selected)
   Disk space: ~30MB
   
   Install GitHub CLI? (Y/n): _

═══════════════════════════════════════════════════════════════

5. DOCKER/PODMAN COMMAND MAPPING

   Configuration:
   • Creates aliases: docker → podman
   • Creates aliases: docker-compose → podman-compose
   • Added to all shell configurations
   
   Use for:
   • Following Docker tutorials using Podman
   • Running Docker Compose files
   • Container development workflows
   
   Note: Podman is Docker-compatible and often more secure!
   Disk space: 0MB (configuration only)
   
   Setup Docker/Podman mapping? (Y/n): _

═══════════════════════════════════════════════════════════════

6. DEVELOPMENT FOLDER WITH DOCUMENTATION

   Creates:
   • ~/Dev/projects/          (for your projects)
   • ~/Dev/docs/              (reference documentation)
   • Complete setup guides
   • Command cheat sheets
   • Quick reference cards
   • Docker/Podman guides
   
   Disk space: ~1MB
   
   Create Dev folder? (Y/n): _

═══════════════════════════════════════════════════════════════

3.2 Installation Summary (Enhanced)

Display Detailed Summary Before Installation:

╔═══════════════════════════════════════════════════════════════╗
║                    INSTALLATION SUMMARY                       ║
╚═══════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════════
SYSTEM INFORMATION
═══════════════════════════════════════════════════════════════

Operating System:    Bazzite DX (bazzite-nvidia-dx:stable)
Desktop Environment: KDE Plasma 5.27
GPU:                NVIDIA GeForce RTX 3080
Container Runtime:  Podman 4.8.2
Container Manager:  Distrobox 1.7.0

═══════════════════════════════════════════════════════════════
CONTAINER CONFIGURATION
═══════════════════════════════════════════════════════════════

Container Name:     main-dev
Base Image:         Ubuntu 24.04 LTS (Noble Numbat)
Architecture:       x86_64
Podman Socket:      ✓ Enabled (Docker compatibility active)
Home Directory:     ✓ Mounted (seamless file access)

═══════════════════════════════════════════════════════════════
TOOLS TO BE INSTALLED
═══════════════════════════════════════════════════════════════

✓ Node.js Development Stack
  • Node.js LTS (v20.x)           via NodeSource repository
  • npm (bundled with Node.js)    Package manager
  • npx (bundled with Node.js)    Package executor
  • pnpm (latest)                 via Corepack
  • bun (latest)                  via official installer
  
  Installation method: NodeSource APT repository
  Binary exports: node, npm, npx, pnpm, bun, bunx
  Estimated time: ~2 minutes

✓ Python Development Tools
  • UV (latest)                   via official installer
  
  Installation method: curl | sh
  Binary exports: uv
  Estimated time: ~30 seconds

✓ Git Version Control
  • git (latest from Ubuntu)      via APT
  
  Installation method: APT package
  Binary exports: git
  Estimated time: ~10 seconds (already in base deps)

✓ GitHub CLI
  • gh (latest)                   via GitHub APT repository
  
  Installation method: GitHub APT repository
  Binary exports: gh
  Estimated time: ~1 minute

✓ Docker/Podman Mapping
  • Shell aliases configured      All shells (bash, zsh, fish)
  • docker → podman
  • docker-compose → podman-compose
  
  Estimated time: ~5 seconds

✓ Dev Folder Structure
  • ~/Dev/projects/               Created
  • ~/Dev/docs/                   Created
  • Documentation files           Generated (5 files)
  
  Estimated time: ~5 seconds

═══════════════════════════════════════════════════════════════
DISK SPACE REQUIREMENTS
═══════════════════════════════════════════════════════════════

Container base image:    ~200 MB
Base dependencies:       ~150 MB
Node.js stack:          ~500 MB
Python tools:           ~100 MB
Git:                     ~50 MB
GitHub CLI:              ~30 MB
Documentation:            ~1 MB
                        ─────────
Total required:        ~1,031 MB  (~1.0 GB)

Available disk space:    47.2 GB
After installation:      46.2 GB (estimated)

═══════════════════════════════════════════════════════════════
SHELL CONFIGURATION
═══════════════════════════════════════════════════════════════

The following files will be modified:
  ✓ ~/.bashrc                    (PATH configuration)
  ✓ ~/.bash_profile              (PATH configuration)
  ✓ ~/.zshrc                     (PATH configuration if exists)
  ✓ ~/.config/fish/config.fish   (PATH configuration if exists)

Changes:
  • Add ~/.local/bin to PATH
  • Add docker/podman aliases (if selected)
  • Add NVM wrapper function

Backup: Original files will NOT be backed up. Changes are
        additive only (appended to end of files).

═══════════════════════════════════════════════════════════════
PROCESS MANAGEMENT
═══════════════════════════════════════════════════════════════

Tool wrappers: Process-aware wrappers will be created
Purpose:       Dev servers terminate cleanly when terminal closes
Behavior:      Ctrl+C or closing terminal stops all child processes
Location:      ~/.local/bin/

═══════════════════════════════════════════════════════════════
ESTIMATED TOTAL TIME
═══════════════════════════════════════════════════════════════

Container creation:       ~30 seconds
Base dependencies:        ~1 minute
Tool installation:        ~4 minutes
Binary exports:           ~30 seconds
Shell configuration:      ~10 seconds
Documentation:            ~5 seconds
                         ──────────
Total estimated time:     ~6-7 minutes

Actual time may vary based on network speed and system performance.

═══════════════════════════════════════════════════════════════
IMPORTANT NOTES
═══════════════════════════════════════════════════════════════

  ⚠  After installation, you must RESTART YOUR TERMINAL
     or run: source ~/.bashrc (or ~/.zshrc)

  ⚠  Tools run from the host but execute in the container
     This is transparent - you won't notice any difference

  ⚠  Container will auto-start when you use any tool
     No manual container management needed

  ⚠  To enter container directly: distrobox enter main-dev

  ⚠  To remove everything: Run the generated uninstall.sh script

═══════════════════════════════════════════════════════════════

Proceed with installation? (Y/n): _

User Decision:

IF user enters 'Y', 'y', or just presses Enter (default Yes):
  → Log: "User confirmed installation"
  → PROCEED to installation

IF user enters 'N' or 'n':
  → Display: "Installation cancelled by user"
  → EXIT(0)

IF user enters anything else:
  → Display: "Please answer Y or n"
  → Re-prompt

4. Container Setup and Tool Installation

(Continues with existing phases from the original analysis)
4.1 Container Creation
4.2 Base Dependencies Installation
4.3 Individual Tool Installation
4.4 Binary Export with Process-Aware Wrappers
4.5 Shell Configuration
4.6 Verification
5. Post-Installation Reporting
5.1 Enhanced Final Report Display

Terminal Output:

╔═══════════════════════════════════════════════════════════════╗
║              SETUP COMPLETED SUCCESSFULLY                     ║
╚═══════════════════════════════════════════════════════════════╝

Setup Duration: 6 minutes 32 seconds
Completion Time: 2025-01-18 14:23:45

═══════════════════════════════════════════════════════════════
INSTALLATION RESULTS
═══════════════════════════════════════════════════════════════

✅ Successfully Installed: 10 tools
⚠️  Partial Success:       0 tools
❌ Failed:                 0 tools

Detailed Results:

✓ Container
  Status: Created and running
  Name: main-dev
  Image: ubuntu:24.04
  Podman socket: Mounted for Docker compatibility

✓ Node.js v20.11.0
  Location: /usr/bin/node
  Wrapper: ~/.local/bin/node
  Test: ✓ Accessible from host

✓ npm v10.3.0
  Location: /usr/bin/npm
  Wrapper: ~/.local/bin/npm
  Test: ✓ Accessible from host

✓ npx v10.3.0
  Location: /usr/bin/npx
  Wrapper: ~/.local/bin/npx
  Test: ✓ Accessible from host

✓ pnpm v8.15.1
  Location: ~/.local/bin/pnpm
  Wrapper: ~/.local/bin/pnpm
  Test: ✓ Accessible from host

✓ bun v1.0.23
  Location: ~/.bun/bin/bun
  Wrapper: ~/.local/bin/bun
  Test: ✓ Accessible from host

✓ git v2.43.0
  Location: /usr/bin/git
  Wrapper: ~/.local/bin/git
  Test: ✓ Accessible from host

✓ GitHub CLI v2.42.0
  Location: /usr/bin/gh
  Wrapper: ~/.local/bin/gh
  Test: ✓ Accessible from host

✓ UV v0.1.9
  Location: ~/.local/bin/uv
  Wrapper: ~/.local/bin/uv
  Test: ✓ Accessible from host

✓ Shell Configuration
  Bash:   ✓ ~/.bashrc configured
  Zsh:    ✓ ~/.zshrc configured
  Fish:   - Not installed on system

✓ Dev Folder
  Location: ~/Dev
  Projects: ~/Dev/projects (ready for use)
  Docs: ~/Dev/docs (5 guides created)

═══════════════════════════════════════════════════════════════
FILES CREATED
═══════════════════════════════════════════════════════════════

📄 Reports and Logs:
  • setup-report.md              Detailed installation report
  • setup.log                    Complete installation log
  
📜 Helper Scripts:
  • verify-setup.sh              Test tool accessibility
  • uninstall.sh                 Remove all installed components
  
🗂️  Development Folder:
  • ~/Dev/README.md              Quick start guide
  • ~/Dev/docs/SETUP_GUIDE.md    Complete technical guide
  • ~/Dev/docs/CHEAT_SHEET.md    Command reference
  • ~/Dev/docs/QUICK_REF.md      Quick reference card
  • ~/Dev/docs/DOCKER_PODMAN.md  Container usage guide

📦 Binary Wrappers (in ~/.local/bin):
  • node, npm, npx, pnpm, bun, bunx
  • git, gh, uv

═══════════════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════════════

1. RESTART YOUR TERMINAL (REQUIRED)
   
   Close this terminal and open a new one, or run:
   
   For Bash:  source ~/.bashrc
   For Zsh:   source ~/.zshrc
   For Fish:  source ~/.config/fish/config.fish

2. VERIFY INSTALLATION
   
   Run the verification script:
   
   ./verify-setup.sh
   
   This will test all installed tools and report any issues.

3. START DEVELOPING
   
   Create your first project:
   
   cd ~/Dev/projects
   mkdir my-first-project
   cd my-first-project
   npm init -y
   
   Or try a quick React app:
   
   cd ~/Dev/projects
   npm create vite@latest my-react-app -- --template react
   cd my-react-app
   npm install
   npm run dev

4. EXPLORE THE DOCUMENTATION
   
   Quick reference:
   cat ~/Dev/docs/QUICK_REF.md
   
   Complete guide:
   cat ~/Dev/docs/SETUP_GUIDE.md
   
   Command cheat sheet:
   cat ~/Dev/docs/CHEAT_SHEET.md

═══════════════════════════════════════════════════════════════
USEFUL COMMANDS
═══════════════════════════════════════════════════════════════

Check tool versions:
  node --version && npm --version && pnpm --version

Enter container directly:
  distrobox enter main-dev

List all containers:
  distrobox list

View container status:
  podman ps

Re-run verification:
  ./verify-setup.sh

View detailed report:
  cat setup-report.md

═══════════════════════════════════════════════════════════════
TROUBLESHOOTING
═══════════════════════════════════════════════════════════════

If tools are not found after restarting terminal:

1. Check PATH:
   echo $PATH | grep ".local/bin"
   
2. Manually add to current session:
   export PATH="$HOME/.local/bin:$PATH"
   
3. Verify shell config was updated:
   grep "Bazzite Dev Setup" ~/.bashrc

If dev server doesn't stop when closing terminal:
   • This should not happen with v3.0+
   • Check wrapper script: cat ~/.local/bin/node
   • Report issue if problem persists

For other issues:
   • Check: setup.log
   • Run: ./diagnose.sh (if available)
   • Visit: https://github.com/your-repo/issues

═══════════════════════════════════════════════════════════════

🎉 CONGRATULATIONS! Your development environment is ready!

═══════════════════════════════════════════════════════════════

5.2 Markdown Report (setup-report.md)

(Enhanced version of existing report with more details)
6. Error Handling and Recovery
6.1 Error Categories

    Fatal Errors (Exit immediately):
        Not running on Bazzite OS
        Insufficient disk space
        distrobox not installed and cannot continue

    Recoverable Errors (Offer alternatives):
        Rebase failure → Continue with base Bazzite
        podman not found → Continue without Docker compatibility
        Single tool installation failure → Continue with other tools

    Warnings (Log but continue):
        podman-compose not found
        NVM installation skipped
        Export failures (tool available in container)

7. Rollback and Uninstallation
7.1 DX Rebase Rollback

# If user wants to rollback from DX to base:
rpm-ostree rollback
systemctl reboot

7.2 Complete Uninstallation

Generated uninstall.sh script removes:

    Container: distrobox rm main-dev --force
    Wrappers: rm -rf ~/.local/bin/{node,npm,npx,pnpm,bun,bunx,git,gh,uv}
    Dev folder: rm -rf ~/Dev (with confirmation)
    Shell configs: Removes added lines (optional)

8. Testing and Validation
8.1 Verification Script

verify-setup.sh should test:

    Each tool wrapper exists and is executable
    Each tool returns version correctly
    Container is running and accessible
    PATH is correctly configured
    Shell configs contain required additions

9. Documentation Requirements

All generated documentation files must include:

    Last updated timestamp
    System-specific information
    Working examples
    Troubleshooting sections
    Links to external resources

End of Specification Document
