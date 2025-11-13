# Bazzite Development Container Setup

**One script. That's it.**

## Quick Start

```bash
./setup.sh
```

That's the ONLY command you need. Everything else is automatic.

## What It Does

1. Creates an Ubuntu container named `main-dev`
2. Installs development tools (Node.js, npm, pnpm, bun, git, gh, uv)
3. Exports tools to your host system
4. Configures your shell (bash/zsh/fish)
5. Makes everything just work

## After Setup

Tools work everywhere:

```bash
# On host
node -v
npm -v
git --version

# Inside container (works the same!)
distrobox enter main-dev
node -v
git --version
exit
```

## Setup Options

When you run `./setup.sh`, you can choose:

**1. Update/Fix Existing Setup (Default)**
- Keeps your container and tools
- Updates wrappers with latest fixes
- Safe, no data loss
- Use this to fix issues

**2. Clean Install**
- Removes existing container
- Deletes all wrapper scripts
- Fresh installation from scratch
- Use this if things are seriously broken

## If Something Goes Wrong

```bash
# Update/fix existing setup
./setup.sh
# Choose option 1 (default)

# Or do a clean install
./setup.sh
# Choose option 2, confirm with "yes"

# Get detailed diagnostics
./diagnose.sh
```

## Files in This Repo

**Scripts:**
- **setup.sh** - Main setup script (the only one you need to run)
- **diagnose.sh** - Optional diagnostic tool for troubleshooting
- **verify-setup.sh** - Generated after setup, tests everything works

**Documentation:**
- **README.md** - This file
- **TROUBLESHOOTING.md** - Help when things go wrong
- **FIXES_CONTAINER_ERRORS.md** - Technical details of fixes
- **CONTRIBUTING.md** - For contributors

**Directories:**
- **modules/** - Internal modules (don't touch)
- **archive/** - Old docs and scripts (reference only)

## Common Issues

### Tools don't work after setup

**Solution:** Restart your terminal
```bash
# Close terminal, open new one, then test
node -v
```

### Need to fix wrapper issues

**Solution:** Re-run setup in update mode (safe, keeps your data)
```bash
./setup.sh
# Choose option 1 (default)
```

### Everything is broken, want fresh start

**Solution:** Re-run setup in clean install mode
```bash
./setup.sh
# Choose option 2, type "yes" to confirm
```

## What Gets Installed

**Node.js Stack:**
- Node.js LTS (v24.x)
- npm, npx
- pnpm
- bun

**Python:**
- UV (fast package manager)

**Git:**
- git
- GitHub CLI (gh)

**Bonus:**
- Docker/Podman compatibility
- Process management (dev servers stop with terminal)
- Multi-shell support (bash, zsh, fish)

## Technical Details

**How it works:**
- Tools are installed in an Ubuntu 24.04 container
- Wrapper scripts in `~/.local/bin` provide seamless access from host
- Wrappers detect if you're inside the container (no recursion)
- Process management ensures dev servers terminate properly

**Container:**
- Name: `main-dev`
- Image: `ubuntu:24.04`
- Podman socket: Mounted for Docker compatibility

## Documentation

- **FIXES_CONTAINER_ERRORS.md** - What was broken and how it's fixed
- **TROUBLESHOOTING.md** - Detailed troubleshooting guide
- **~/Dev/docs/** - Setup guides and cheat sheets (if you chose to create Dev folder)

## Support

Something not working?
1. Run `./setup.sh` again
2. Restart your terminal
3. Run `./diagnose.sh` and check output
4. Check TROUBLESHOOTING.md

That's it. Keep it simple.
