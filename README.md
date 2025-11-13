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

## If Something Goes Wrong

```bash
# Just run setup again - it's idempotent
./setup.sh

# Or get detailed diagnostics
./diagnose.sh
```

## Files You Need to Care About

- **setup.sh** - The only script you run
- **verify-setup.sh** - Generated after setup, tests everything works

## Files You Don't Need to Care About

- `diagnose.sh` - Optional diagnostic tool
- `regenerate-wrappers.sh` - Legacy, not needed (setup.sh does this)
- `TROUBLESHOOTING.md` - Only if you have issues
- `QUICK_FIX.md` - Legacy documentation
- Everything else - Just documentation

## Common Issues

### Tools don't work after setup

Solution: Restart your terminal
```bash
# New terminal window, then test
node -v
```

### Want to re-run setup

No problem, it's safe to run multiple times:
```bash
./setup.sh
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
