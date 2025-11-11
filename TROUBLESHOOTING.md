# Troubleshooting Guide

Comprehensive troubleshooting guide for the Bazzite Node.js Development Container setup.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Command Not Found Errors](#command-not-found-errors)
3. [Permission Issues](#permission-issues)
4. [Container Issues](#container-issues)
5. [Export Issues](#export-issues)
6. [Network Issues](#network-issues)
7. [Version Conflicts](#version-conflicts)
8. [Package Installation Issues](#package-installation-issues)
9. [Performance Issues](#performance-issues)
10. [Uninstallation Issues](#uninstallation-issues)

---

## Installation Issues

### Issue: "distrobox: command not found"

**Cause**: Distrobox is not installed on your system.

**Solution**:

```bash
# On Bazzite, distrobox should be pre-installed
# Verify it's available
rpm-ostree status

# If missing, you may need to rebase to Bazzite
```

**Alternative**: Check if distrobox is in a different location:
```bash
which distrobox
find /usr -name distrobox 2>/dev/null
```

---

### Issue: "Container creation failed"

**Cause**: Various reasons - network issues, podman problems, or system resources.

**Solution 1**: Check system resources
```bash
# Check disk space
df -h

# Check memory
free -h

# Ensure you have at least 5GB free space and 2GB RAM
```

**Solution 2**: Check podman status
```bash
# Check if podman is running
systemctl --user status podman.socket

# Restart podman if needed
systemctl --user restart podman.socket
```

**Solution 3**: Try creating the container manually
```bash
# Create container manually
distrobox create --name main-dev --image ubuntu:24.04 --yes

# Check for errors
distrobox list
```

**Solution 4**: Check for SELinux issues
```bash
# Check SELinux status
sestatus

# If SELinux is causing issues, check audit logs
sudo ausearch -m avc -ts recent
```

---

### Issue: "Setup script fails during package installation"

**Cause**: Network issues or repository problems.

**Solution**:

```bash
# Enter the container manually
distrobox enter main-dev

# Update package lists
sudo apt-get update

# Try installing packages one by one
sudo apt-get install -y curl
sudo apt-get install -y wget
sudo apt-get install -y git
sudo apt-get install -y build-essential

# Exit and re-run setup
exit
./setup-dev-container.sh
```

---

### Issue: "NVM installation fails"

**Cause**: Network issues or curl/wget not available.

**Solution 1**: Manual NVM installation
```bash
# Enter container
distrobox enter main-dev

# Install NVM manually
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Or with wget
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Verify
nvm --version

# Exit
exit
```

**Solution 2**: Check GitHub connectivity
```bash
# Test GitHub connectivity
curl -I https://raw.githubusercontent.com

# If this fails, check your network/firewall settings
```

---

### Issue: "Bun installation fails"

**Cause**: System compatibility or network issues.

**Solution**:

```bash
# Enter container
distrobox enter main-dev

# Try manual installation with verbose output
curl -fsSL https://bun.sh/install | bash -x

# Or download directly
wget https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip
unzip bun-linux-x64.zip
mkdir -p ~/.bun/bin
mv bun-linux-x64/bun ~/.bun/bin/
chmod +x ~/.bun/bin/bun

# Verify
~/.bun/bin/bun --version

# Exit
exit
```

---

## Command Not Found Errors

### Issue: "node: command not found"

**Cause**: Tools are not in your PATH or exports failed.

**Solution 1**: Check PATH
```bash
# Check if ~/.local/bin is in PATH
echo $PATH | grep -o "$HOME/.local/bin"

# If not found, add it
export PATH="$HOME/.local/bin:$PATH"

# Make it permanent
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Solution 2**: Verify exports
```bash
# Check if exported binaries exist
ls -la ~/.local/bin/ | grep -E "node|npm|pnpm|bun"

# If missing, re-export manually
distrobox-export --bin ~/.nvm/versions/node/*/bin/node --export-path ~/.local/bin --container main-dev
```

**Solution 3**: Create manual wrapper
```bash
# Create wrapper script
cat > ~/.local/bin/node << 'EOF'
#!/usr/bin/env bash
distrobox enter -n main-dev -- bash -lc "node $*"
EOF

chmod +x ~/.local/bin/node

# Test
node --version
```

---

### Issue: "nvm: command not found"

**Cause**: NVM is not exported or not loaded.

**Solution**:

```bash
# Check if NVM is installed in container
distrobox enter main-dev -- bash -lc "command -v nvm"

# Create NVM wrapper script
mkdir -p ~/.local/bin
cat > ~/.local/bin/nvm << 'EOF'
#!/usr/bin/env bash
distrobox enter -n main-dev -- bash -lc "export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"; nvm $*"
EOF

chmod +x ~/.local/bin/nvm

# Test
nvm --version
```

---

### Issue: "pnpm: command not found"

**Cause**: pnpm not installed or not exported.

**Solution**:

```bash
# Install pnpm in container
distrobox enter main-dev -- bash -lc "npm install -g pnpm"

# Export pnpm
distrobox enter main-dev -- bash -lc "which pnpm" | xargs -I {} distrobox-export --bin {} --export-path ~/.local/bin --container main-dev

# Verify
pnpm --version
```

---

## Permission Issues

### Issue: "Permission denied" when running setup script

**Cause**: Script is not executable.

**Solution**:

```bash
# Make script executable
chmod +x setup-dev-container.sh verify-setup.sh uninstall.sh

# Run again
./setup-dev-container.sh
```

---

### Issue: "Permission denied" when exporting binaries

**Cause**: Insufficient permissions for ~/.local/bin

**Solution**:

```bash
# Create directory with correct permissions
mkdir -p ~/.local/bin
chmod 755 ~/.local/bin

# Ensure ownership is correct
sudo chown -R $USER:$USER ~/.local

# Try export again
```

---

### Issue: "sudo: no tty present and no askpass program specified"

**Cause**: Container needs passwordless sudo or you're not in sudoers.

**Solution**:

```bash
# Enter container
distrobox enter main-dev

# Add yourself to sudoers (if needed)
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER

# Exit and retry
exit
```

---

## Container Issues

### Issue: "Container 'main-dev' not found"

**Cause**: Container was deleted or never created.

**Solution**:

```bash
# List existing containers
distrobox list

# Create the container
distrobox create --name main-dev --image ubuntu:24.04 --yes

# Re-run setup
./setup-dev-container.sh
```

---

### Issue: "Container won't start"

**Cause**: Podman issues or corrupt container.

**Solution 1**: Restart podman
```bash
# Stop all containers
distrobox stop --all

# Restart podman
systemctl --user restart podman.socket

# Try again
distrobox enter main-dev
```

**Solution 2**: Remove and recreate container
```bash
# Remove container
distrobox rm main-dev --force

# Recreate
distrobox create --name main-dev --image ubuntu:24.04 --yes

# Re-run setup
./setup-dev-container.sh
```

---

### Issue: "Container is slow"

**Cause**: Resource constraints or I/O issues.

**Solution**:

```bash
# Check container resource usage
podman stats $(distrobox list | grep main-dev | awk '{print $NF}')

# Increase container resources (if needed)
distrobox stop main-dev
distrobox rm main-dev
distrobox create --name main-dev --image ubuntu:24.04 --memory 4g --cpus 4 --yes

# Re-run setup
./setup-dev-container.sh
```

---

### Issue: "Can't access files from host in container"

**Cause**: Home directory mounting issue.

**Solution**:

```bash
# Check if home is mounted
distrobox enter main-dev -- df -h | grep $HOME

# Home should be automatically mounted
# If not, recreate container with explicit mount:
distrobox rm main-dev --force
distrobox create --name main-dev --image ubuntu:24.04 --home $HOME --yes
```

---

## Export Issues

### Issue: "Exported commands don't work"

**Cause**: Export scripts are broken or PATH issues.

**Solution 1**: Check export scripts
```bash
# List exported scripts
ls -la ~/.local/bin/

# Check one script
cat ~/.local/bin/node

# Script should contain distrobox-enter command
# If not, re-export
```

**Solution 2**: Re-export all tools
```bash
# Remove old exports
rm -f ~/.local/bin/{node,npm,npx,pnpm,bun,bunx,nvm}

# Re-run export section manually
distrobox enter main-dev -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; which node' | xargs -I {} distrobox-export --bin {} --export-path ~/.local/bin --container main-dev

# Repeat for each tool
```

---

### Issue: "Exported commands are slow"

**Cause**: Normal behavior - commands run inside container.

**Solution**: This is expected. Each command has a small overhead (~100-200ms) for entering the container. For better performance:

```bash
# Option 1: Work directly in container for intensive tasks
distrobox enter main-dev
# Do your work here
exit

# Option 2: Use long-running processes (dev servers)
# These start once and run continuously
npm run dev
```

---

## Network Issues

### Issue: "Cannot download packages"

**Cause**: Network connectivity issues.

**Solution 1**: Check network
```bash
# Test connectivity from host
ping -c 3 google.com

# Test from container
distrobox enter main-dev -- ping -c 3 google.com

# Test npm registry
distrobox enter main-dev -- curl -I https://registry.npmjs.org
```

**Solution 2**: Configure npm proxy (if behind firewall)
```bash
distrobox enter main-dev

# Set proxy
npm config set proxy http://proxy.company.com:8080
npm config set https-proxy http://proxy.company.com:8080

# Or use registry mirror
npm config set registry https://registry.npmmirror.com

exit
```

---

### Issue: "Dev server not accessible from browser"

**Cause**: Port forwarding issue or firewall.

**Solution 1**: Check if server is listening
```bash
# From container
distrobox enter main-dev
lsof -i :3000  # Replace 3000 with your port
exit
```

**Solution 2**: Ensure binding to 0.0.0.0
```javascript
// In your server code, bind to all interfaces
app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on http://localhost:3000');
});
```

**Solution 3**: Check firewall
```bash
# Check firewall status
sudo firewall-cmd --list-all

# If needed, allow port
sudo firewall-cmd --add-port=3000/tcp
```

---

## Version Conflicts

### Issue: "Wrong Node.js version is being used"

**Cause**: Multiple Node installations or NVM not configured correctly.

**Solution**:

```bash
# Check which node is being used
which node

# Should point to ~/.local/bin/node
# If not, check PATH order
echo $PATH

# Enter container and set default version
distrobox enter main-dev
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm list
nvm use 20  # Or your preferred version
nvm alias default 20
exit

# Test from host
node --version
```

---

### Issue: "npm version mismatch"

**Cause**: npm not updated with Node.js.

**Solution**:

```bash
# Update npm in container
distrobox enter main-dev -- bash -lc "npm install -g npm@latest"

# Re-export npm
distrobox enter main-dev -- bash -lc "which npm" | xargs -I {} distrobox-export --bin {} --export-path ~/.local/bin --container main-dev

# Verify
npm --version
```

---

### Issue: "Package requires different Node version"

**Cause**: Project requires specific Node version.

**Solution**:

```bash
# Install required version
nvm install 18.20.0

# Switch to it
nvm use 18.20.0

# Or create .nvmrc in project
echo "18.20.0" > .nvmrc
nvm use

# Install dependencies with correct version
npm install
```

---

## Package Installation Issues

### Issue: "npm install fails with EACCES error"

**Cause**: Permission issues with npm global directory.

**Solution**:

```bash
# Fix npm permissions (run in container)
distrobox enter main-dev

# Configure npm to use user directory
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

# Update PATH (add to ~/.bashrc in container)
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

exit
```

---

### Issue: "Package installation fails with ERESOLVE error"

**Cause**: Dependency conflicts.

**Solution**:

```bash
# Option 1: Use --legacy-peer-deps
npm install --legacy-peer-deps

# Option 2: Use --force
npm install --force

# Option 3: Use pnpm (better at resolving dependencies)
pnpm install
```

---

### Issue: "gyp ERR! build error"

**Cause**: Missing build tools for native modules.

**Solution**:

```bash
# Install build dependencies in container
distrobox enter main-dev

sudo apt-get update
sudo apt-get install -y build-essential python3

# Also install node-gyp globally
npm install -g node-gyp

exit

# Try installation again
npm install
```

---

### Issue: "Package not found in registry"

**Cause**: Typo, private package, or registry issue.

**Solution**:

```bash
# Check package name on npmjs.com

# Check registry configuration
npm config get registry

# Reset to default if needed
npm config set registry https://registry.npmjs.org/

# Clear cache
npm cache clean --force

# Try again
npm install package-name
```

---

## Performance Issues

### Issue: "npm install is very slow"

**Cause**: npm is inherently slower than alternatives.

**Solution**: Use pnpm or bun instead

```bash
# Option 1: Use pnpm (faster, saves disk space)
pnpm install

# Option 2: Use bun (fastest)
bun install

# Both are already installed in your setup!
```

---

### Issue: "Container uses too much disk space"

**Cause**: npm cache, node_modules, or container images.

**Solution**:

```bash
# Clean npm cache
npm cache clean --force

# Clean pnpm store
pnpm store prune

# Remove node_modules if not needed
rm -rf node_modules

# Check container size
podman images

# Clean unused container images
podman image prune -a
```

---

### Issue: "High memory usage"

**Cause**: Dev server or memory leaks.

**Solution**:

```bash
# Check memory usage
free -h

# Check container memory
podman stats

# Restart container
distrobox stop main-dev
distrobox enter main-dev  # Auto-starts

# If persistent, limit container memory
distrobox rm main-dev --force
distrobox create --name main-dev --image ubuntu:24.04 --memory 4g --yes
```

---

## Uninstallation Issues

### Issue: "Uninstall script fails"

**Cause**: Missing permissions or container already deleted.

**Solution**:

```bash
# Manual uninstall
# Remove exported binaries
rm -f ~/.local/bin/{node,npm,npx,pnpm,bun,bunx,nvm}

# Remove container
distrobox rm main-dev --force

# Clean up setup files
cd ~/bazzite-node-setup
rm -f setup.log verify-setup.sh uninstall.sh

# Verify
distrobox list
ls ~/.local/bin/
```

---

### Issue: "Container won't delete"

**Cause**: Container is running or locked.

**Solution**:

```bash
# Stop container first
distrobox stop main-dev

# Force remove
distrobox rm main-dev --force

# If still fails, remove podman container directly
podman ps -a | grep main-dev
podman rm -f <container-id>
```

---

## Advanced Diagnostics

### Collect Debug Information

```bash
# System info
cat /etc/os-release
uname -a

# Distrobox version
distrobox version

# Podman version
podman --version

# Container status
distrobox list

# Exported binaries
ls -la ~/.local/bin/ | grep -E "node|npm|pnpm|bun"

# PATH
echo $PATH

# Check logs
cat setup.log

# Container logs
distrobox enter main-dev -- dmesg | tail -50
```

### Enable Verbose Logging

```bash
# Run setup with debug output
bash -x ./setup-dev-container.sh 2>&1 | tee debug.log

# Check debug.log for errors
```

### Test Individual Components

```bash
# Test distrobox
distrobox create --name test-container --image ubuntu:24.04 --yes
distrobox enter test-container -- echo "Works!"
distrobox rm test-container --force

# Test NVM in container
distrobox enter main-dev -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm --version'

# Test exports
cat ~/.local/bin/node
```

---

## Getting Additional Help

If you've tried all solutions and still have issues:

1. **Check logs**: Review `setup.log` for specific error messages
2. **Search issues**: Look for similar problems on GitHub
3. **Create issue**: Open a new issue with:
   - Your system info (`cat /etc/os-release`)
   - Error messages (from `setup.log`)
   - Steps to reproduce
   - What you've already tried

4. **Community**: Ask on Bazzite Discord or Universal Blue community

---

## Prevention Tips

To avoid issues in the future:

✅ **Keep your system updated**
```bash
rpm-ostree upgrade
```

✅ **Regularly update tools**
```bash
nvm install node --reinstall-packages-from=current
npm update -g
pnpm add -g pnpm
bun upgrade
```

✅ **Clean caches periodically**
```bash
npm cache clean --force
pnpm store prune
```

✅ **Use .nvmrc files** for consistent Node versions
```bash
echo "20" > .nvmrc
```

✅ **Commit lock files** for reproducible installs
```bash
git add package-lock.json pnpm-lock.yaml
```

---

**Still stuck? Don't hesitate to ask for help! The community is here to assist you.**
