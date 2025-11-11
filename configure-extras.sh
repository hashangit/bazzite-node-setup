#!/usr/bin/env bash

################################################################################
# Bazzite Development Container - Extra Configuration Script
#
# This script adds optional configurations:
# - Docker/Podman mapping
# - Dev folder creation with guides
# - Additional shell config (bash, zsh, fish)
#
# Usage: ./configure-extras.sh
################################################################################

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Configuration
SETUP_PODMAN_DOCKER=false
CREATE_DEV_FOLDER=false
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEV_FOLDER="$HOME/Dev"

################################################################################
# Helper Functions
################################################################################

print_header() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║     Bazzite Dev Container - Extra Configuration               ║"
    echo "║                                                               ║"
    echo "║  Docker/Podman Mapping • Dev Folder • Shell Config           ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $*"
}

################################################################################
# Interactive Menus
################################################################################

show_podman_docker_menu() {
    echo -e "${YELLOW}${BOLD}1. Docker/Podman Mapping${NC}\n"
    echo "Many development tools and guides reference 'docker' and 'docker-compose'."
    echo "On Bazzite, Podman is the container runtime (not Docker)."
    echo ""
    echo -e "${CYAN}This option will:${NC}"
    echo "  • Create aliases: docker → podman"
    echo "  • Create aliases: docker-compose → podman-compose"
    echo "  • Add to all shell configs (bash, zsh, fish)"
    echo "  • Allow you to follow Docker tutorials using Podman"
    echo ""
    echo -e "${YELLOW}Note:${NC} Podman is Docker-compatible and often works better!"
    echo ""

    while true; do
        echo -en "${CYAN}${BOLD}Set up Docker/Podman mapping?${NC} (Y/n): "
        read -r response
        case $response in
            [Nn]* )
                SETUP_PODMAN_DOCKER=false
                break
                ;;
            * )
                SETUP_PODMAN_DOCKER=true
                break
                ;;
        esac
    done
    echo ""
}

show_dev_folder_menu() {
    echo -e "${YELLOW}${BOLD}2. Dev Folder Creation${NC}\n"
    echo "Create a dedicated development folder with:"
    echo "  • Organized project structure"
    echo "  • Quick reference guides"
    echo "  • Setup documentation"
    echo "  • Command cheat sheets"
    echo ""
    echo -e "${CYAN}Will create:${NC} ${GREEN}$DEV_FOLDER${NC}"
    echo ""
    echo "Structure:"
    echo "  ~/Dev/"
    echo "  ├── projects/          # Your projects go here"
    echo "  ├── docs/              # Reference documentation"
    echo "  │   ├── SETUP_GUIDE.md"
    echo "  │   ├── CHEAT_SHEET.md"
    echo "  │   └── QUICK_REF.md"
    echo "  └── README.md          # Overview"
    echo ""

    while true; do
        echo -en "${CYAN}${BOLD}Create Dev folder with guides?${NC} (Y/n): "
        read -r response
        case $response in
            [Nn]* )
                CREATE_DEV_FOLDER=false
                break
                ;;
            * )
                CREATE_DEV_FOLDER=true
                break
                ;;
        esac
    done
    echo ""
}

################################################################################
# Configuration Functions
################################################################################

setup_docker_podman_mapping() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}Setting up Docker/Podman Mapping${NC}\n"

    local alias_lines='
# Docker/Podman aliases - Added by Bazzite Dev Setup
alias docker="podman"
alias docker-compose="podman-compose"
'

    # Bash
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "Docker/Podman aliases" "$HOME/.bashrc"; then
            echo "$alias_lines" >> "$HOME/.bashrc"
            log_success "Added aliases to ~/.bashrc"
        else
            log_info "Aliases already in ~/.bashrc"
        fi
    fi

    # Zsh
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "Docker/Podman aliases" "$HOME/.zshrc"; then
            echo "$alias_lines" >> "$HOME/.zshrc"
            log_success "Added aliases to ~/.zshrc"
        else
            log_info "Aliases already in ~/.zshrc"
        fi
    fi

    # Fish
    local fish_config="$HOME/.config/fish/config.fish"
    if [ -d "$HOME/.config/fish" ]; then
        mkdir -p "$(dirname "$fish_config")"

        local fish_aliases='
# Docker/Podman aliases - Added by Bazzite Dev Setup
alias docker="podman"
alias docker-compose="podman-compose"
'
        if [ ! -f "$fish_config" ] || ! grep -q "Docker/Podman aliases" "$fish_config"; then
            echo "$fish_aliases" >> "$fish_config"
            log_success "Added aliases to ~/.config/fish/config.fish"
        else
            log_info "Aliases already in Fish config"
        fi
    fi

    # Check if podman-compose is installed
    echo ""
    log_info "Checking for podman-compose..."

    if command -v podman-compose &> /dev/null; then
        log_success "podman-compose is already installed"
    else
        log_error "podman-compose is not installed"
        echo ""
        echo -e "${YELLOW}To install podman-compose:${NC}"
        echo "  Option 1 (pip): pip install --user podman-compose"
        echo "  Option 2 (Bazzite): Use the container for docker-compose commands"
        echo ""
    fi

    log_success "Docker/Podman mapping configured!"
}

create_dev_folder_structure() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}Creating Dev Folder Structure${NC}\n"

    # Create main folders
    mkdir -p "$DEV_FOLDER"/{projects,docs}
    log_success "Created folder structure at $DEV_FOLDER"

    # Create README.md
    cat > "$DEV_FOLDER/README.md" <<'EOF'
# Development Environment

Welcome to your Bazzite development environment!

## Folder Structure

```
~/Dev/
├── projects/          # All your development projects
├── docs/              # Reference documentation and guides
│   ├── SETUP_GUIDE.md # Complete setup documentation
│   ├── CHEAT_SHEET.md # Quick command reference
│   └── QUICK_REF.md   # Quick reference for common tasks
└── README.md          # This file
```

## Quick Start

### Create a New Project

```bash
cd ~/Dev/projects
mkdir my-new-project
cd my-new-project
npm init -y
```

### Available Tools

- **Node.js**: `node`, `npm`, `npx`
- **Package Managers**: `pnpm`, `bun`
- **Version Control**: `git`, `gh`
- **Python**: `uv`
- **Containers**: `podman` (aliased as `docker`)

### Common Commands

```bash
# Node.js projects
npm install          # Install dependencies
npm run dev          # Run development server
npm test            # Run tests

# Using pnpm (faster)
pnpm install
pnpm dev

# Using bun (fastest)
bun install
bun dev

# Git workflow
git add .
git commit -m "message"
git push
```

### Getting Help

- Check the guides in `~/Dev/docs/`
- View the main setup report: `~/bazzite-node-setup/setup-report.md`
- Run verification: `~/bazzite-node-setup/verify-setup.sh`

## Container Information

- **Container Name**: main-dev
- **Image**: Ubuntu 24.04
- **Purpose**: Isolated development environment
- **Access**: Tools exported to host, work transparently

### Working with the Container

```bash
# Enter container directly (for advanced usage)
distrobox enter main-dev

# List containers
distrobox list

# Stop container
distrobox stop main-dev
```

## Tips

1. **Keep projects organized**: Use `~/Dev/projects/` for all work
2. **Use version control**: Initialize git in every project
3. **Package manager choice**:
   - `npm`: Universal, works everywhere
   - `pnpm`: Fast, saves disk space
   - `bun`: Fastest, cutting edge
4. **Docker commands**: Just use them! They're aliased to Podman
5. **Node versions**: Use `nvm` to switch versions when needed

## Troubleshooting

If tools aren't working:

```bash
# Reload shell config
source ~/.bashrc  # or ~/.zshrc

# Verify PATH
echo $PATH | grep ".local/bin"

# Re-run verification
cd ~/bazzite-node-setup
./verify-setup.sh
```

---

**Happy coding!** 🚀
EOF

    log_success "Created README.md"

    # Create SETUP_GUIDE.md
    cat > "$DEV_FOLDER/docs/SETUP_GUIDE.md" <<'EOF'
# Complete Setup Guide

This document provides comprehensive information about your development environment setup.

## System Information

### Host System
- **OS**: Bazzite (Fedora-based immutable OS)
- **Desktop**: KDE Plasma or GNOME
- **Container Runtime**: Podman

### Development Container
- **Name**: main-dev
- **Image**: Ubuntu 24.04 LTS
- **Purpose**: Isolated environment for development tools

## Installed Tools

### Node.js Stack
- **Node.js**: JavaScript runtime (LTS version)
- **npm**: Node package manager (included with Node)
- **npx**: Package executor (included with Node)
- **pnpm**: Fast, disk-efficient package manager
- **bun**: Ultra-fast all-in-one JavaScript runtime
- **NVM**: Node Version Manager (for switching versions)

### Python Tools
- **uv**: Modern, fast Python package manager

### Version Control
- **git**: Distributed version control system
- **gh**: GitHub CLI for GitHub operations

### Container Tools
- **podman**: Container runtime (Docker-compatible)
- **distrobox**: Integration layer for seamless containers

## How It Works

### Architecture

```
┌─────────────────────────────────────────┐
│         Bazzite Host (Immutable)        │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │   ~/.local/bin (Exported Tools)   │ │
│  │   ↓ Wrappers call container ↓     │ │
│  └───────────────────────────────────┘ │
│                   ↓                     │
│  ┌───────────────────────────────────┐ │
│  │  Distrobox Container (Ubuntu)     │ │
│  │  ├── Node.js, npm, pnpm, bun      │ │
│  │  ├── Python, uv                   │ │
│  │  ├── git, gh                      │ │
│  │  └── Build tools                  │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Why This Setup?

1. **Immutable Host**: Bazzite's filesystem is immutable for stability
2. **Container Isolation**: Dev tools in container, don't affect host
3. **Seamless Integration**: Exported tools work like native commands
4. **Easy Reset**: Remove container and start fresh anytime

## PATH Configuration

Your PATH has been updated in:
- `~/.bashrc` (Bash shell)
- `~/.zshrc` (Zsh shell)
- `~/.config/fish/config.fish` (Fish shell)

Added: `$HOME/.local/bin` to PATH

This ensures all exported tools are accessible.

## Usage Patterns

### Starting a New Node.js Project

```bash
# 1. Create project directory
mkdir ~/Dev/projects/my-app
cd ~/Dev/projects/my-app

# 2. Initialize project
npm init -y

# 3. Install dependencies
npm install express

# 4. Create your app
cat > app.js << 'ENDJS'
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello from Bazzite!');
});

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
ENDJS

# 5. Run your app
node app.js
```

### Using Different Package Managers

```bash
# npm (standard)
npm install lodash
npm run dev

# pnpm (faster, saves disk)
pnpm add lodash
pnpm dev

# bun (fastest)
bun add lodash
bun dev
```

### Version Control Workflow

```bash
# Initialize repository
git init
git add .
git commit -m "Initial commit"

# Create GitHub repository and push
gh repo create my-app --public --source=. --push

# Regular workflow
git add .
git commit -m "Add feature"
git push
```

### Managing Node.js Versions

```bash
# Enter container to use nvm
distrobox enter main-dev

# List available versions
nvm list-remote

# Install specific version
nvm install 18.20.0
nvm install 20.11.0

# Switch versions
nvm use 18
nvm use 20

# Set default
nvm alias default 20

# Exit container
exit

# Node version changes persist in container
```

### Python Development with UV

```bash
# Create virtual environment
uv venv my-env

# Activate it
source my-env/bin/activate

# Install packages
uv pip install requests

# Or use requirements file
echo "requests>=2.31.0" > requirements.txt
uv pip install -r requirements.txt
```

## Docker/Podman Usage

If you enabled Docker/Podman mapping:

```bash
# These commands work identically
docker ps
podman ps

docker run hello-world
podman run hello-world

# Docker Compose
docker-compose up
podman-compose up
```

## Advanced Topics

### Container Management

```bash
# List all containers
distrobox list

# Stop container (to save resources)
distrobox stop main-dev

# Start container (auto-starts when you use tools)
distrobox enter main-dev

# Remove container (to start fresh)
distrobox rm main-dev --force

# Recreate with original setup script
cd ~/bazzite-node-setup
./setup-dev-container.sh
```

### Installing Additional Tools

```bash
# Enter container
distrobox enter main-dev

# Install with apt (Ubuntu packages)
sudo apt install ripgrep fd-find

# Export to host
distrobox-export --bin /usr/bin/rg --export-path ~/.local/bin
distrobox-export --bin /usr/bin/fdfind --export-path ~/.local/bin

# Exit
exit

# Now use from host
rg "search term"
fdfind "file pattern"
```

### Global Node Packages

```bash
# Install global package
npm install -g typescript

# It's available in container
distrobox enter main-dev -- tsc --version

# Export to host if needed
distrobox enter main-dev -- which tsc | \
  xargs -I {} distrobox-export --bin {} \
  --export-path ~/.local/bin \
  --container main-dev
```

## Maintenance

### Updating Tools

```bash
# Update Node.js
distrobox enter main-dev
nvm install node --reinstall-packages-from=current
exit

# Update npm
npm install -g npm@latest

# Update pnpm
pnpm add -g pnpm

# Update bun
bun upgrade

# Update container packages
distrobox enter main-dev
sudo apt update && sudo apt upgrade
exit
```

### Cleaning Up

```bash
# Clear npm cache
npm cache clean --force

# Clear pnpm store
pnpm store prune

# Clear bun cache
rm -rf ~/.bun/install/cache

# Remove node_modules
rm -rf node_modules
npm install
```

## Troubleshooting

See the main troubleshooting guide at:
`~/bazzite-node-setup/TROUBLESHOOTING.md`

## Additional Resources

- [Bazzite Documentation](https://bazzite.gg/docs)
- [Distrobox Documentation](https://distrobox.it/)
- [Node.js Documentation](https://nodejs.org/docs)
- [NVM GitHub](https://github.com/nvm-sh/nvm)
- [pnpm Documentation](https://pnpm.io/)
- [Bun Documentation](https://bun.sh/docs)

---

Last updated: $(date '+%Y-%m-%d')
EOF

    log_success "Created SETUP_GUIDE.md"

    # Create CHEAT_SHEET.md
    cat > "$DEV_FOLDER/docs/CHEAT_SHEET.md" <<'EOF'
# Development Cheat Sheet

Quick reference for common commands and tasks.

## Node.js & npm

```bash
# Package Management
npm install <package>          # Install package
npm install -D <package>       # Install as dev dependency
npm install -g <package>       # Install globally
npm uninstall <package>        # Remove package
npm update                     # Update packages

# Project Management
npm init                       # Create new project (interactive)
npm init -y                    # Create with defaults
npm run <script>               # Run script from package.json
npm test                       # Run tests
npm start                      # Run start script

# Information
npm list                       # List installed packages
npm list -g                    # List global packages
npm outdated                   # Check for updates
npm audit                      # Check for vulnerabilities
```

## pnpm (Fast Alternative)

```bash
# Same as npm, but faster
pnpm add <package>             # Install package
pnpm add -D <package>          # Install as dev dependency
pnpm add -g <package>          # Install globally
pnpm remove <package>          # Remove package
pnpm update                    # Update packages

# Run commands
pnpm <script>                  # Run script (no 'run' needed)
pnpm test
pnpm dev
```

## bun (Fastest Alternative)

```bash
# Bun commands
bun add <package>              # Install package
bun add -d <package>           # Install as dev dependency
bun add -g <package>           # Install globally
bun remove <package>           # Remove package

# Run commands
bun run <script>               # Run script
bun <file>                     # Execute file directly
bun test                       # Run tests
```

## Node Version Management (NVM)

```bash
# Must be run in container
distrobox enter main-dev

nvm install <version>          # Install specific Node version
nvm install --lts             # Install latest LTS
nvm install node              # Install latest version
nvm use <version>             # Switch to version
nvm alias default <version>   # Set default version
nvm list                      # List installed versions
nvm list-remote               # List available versions

exit                          # Exit container
```

## Git

```bash
# Setup
git config --global user.name "Your Name"
git config --global user.email "email@example.com"

# Basic Commands
git init                       # Initialize repository
git clone <url>                # Clone repository
git status                     # Check status
git add <file>                 # Stage file
git add .                      # Stage all changes
git commit -m "message"        # Commit changes
git push                       # Push to remote
git pull                       # Pull from remote

# Branching
git branch                     # List branches
git branch <name>              # Create branch
git checkout <branch>          # Switch branch
git checkout -b <branch>       # Create and switch
git merge <branch>             # Merge branch
git branch -d <branch>         # Delete branch

# History
git log                        # View commit history
git log --oneline             # Compact history
git diff                      # View changes
```

## GitHub CLI (gh)

```bash
# Authentication
gh auth login                  # Login to GitHub

# Repositories
gh repo create <name>          # Create repository
gh repo clone <repo>           # Clone repository
gh repo view                   # View repository info

# Pull Requests
gh pr create                   # Create PR
gh pr list                     # List PRs
gh pr view <number>            # View PR
gh pr checkout <number>        # Checkout PR

# Issues
gh issue create                # Create issue
gh issue list                  # List issues
gh issue view <number>         # View issue
```

## Python & UV

```bash
# Virtual Environments
uv venv <name>                 # Create venv
source <name>/bin/activate     # Activate venv
deactivate                     # Deactivate venv

# Package Management
uv pip install <package>       # Install package
uv pip install -r requirements.txt  # Install from file
uv pip list                    # List installed
uv pip freeze > requirements.txt    # Save dependencies
```

## Docker/Podman

```bash
# Container Management
docker ps                      # List running containers
docker ps -a                   # List all containers
docker images                  # List images
docker pull <image>            # Download image
docker run <image>             # Run container
docker stop <container>        # Stop container
docker rm <container>          # Remove container

# Docker Compose
docker-compose up              # Start services
docker-compose up -d           # Start in background
docker-compose down            # Stop services
docker-compose ps              # List services
docker-compose logs            # View logs
```

## Distrobox (Container)

```bash
# Container Management
distrobox list                 # List containers
distrobox enter <name>         # Enter container
distrobox stop <name>          # Stop container
distrobox rm <name>            # Remove container

# Exporting
distrobox-export --bin <path>  # Export binary to host
distrobox-export --app <name>  # Export app to host
```

## File Operations

```bash
# Navigation
cd <dir>                       # Change directory
cd ~                           # Go to home
cd ..                          # Go up one level
pwd                            # Print current directory

# Files
ls                             # List files
ls -la                         # List all with details
cat <file>                     # View file contents
nano <file>                    # Edit file (nano)
vim <file>                     # Edit file (vim)
cp <source> <dest>             # Copy file
mv <source> <dest>             # Move/rename file
rm <file>                      # Remove file
mkdir <dir>                    # Create directory
rm -rf <dir>                   # Remove directory

# Permissions
chmod +x <file>                # Make executable
chmod 644 <file>               # Set file permissions
chown user:group <file>        # Change ownership
```

## System Information

```bash
# System
df -h                          # Disk space
free -h                        # Memory usage
top                            # Process monitor
htop                           # Better process monitor

# Networking
ping <host>                    # Test connectivity
curl <url>                     # Download/test URL
wget <url>                     # Download file
netstat -tulpn                 # List open ports
```

## Quick Project Setup

### React App
```bash
npx create-react-app my-app
cd my-app
npm start
```

### Next.js App
```bash
npx create-next-app@latest my-app
cd my-app
npm run dev
```

### Vue App
```bash
npm create vue@latest my-app
cd my-app
npm install
npm run dev
```

### Express API
```bash
mkdir my-api && cd my-api
npm init -y
npm install express
# Create index.js with Express code
node index.js
```

---

For more details, see SETUP_GUIDE.md
EOF

    log_success "Created CHEAT_SHEET.md"

    # Create QUICK_REF.md
    cat > "$DEV_FOLDER/docs/QUICK_REF.md" <<'EOF'
# Quick Reference

## Most Used Commands

```bash
# Package Installation
npm install              # Install dependencies
pnpm install            # Faster alternative
bun install             # Fastest alternative

# Run Development Server
npm run dev
pnpm dev
bun dev

# Git Workflow
git add .
git commit -m "message"
git push

# Container Access
distrobox enter main-dev    # Enter container
```

## File Paths

```
~/Dev/                      # Your development folder
~/Dev/projects/             # All your projects
~/Dev/docs/                 # Reference guides
~/.local/bin/               # Exported tools
~/bazzite-node-setup/       # Setup scripts
```

## Common Issues

### "Command not found"
```bash
export PATH="$HOME/.local/bin:$PATH"
# Or restart terminal
```

### "Permission denied"
```bash
chmod +x <script>
```

### Container not accessible
```bash
distrobox list
distrobox enter main-dev
```

### Tools not working
```bash
cd ~/bazzite-node-setup
./verify-setup.sh
```

## Tool Versions

Check installed versions:

```bash
node --version
npm --version
pnpm --version
bun --version
git --version
gh --version
uv --version
```

## Getting Help

- Full setup guide: `~/Dev/docs/SETUP_GUIDE.md`
- Command cheat sheet: `~/Dev/docs/CHEAT_SHEET.md`
- Troubleshooting: `~/bazzite-node-setup/TROUBLESHOOTING.md`
- Verification: `~/bazzite-node-setup/verify-setup.sh`

---

Quick Tip: Tab completion works for most commands!
EOF

    log_success "Created QUICK_REF.md"

    echo ""
    log_success "Dev folder structure created successfully!"
    echo ""
    echo -e "${CYAN}Your Dev folder is ready at:${NC} ${GREEN}$DEV_FOLDER${NC}"
    echo ""
    echo "Contents:"
    echo "  • ~/Dev/projects/     - Create your projects here"
    echo "  • ~/Dev/docs/         - Reference guides and documentation"
    echo "  • ~/Dev/README.md     - Quick overview"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header

    echo "This script configures additional features for your development environment."
    echo ""

    # Show menus
    show_podman_docker_menu
    show_dev_folder_menu

    # Confirm
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}Configuration Summary${NC}\n"

    [ "$SETUP_PODMAN_DOCKER" == true ] && echo -e "${GREEN}✓${NC} Docker/Podman mapping"
    [ "$SETUP_PODMAN_DOCKER" == false ] && echo -e "${YELLOW}✗${NC} Docker/Podman mapping (skipped)"

    [ "$CREATE_DEV_FOLDER" == true ] && echo -e "${GREEN}✓${NC} Dev folder creation"
    [ "$CREATE_DEV_FOLDER" == false ] && echo -e "${YELLOW}✗${NC} Dev folder creation (skipped)"

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ "$SETUP_PODMAN_DOCKER" == false ] && [ "$CREATE_DEV_FOLDER" == false ]; then
        echo -e "${YELLOW}No configurations selected. Exiting.${NC}"
        exit 0
    fi

    while true; do
        echo -en "${CYAN}${BOLD}Proceed with configuration?${NC} (Y/n): "
        read -r response
        case $response in
            [Nn]* )
                echo -e "\n${YELLOW}Configuration cancelled.${NC}"
                exit 0
                ;;
            * )
                break
                ;;
        esac
    done

    # Apply configurations
    [ "$SETUP_PODMAN_DOCKER" == true ] && setup_docker_podman_mapping
    [ "$CREATE_DEV_FOLDER" == true ] && create_dev_folder_structure

    # Final message
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}Configuration Complete!${NC}\n"

    if [ "$SETUP_PODMAN_DOCKER" == true ]; then
        echo -e "${YELLOW}Docker/Podman mapping:${NC}"
        echo "  Restart your terminal or run: source ~/.bashrc"
        echo "  Then you can use: docker, docker-compose"
        echo ""
    fi

    if [ "$CREATE_DEV_FOLDER" == true ]; then
        echo -e "${YELLOW}Dev folder:${NC}"
        echo "  Location: $DEV_FOLDER"
        echo "  Start here: cd ~/Dev/projects"
        echo "  Guides: cd ~/Dev/docs"
        echo ""
    fi

    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Restart your terminal (or source your shell config)"
    echo "  2. Start coding: cd ~/Dev/projects"
    echo "  3. Reference guides: cat ~/Dev/docs/QUICK_REF.md"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

# Run main function
main "$@"
