# User Guide: Bazzite Node.js Development Container

A comprehensive guide for developers and end users on how to install, configure, and use the Node.js development environment on Bazzite.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Installation Steps](#installation-steps)
3. [Daily Usage](#daily-usage)
4. [Package Management](#package-management)
5. [Version Management](#version-management)
6. [Common Workflows](#common-workflows)
7. [Best Practices](#best-practices)
8. [Tips & Tricks](#tips--tricks)

## Getting Started

### What You'll Get

After completing this setup, you'll have:

- ✅ **Node.js** - JavaScript runtime for server-side development
- ✅ **npm** - The world's largest package registry
- ✅ **npx** - Run packages without installing globally
- ✅ **pnpm** - Fast, disk-efficient alternative to npm
- ✅ **bun** - Ultra-fast JavaScript runtime and package manager
- ✅ **nvm** - Easily switch between Node.js versions

All accessible directly from your host terminal, with no configuration needed!

### Prerequisites Check

Before starting, ensure you have:

```bash
# Check if you're on Bazzite
cat /etc/os-release | grep -i bazzite

# Check if distrobox is available
command -v distrobox && echo "✓ distrobox is available" || echo "✗ distrobox not found"
```

## Installation Steps

### Step 1: Download the Setup

```bash
# Clone the repository
git clone <repository-url>
cd bazzite-node-setup

# Or download and extract the ZIP file
```

### Step 2: Prepare the Setup Script

```bash
# Make the setup script executable
chmod +x setup-dev-container.sh

# Optional: Review the script before running
cat setup-dev-container.sh
```

### Step 3: Run the Setup

```bash
# Execute the setup script
./setup-dev-container.sh
```

**What happens during setup:**

1. ✓ Checks your system compatibility
2. ✓ Creates/verifies the `main-dev` distrobox container
3. ✓ Installs Ubuntu 24.04 in the container
4. ✓ Installs build tools and dependencies
5. ✓ Installs NVM (Node Version Manager)
6. ✓ Installs Node.js LTS version
7. ✓ Installs pnpm package manager
8. ✓ Installs bun runtime
9. ✓ Exports all tools to host system
10. ✓ Verifies everything works correctly
11. ✓ Creates verification and uninstall scripts

**Expected duration**: 5-10 minutes (depending on internet speed)

### Step 4: Activate the Tools

After setup completes, restart your terminal or run:

```bash
# Add to current session
export PATH="$HOME/.local/bin:$PATH"

# Or restart your terminal (recommended)
```

### Step 5: Verify Installation

```bash
# Run the verification script
./verify-setup.sh
```

Expected output:
```
Verifying Development Environment...
====================================

✓ node: v20.11.0
✓ npm: 10.2.4
✓ npx: 10.2.4
✓ pnpm: 8.15.0
✓ bun: 1.0.25

====================================
Results: 5 passed, 0 failed
All checks passed!
```

## Daily Usage

### Running Node.js Applications

```bash
# Execute a JavaScript file
node app.js

# Run with arguments
node app.js --port 3000

# Run in development mode (if configured in package.json)
npm run dev
```

### Installing Packages

#### Option 1: Using npm (default)

```bash
# Install a single package
npm install express

# Install as dev dependency
npm install --save-dev typescript

# Install globally
npm install -g nodemon
```

#### Option 2: Using pnpm (faster, more efficient)

```bash
# Install a single package
pnpm add express

# Install as dev dependency
pnpm add -D typescript

# Install globally
pnpm add -g nodemon
```

#### Option 3: Using bun (fastest)

```bash
# Install a single package
bun add express

# Install as dev dependency
bun add -d typescript

# Install globally
bun add -g nodemon
```

### Running Package Scripts

All three package managers can run scripts defined in `package.json`:

```bash
# Using npm
npm run build
npm run test
npm run start

# Using pnpm
pnpm build
pnpm test
pnpm start

# Using bun
bun run build
bun test
bun start
```

### Using npx and bunx

Execute packages without installing them:

```bash
# Create a React app
npx create-react-app my-app

# Or with bunx (faster)
bunx create-react-app my-app

# Run a one-off command
npx cowsay "Hello Bazzite!"

# Run a specific version
npx typescript@4.5.2 --version
```

## Package Management

### Choosing the Right Package Manager

| Feature | npm | pnpm | bun |
|---------|-----|------|-----|
| **Speed** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Disk Usage** | High | Low | Low |
| **Compatibility** | ✅ 100% | ✅ 99%+ | ⚠️ Most packages |
| **Monorepos** | Basic | Excellent | Good |
| **Learning Curve** | Easy | Easy | Easy |

**Recommendation**:
- **npm**: Stick with it if you're comfortable
- **pnpm**: Best for most projects, especially monorepos
- **bun**: Bleeding edge, fastest, but newer ecosystem

### Package.json Scripts

Example `package.json`:

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "scripts": {
    "dev": "node server.js",
    "build": "node build.js",
    "test": "node test.js",
    "start": "node dist/server.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

Run scripts with any package manager:
```bash
npm run dev    # or
pnpm dev       # or
bun dev
```

### Installing Dependencies

```bash
# Install all dependencies from package.json
npm install    # or
pnpm install   # or
bun install

# Install and add to dependencies
npm install lodash    # or
pnpm add lodash       # or
bun add lodash

# Install and add to devDependencies
npm install -D jest    # or
pnpm add -D jest       # or
bun add -d jest
```

## Version Management

### Checking Current Version

```bash
# Check Node.js version
node --version

# Check npm version
npm --version

# Check all NVM versions installed
nvm list
```

### Installing Different Node.js Versions

```bash
# Install latest LTS version
nvm install --lts

# Install specific version
nvm install 18.20.0

# Install latest version
nvm install node
```

### Switching Between Versions

```bash
# Switch to a different version
nvm use 18

# Switch to LTS
nvm use --lts

# Switch to system Node (if any)
nvm use system
```

### Setting Default Version

```bash
# Set default Node.js version
nvm alias default 20

# Or set to LTS
nvm alias default lts/*
```

### Per-Project Node Version

Create an `.nvmrc` file in your project:

```bash
# Create .nvmrc file
echo "20.11.0" > .nvmrc

# Now 'nvm use' will automatically use this version
nvm use
```

## Common Workflows

### Creating a New Project

#### Basic Node.js Project

```bash
# Create project directory
mkdir my-project
cd my-project

# Initialize package.json
npm init -y

# Install dependencies
npm install express

# Create main file
cat > index.js << 'EOF'
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello from Bazzite!');
});

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
EOF

# Run the server
node index.js
```

#### React Project

```bash
# Create new React app
npx create-react-app my-react-app
cd my-react-app

# Start development server
npm start
```

#### Next.js Project

```bash
# Create new Next.js app
npx create-next-app@latest my-next-app
cd my-next-app

# Start development server
npm run dev
```

#### Vue Project

```bash
# Create new Vue app
npm create vue@latest my-vue-app
cd my-vue-app

# Install dependencies
npm install

# Start development server
npm run dev
```

### Working with Existing Projects

```bash
# Clone a repository
git clone https://github.com/user/project.git
cd project

# Check for .nvmrc and use the right Node version
if [ -f .nvmrc ]; then
  nvm install
  nvm use
fi

# Install dependencies
npm install    # or pnpm install, or bun install

# Run the project
npm run dev
```

### Running Development Servers

```bash
# Start a dev server
npm run dev

# The server runs inside the container but is accessible from host
# Open http://localhost:3000 in your browser

# Stop the server with Ctrl+C
# Or close the terminal (it will auto-stop)
```

**Important Notes**:
- Servers run on localhost and are accessible from your browser
- Ports are automatically forwarded by distrobox
- Closing the terminal stops the dev server (clean shutdown)
- Use `Ctrl+C` for graceful shutdown

## Best Practices

### 1. Use Version Managers

```bash
# Always use NVM for Node.js versions
nvm install 20
nvm use 20

# Don't manually install Node.js in the container
```

### 2. Commit Lock Files

```bash
# npm
git add package-lock.json

# pnpm
git add pnpm-lock.yaml

# bun
git add bun.lockb

# This ensures consistent installs across machines
```

### 3. Use .nvmrc Files

```bash
# Create .nvmrc for project-specific Node version
echo "20.11.0" > .nvmrc
git add .nvmrc

# Team members can then just run:
nvm install && nvm use
```

### 4. Keep Dependencies Updated

```bash
# Check outdated packages
npm outdated    # or
pnpm outdated   # or
bun outdated

# Update packages
npm update      # or
pnpm update     # or
bun update
```

### 5. Clean Node Modules When Switching Package Managers

```bash
# If switching from npm to pnpm
rm -rf node_modules package-lock.json
pnpm install

# If switching to bun
rm -rf node_modules package-lock.json
bun install
```

## Tips & Tricks

### Tip 1: Faster Installs with pnpm

```bash
# pnpm uses a global store and links packages
# First install creates the store
pnpm install

# Subsequent installs are much faster
# And save disk space!
```

### Tip 2: Run Scripts Faster with bun

```bash
# Bun is 2-3x faster for running scripts
bun run dev
bun test
bun build
```

### Tip 3: Use Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias ni="npm install"
alias nid="npm install --save-dev"
alias nr="npm run"
alias ns="npm start"

alias pi="pnpm install"
alias pa="pnpm add"
alias pr="pnpm run"

alias bi="bun install"
alias ba="bun add"
alias br="bun run"
```

Then:
```bash
nr dev    # Instead of npm run dev
pa express # Instead of pnpm add express
```

### Tip 4: Check What's Using Port

```bash
# If you get "port already in use" error
distrobox enter main-dev
lsof -i :3000
```

### Tip 5: Clear npm Cache

```bash
# If installations are failing
npm cache clean --force
```

### Tip 6: Reinstall All Global Packages

```bash
# When updating Node.js version
nvm install 20 --reinstall-packages-from=18
```

### Tip 7: Run Commands Inside Container

```bash
# For advanced usage or debugging
distrobox enter main-dev

# Now you're inside the container
# Exit with 'exit' or Ctrl+D
```

### Tip 8: Multiple Terminal Sessions

```bash
# You can have multiple terminals using the same container
# Terminal 1: Run dev server
npm run dev

# Terminal 2: Run tests
npm test

# Terminal 3: Edit files
vim src/app.js
```

## Container Management

### Entering the Container

```bash
# Enter the container shell
distrobox enter main-dev

# You're now inside Ubuntu 24.04
# All tools are available
# Exit with 'exit' or Ctrl+D
```

### Stopping the Container

```bash
# Containers auto-stop when not in use
# To manually stop:
distrobox stop main-dev
```

### Starting the Container

```bash
# Usually not needed (auto-starts when you use tools)
# To manually start:
distrobox enter main-dev
```

### Checking Container Status

```bash
# List all distrobox containers
distrobox list

# Should show: main-dev | ubuntu:24.04 | Up
```

## Updating Tools

### Update Node.js

```bash
# Install latest LTS
nvm install --lts --reinstall-packages-from=current
nvm alias default lts/*
```

### Update npm

```bash
npm install -g npm@latest
```

### Update pnpm

```bash
pnpm add -g pnpm
```

### Update bun

```bash
bun upgrade
```

### Update All Global Packages

```bash
# List global packages
npm list -g --depth=0

# Update all
npm update -g
```

## Cleanup and Maintenance

### Clear Package Caches

```bash
# npm cache
npm cache clean --force

# pnpm cache
pnpm store prune

# bun cache
rm -rf ~/.bun/install/cache
```

### Remove Unused Packages

```bash
# Remove package
npm uninstall package-name

# Remove unused packages
npm prune
```

### Clean node_modules

```bash
# Remove and reinstall
rm -rf node_modules
npm install
```

## Getting Help

### Check Versions

```bash
node --version
npm --version
pnpm --version
bun --version
nvm --version
```

### Command Help

```bash
npm help
pnpm help
bun help
nvm --help
```

### View Logs

```bash
# Setup log
cat setup.log

# npm logs
cat ~/.npm/_logs/*.log
```

### Verify Setup

```bash
# Run verification script
./verify-setup.sh

# Manual checks
command -v node
command -v npm
command -v pnpm
command -v bun
```

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Command not found | Run `export PATH="$HOME/.local/bin:$PATH"` |
| Permission denied | Run `chmod +x setup-dev-container.sh` |
| Port in use | Check with `lsof -i :PORT` and kill process |
| Installation fails | Check `setup.log` for errors |
| Container won't start | Run `distrobox list` and check status |

For detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Summary

You now have a complete Node.js development environment on Bazzite! Here's what to remember:

✅ **All tools work from host terminal** - No need to enter container
✅ **Use any package manager** - npm, pnpm, or bun
✅ **Switch Node versions easily** - Just use nvm
✅ **Dev servers auto-stop** - When you close terminal
✅ **Clean and isolated** - No pollution of host system

**Happy coding!** 🚀

---

For more information:
- [README.md](README.md) - Overview and quick start
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Detailed problem solving
- [GitHub Issues](https://github.com/your-repo/issues) - Report bugs or ask questions
