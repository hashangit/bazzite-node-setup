# Bazzite Node.js Development Container Setup

A production-ready, automated setup for Node.js development on Bazzite using distrobox. This creates a clean, isolated development environment with all Node.js tools properly exported to your host system.

## Features

✅ **Complete Node.js Development Stack**
- Node.js (LTS version via NVM)
- npm & npx (package managers)
- pnpm (fast, disk-efficient package manager)
- bun (blazing fast all-in-one JavaScript runtime)
- NVM (Node Version Manager)

✅ **Clean Integration**
- All tools exported to host system
- No conflicts or duplication
- Proper PATH management
- Seamless terminal integration

✅ **Production Ready**
- Comprehensive error handling
- Automatic verification
- Detailed logging
- Easy uninstall process

✅ **Process Management**
- Dev servers stop when terminal closes
- No orphaned processes
- Clean session handling

## Quick Start

### Prerequisites

- Bazzite OS (or any system with distrobox)
- Internet connection
- Sudo privileges (for container setup)

### Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd bazzite-node-setup
```

2. Make the setup script executable:
```bash
chmod +x setup-dev-container.sh
```

3. Run the setup:
```bash
./setup-dev-container.sh
```

4. Restart your terminal or reload your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

5. Verify the installation:
```bash
./verify-setup.sh
```

## What Gets Installed

### Container: `main-dev`
- **OS**: Ubuntu 24.04 LTS
- **Location**: Managed by distrobox
- **Isolation**: Complete isolation from host system

### Tools Installed

| Tool | Purpose | Version |
|------|---------|---------|
| **node** | JavaScript runtime | LTS (currently v20.x) |
| **npm** | Node package manager | Latest (bundled with Node) |
| **npx** | Package executor | Latest (bundled with Node) |
| **pnpm** | Fast package manager | Latest |
| **bun** | All-in-one JS runtime | Latest |
| **nvm** | Node version manager | Latest |

### Export Locations

All tools are exported to: `~/.local/bin/`

This directory is automatically added to your PATH by the script.

## Usage Guide

### Basic Commands

```bash
# Check Node.js version
node --version

# Run a JavaScript file
node script.js

# Install packages with npm
npm install express

# Install packages with pnpm (faster)
pnpm install express

# Install packages with bun (fastest)
bun install express

# Run scripts
npm run dev
pnpm dev
bun dev

# Execute packages without installing
npx create-react-app my-app
bunx create-react-app my-app
```

### Managing Node.js Versions

```bash
# List available Node.js versions
nvm list-remote

# Install a specific version
nvm install 18.20.0

# Switch to a different version
nvm use 18.20.0

# Set default version
nvm alias default 18.20.0

# Check current version
nvm current
```

### Working with Projects

#### Creating a New Project

```bash
# Create a new directory
mkdir my-project
cd my-project

# Initialize a new project
npm init -y
# or
pnpm init
# or
bun init
```

#### Running Development Servers

```bash
# Start a dev server
npm run dev
# or
pnpm dev
# or
bun dev
```

**Important**: When you close the terminal, the dev server will automatically stop. This is the expected behavior with distrobox integration.

#### Installing Dependencies

```bash
# Using npm
npm install

# Using pnpm (faster, saves disk space)
pnpm install

# Using bun (fastest)
bun install
```

### Process Management

When you run commands from your host terminal, they execute inside the container but are tied to your terminal session:

- ✅ **Closing terminal stops processes** (prevents orphaned processes)
- ✅ **Ctrl+C works as expected** (interrupts running processes)
- ✅ **Background jobs inherit terminal session** (clean process management)

If you need persistent processes that survive terminal closure, run them inside the container directly:

```bash
# Enter the container
distrobox enter main-dev

# Run your process in the background
nohup npm run dev &

# Exit container
exit
```

## Verification

Run the verification script to check that all tools are properly installed and accessible:

```bash
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

## Advanced Usage

### Entering the Container

To work directly inside the container:

```bash
distrobox enter main-dev
```

### Updating Tools

#### Update Node.js

```bash
nvm install node --reinstall-packages-from=current
nvm alias default node
```

#### Update npm

```bash
npm install -g npm@latest
```

#### Update pnpm

```bash
npm install -g pnpm@latest
# or
pnpm add -g pnpm
```

#### Update bun

```bash
bun upgrade
```

### Installing Additional Global Packages

```bash
# Install a global package
npm install -g typescript
pnpm add -g typescript
bun install -g typescript

# Export the binary to host (if needed)
distrobox-export --bin ~/.local/bin/tsc --export-path ~/.local/bin
```

### Multiple Node.js Versions

NVM allows you to install and switch between multiple Node.js versions:

```bash
# Install multiple versions
nvm install 18
nvm install 20
nvm install 21

# List installed versions
nvm list

# Switch between versions
nvm use 18
nvm use 20

# Use different versions for different projects
cd project-a
echo "18" > .nvmrc
nvm use  # Uses version from .nvmrc

cd ../project-b
echo "20" > .nvmrc
nvm use  # Uses version from .nvmrc
```

## Troubleshooting

### Tools not found after installation

**Solution**: Ensure `~/.local/bin` is in your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Permission denied errors

**Solution**: Ensure scripts are executable:

```bash
chmod +x setup-dev-container.sh verify-setup.sh uninstall.sh
```

### Container not starting

**Solution**: Check distrobox status:

```bash
distrobox list
systemctl --user status distrobox
```

### Export errors

**Solution**: Manually re-export tools:

```bash
# Re-run the export section
distrobox enter main-dev
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Export node
distrobox-export --bin $(which node) --export-path ~/.local/bin

# Repeat for other tools
```

### Node version conflicts

**Solution**: Use NVM to manage versions:

```bash
nvm list
nvm use <version>
nvm alias default <version>
```

For more detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Uninstallation

To completely remove the development container and all exported tools:

```bash
./uninstall.sh
```

This will:
1. Remove all exported binaries from `~/.local/bin`
2. Delete the `main-dev` container
3. Clean up all related files

**Note**: This does NOT remove distrobox itself or affect other containers.

## File Structure

```
bazzite-node-setup/
├── setup-dev-container.sh   # Main setup script
├── verify-setup.sh           # Verification script (created by setup)
├── uninstall.sh              # Uninstall script (created by setup)
├── setup.log                 # Setup log file (created during setup)
├── README.md                 # This file
├── USER_GUIDE.md             # Detailed user guide
└── TROUBLESHOOTING.md        # Troubleshooting guide
```

## Technical Details

### How It Works

1. **Container Creation**: Creates an Ubuntu 24.04 distrobox container named `main-dev`
2. **Tool Installation**: Installs Node.js tools inside the container
3. **Binary Export**: Uses `distrobox-export` to make tools available on the host
4. **PATH Management**: Ensures `~/.local/bin` is in PATH for seamless access

### Export Mechanism

Distrobox creates wrapper scripts in `~/.local/bin` that:
- Execute commands inside the container
- Pass arguments correctly
- Handle stdin/stdout/stderr properly
- Maintain environment variables
- Preserve working directory
- Inherit terminal session (process lifecycle)

### Why This Approach?

- **Isolation**: Keep development tools separate from immutable host OS
- **Cleanliness**: No pollution of host system
- **Flexibility**: Easy to reset, update, or remove
- **Compatibility**: Works with Bazzite's immutable filesystem
- **Portability**: Same setup works across different machines

## Security Considerations

- Container runs with your user privileges (no root)
- Tools execute in isolated environment
- Network access is controlled by container settings
- No modification to host system (except `~/.local/bin`)

## Contributing

Contributions are welcome! Please:
1. Test thoroughly on Bazzite
2. Update documentation
3. Follow existing code style
4. Add verification tests

## License

MIT License - Feel free to use and modify for your needs.

## Support

- **Issues**: Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Questions**: Open an issue on GitHub
- **Updates**: Pull latest changes and re-run setup

## Changelog

### Version 1.0.0 (Initial Release)
- Complete Node.js development environment setup
- Support for npm, pnpm, and bun
- NVM integration for version management
- Automatic export and verification
- Comprehensive documentation
- Uninstall script

---

**Made for Bazzite** 🚀 | **Production Ready** ✅ | **Zero Conflicts** 🎯
