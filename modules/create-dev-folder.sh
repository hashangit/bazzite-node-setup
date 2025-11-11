#!/usr/bin/env bash

################################################################################
# Dev Folder Creation Module
# Creates organized development folder with comprehensive documentation
################################################################################

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/modules/common.sh"

# Configuration
readonly DEV_FOLDER="${DEV_FOLDER:-$HOME/Dev}"

create_dev_folder_structure() {
    if [ "${CREATE_DEV_FOLDER:-false}" != true ]; then
        log "Skipping Dev folder creation (not selected)"
        return 0
    fi

    log_step "Creating Dev folder structure..."

    # Create main folders
    mkdir -p "$DEV_FOLDER"/{projects,docs}
    log_success "Created folder structure at $DEV_FOLDER"

    # Create main README
    create_dev_readme

    # Create documentation guides
    create_setup_guide
    create_cheat_sheet
    create_quick_ref
    create_docker_podman_guide

    log_success "Dev folder created with documentation at $DEV_FOLDER"
    echo ""
    echo -e "${CYAN}Your development folder is ready at:${NC}"
    echo -e "  ${GREEN}$DEV_FOLDER${NC}"
    echo ""
    echo -e "${CYAN}Guides created:${NC}"
    echo "  • $DEV_FOLDER/README.md"
    echo "  • $DEV_FOLDER/docs/SETUP_GUIDE.md"
    echo "  • $DEV_FOLDER/docs/CHEAT_SHEET.md"
    echo "  • $DEV_FOLDER/docs/QUICK_REF.md"
    echo "  • $DEV_FOLDER/docs/DOCKER_PODMAN.md"
    echo ""

    return 0
}

create_dev_readme() {
    cat > "$DEV_FOLDER/README.md" <<'EOF'
# Development Environment

Welcome to your Bazzite development environment!

## Folder Structure

```
~/Dev/
├── projects/          # All your development projects
├── docs/              # Reference documentation and guides
│   ├── SETUP_GUIDE.md    # Complete setup documentation
│   ├── CHEAT_SHEET.md    # Quick command reference
│   ├── QUICK_REF.md      # Quick reference for common tasks
│   └── DOCKER_PODMAN.md  # Container usage guide
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
npm test             # Run tests

# Using pnpm (faster)
pnpm install && pnpm dev

# Using bun (fastest)
bun install && bun dev

# Git workflow
git add . && git commit -m "message" && git push
```

### Getting Help

- Check the guides in `~/Dev/docs/`
- Run verification: `verify-setup.sh`

## Container Information

- **Container Name**: main-dev
- **Image**: Ubuntu 24.04
- **Purpose**: Isolated development environment
- **Access**: Tools exported to host, work transparently

### Working with the Container

```bash
# Enter container directly
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

---

**Happy coding!** 🚀
EOF
}

create_setup_guide() {
    cat > "$DEV_FOLDER/docs/SETUP_GUIDE.md" <<'EOF'
# Complete Setup Guide

## System Architecture

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

## Installed Tools

### Node.js Stack
- **Node.js**: JavaScript runtime (LTS version)
- **npm**: Node package manager
- **npx**: Package executor
- **pnpm**: Fast, disk-efficient package manager
- **bun**: Ultra-fast JavaScript runtime
- **NVM**: Node Version Manager (use in container)

### Python Tools
- **uv**: Modern, fast Python package manager

### Version Control
- **git**: Distributed version control
- **gh**: GitHub CLI

### Container Tools
- **podman**: Container runtime (Docker-compatible)
- **distrobox**: Container integration layer

## How It Works

1. **Immutable Host**: Bazzite's filesystem is immutable for stability
2. **Container Isolation**: Dev tools in container, don't affect host
3. **Seamless Integration**: Exported tools work like native commands
4. **Easy Reset**: Remove container and start fresh anytime

## Common Tasks

### Starting a New Node.js Project

```bash
cd ~/Dev/projects
mkdir my-app && cd my-app
npm init -y
npm install express
npm install --save-dev nodemon
```

### Using Different Node Package Managers

```bash
# npm (default, universally compatible)
npm install
npm run dev

# pnpm (fast, efficient)
pnpm install
pnpm dev

# bun (fastest)
bun install
bun dev
```

### Git Workflows

```bash
# Initialize repository
git init
git add .
git commit -m "Initial commit"

# Create GitHub repo and push
gh repo create my-app --public --source=. --remote=origin
git push -u origin main
```

### Using NVM (Node Version Manager)

NVM must be used from inside the container:

```bash
# Enter container
distrobox enter main-dev

# Use NVM
nvm install 18
nvm use 18
nvm list

# Exit
exit
```

## Troubleshooting

### Tools not found
```bash
# Reload shell
source ~/.bashrc

# Verify PATH
echo $PATH | grep ".local/bin"
```

### Dev server not stopping
With v3.0, dev servers should stop automatically when you close the terminal.
If issues persist, use Ctrl+C.

### Container issues
```bash
# Check container status
distrobox list

# Restart container
distrobox stop main-dev
distrobox enter main-dev

# Rebuild container
distrobox rm main-dev --force
# Re-run setup
```

---

For more help, see other guides in ~/Dev/docs/
EOF
}

create_cheat_sheet() {
    cat > "$DEV_FOLDER/docs/CHEAT_SHEET.md" <<'EOF'
# Development Cheat Sheet

## Node.js & npm

```bash
# Initialize new project
npm init -y

# Install dependencies
npm install <package>
npm install --save-dev <package>
npm install -g <package>

# Run scripts
npm run dev
npm run build
npm test

# Update packages
npm update
npm outdated
```

## pnpm (Fast Package Manager)

```bash
# All npm commands work, just replace npm with pnpm
pnpm install
pnpm add <package>
pnpm dev

# Advantages:
# - Faster than npm
# - Uses less disk space (shared packages)
# - Stricter dependency resolution
```

## Bun (Fastest Runtime)

```bash
# Install dependencies (very fast)
bun install

# Run scripts
bun dev
bun test

# Run files directly
bun run index.ts

# Advantages:
# - 10-100x faster than npm
# - Built-in TypeScript support
# - All-in-one tool
```

## Git

```bash
# Setup
git config --global user.name "Your Name"
git config --global user.email "email@example.com"

# Basic workflow
git init
git add .
git add <file>
git commit -m "message"
git push

# Branching
git branch <name>
git checkout <name>
git checkout -b <name>  # create and switch

# Undo changes
git reset HEAD <file>
git checkout -- <file>
git revert <commit>

# View history
git log
git log --oneline
git diff
```

## GitHub CLI (gh)

```bash
# Create repo
gh repo create <name>
gh repo create --public --source=.

# Clone repo
gh repo clone <owner>/<repo>

# Pull requests
gh pr create
gh pr list
gh pr view <number>
gh pr merge <number>

# Issues
gh issue create
gh issue list
gh issue close <number>

# Authentication
gh auth login
gh auth status
```

## Python & uv

```bash
# Create virtual environment
uv venv

# Activate environment
source .venv/bin/activate

# Install packages
uv pip install <package>
uv pip install -r requirements.txt

# Generate requirements
uv pip freeze > requirements.txt
```

## Container Commands

```bash
# Enter container
distrobox enter main-dev

# List containers
distrobox list

# Stop container
distrobox stop main-dev

# Start container
distrobox enter main-dev

# Remove container
distrobox rm main-dev --force

# Export new binaries
distrobox-export --bin /path/to/binary
```

## Useful Aliases

```bash
# If you set up Docker/Podman mapping:
docker ps        # Actually runs: podman ps
docker run ...   # Actually runs: podman run ...
docker build ... # Actually runs: podman build ...
```

## Quick Project Templates

### Express.js API
```bash
npm init -y
npm install express
# Create server.js and start coding
```

### React App
```bash
npm create vite@latest my-app -- --template react
cd my-app
npm install
npm run dev
```

### Next.js App
```bash
npx create-next-app@latest my-app
cd my-app
npm run dev
```

---

**Tip**: Keep this file open in a second terminal for quick reference!
EOF
}

create_quick_ref() {
    cat > "$DEV_FOLDER/docs/QUICK_REF.md" <<'EOF'
# Quick Reference

## One-Liners

### Node.js
```bash
# Quick server
npx http-server .

# Quick React app
npm create vite@latest

# Quick test
npm test

# Install and save
npm i <pkg> && npm run dev
```

### Git
```bash
# Quick commit
git add . && git commit -m "update" && git push

# Quick branch
git checkout -b feature && git push -u origin feature

# Quick clone and enter
gh repo clone <repo> && cd $(basename $_ .git)
```

### Container
```bash
# Quick container enter
distrobox enter main-dev

# Quick container restart
distrobox stop main-dev && distrobox enter main-dev
```

## Common Fixes

### Fix PATH
```bash
export PATH="$HOME/.local/bin:$PATH"
source ~/.bashrc
```

### Fix permissions
```bash
chmod +x script.sh
chmod 755 directory
```

### Fix npm permissions
```bash
npm config set prefix ~/.npm-global
export PATH=~/.npm-global/bin:$PATH
```

### Fix git credentials
```bash
gh auth login
# or
git config credential.helper store
```

## Environment Variables

```bash
# Add to ~/.bashrc or ~/.zshrc
export NODE_ENV=development
export PATH="$HOME/.local/bin:$PATH"
```

## Performance Tips

1. Use `pnpm` instead of `npm` (faster)
2. Use `bun` for maximum speed
3. Use `&&` to chain commands
4. Use aliases for common tasks

---

**Pro Tip**: Create your own aliases in ~/.bashrc for even faster workflows!
EOF
}

create_docker_podman_guide() {
    cat > "$DEV_FOLDER/docs/DOCKER_PODMAN.md" <<'EOF'
# Docker/Podman Guide

## Why Podman?

On Bazzite, **Podman** is the container runtime, not Docker. But don't worry:

- ✅ Podman is Docker-compatible
- ✅ Same commands work (`podman run` = `docker run`)
- ✅ Alias setup makes it transparent
- ✅ Actually better in many ways (rootless, daemon-free)

## Using "Docker" Commands

If you set up Docker/Podman mapping, just use docker commands normally:

```bash
# These work exactly the same:
docker ps
docker run -it ubuntu bash
docker build -t myapp .
docker-compose up
```

They're automatically translated to podman commands!

## Common Container Tasks

### Run a Database

```bash
# PostgreSQL
docker run --name postgres -e POSTGRES_PASSWORD=secret -p 5432:5432 -d postgres

# MySQL
docker run --name mysql -e MYSQL_ROOT_PASSWORD=secret -p 3306:3306 -d mysql

# MongoDB
docker run --name mongo -p 27017:27017 -d mongo

# Redis
docker run --name redis -p 6379:6379 -d redis
```

### Run a Web Server

```bash
# Nginx
docker run --name nginx -p 8080:80 -v $(pwd):/usr/share/nginx/html:ro -d nginx

# Node.js app
docker run --name myapp -p 3000:3000 -v $(pwd):/app -w /app -d node:lts npm start
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: secret
```

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f
```

## Podman-Specific Features

### Rootless (More Secure)
Podman runs without root privileges by default - more secure!

### No Daemon
Podman doesn't require a background daemon - lighter on resources!

### Pod Support
```bash
# Create a pod (like Kubernetes)
podman pod create --name mypod -p 8080:80

# Add containers to pod
podman run -d --pod mypod nginx
podman run -d --pod mypod redis
```

## Troubleshooting

### Port already in use
```bash
# Find what's using the port
sudo lsof -i :8080

# Use different port
docker run -p 8081:80 nginx
```

### Permission denied
```bash
# Podman runs rootless, should not need sudo
# If you get errors, check:
podman system info
```

### Image not found
```bash
# Pull explicitly
docker pull ubuntu:latest
```

## Best Practices

1. **Use specific tags**: `node:18` not `node:latest`
2. **Clean up**: `docker system prune` regularly
3. **Use volumes**: Don't lose data when container stops
4. **Environment files**: Use `.env` for secrets
5. **Health checks**: Add health checks to services

---

**Remember**: On Bazzite, you're using Podman (which is better!), but you can pretend it's Docker!
EOF
}

# Export functions
export -f create_dev_folder_structure
export -f create_dev_readme create_setup_guide create_cheat_sheet
export -f create_quick_ref create_docker_podman_guide
