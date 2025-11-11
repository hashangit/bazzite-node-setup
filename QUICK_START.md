# Quick Start Guide

Get up and running with Node.js development on Bazzite in 5 minutes!

## 🚀 Installation (3 commands)

### Recommended: v3.0 (Full-Featured)

```bash
# 1. Make setup script executable
chmod +x setup.sh

# 2. Run setup (interactive - choose your tools)
./setup.sh

# 3. Restart terminal or reload PATH
source ~/.bashrc  # or ~/.zshrc for zsh
```

### Alternative: v2.0 (Legacy)

```bash
# 1. Make setup script executable
chmod +x setup-dev-container.sh

# 2. Run setup
./setup-dev-container.sh

# 3. Restart terminal or reload PATH
export PATH="$HOME/.local/bin:$PATH"
```

**Recommendation:** Use v3.0 (setup.sh) for the complete experience with all features.

---

## ✅ Verify Installation

```bash
# Check all tools are working
node --version
npm --version
pnpm --version
bun --version
git --version
gh --version
uv --version
```

---

## 🎯 Your First Project

```bash
# Create a new project
mkdir my-app
cd my-app
npm init -y

# Install a package
npm install express

# Create app.js
cat > app.js << 'EOF'
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello from Bazzite! 🚀');
});

app.listen(3000, () => {
  console.log('Server running at http://localhost:3000');
});
EOF

# Run your app
node app.js
```

Open http://localhost:3000 in your browser!

**Note:** With v3.0, the server automatically stops when you close the terminal. ✅

---

## 💡 Common Commands

### Package Management

```bash
# Install packages (choose your favorite)
npm install express        # npm (traditional)
pnpm add express          # pnpm (faster, efficient)
bun add express           # bun (fastest)

# Run scripts
npm run dev
pnpm dev
bun dev

# Execute without installing
npx create-react-app my-app
bunx create-react-app my-app
```

### Node.js Version Management

```bash
# Using NVM (v3.0 includes wrapper function)
nvm install 18            # Install Node 18
nvm install 20            # Install Node 20
nvm use 18                # Switch to Node 18
nvm list                  # List installed versions
nvm alias default 20      # Set default version
```

### Git & GitHub

```bash
# Version control
git clone <repository-url>
git add .
git commit -m "Initial commit"
git push

# GitHub CLI
gh repo create my-project
gh issue list
gh pr create
```

### Python

```bash
# Fast Python package management with UV
uv pip install requests
uv pip list
uv venv .venv
```

---

## 📦 What's Installed?

| Tool | Purpose | v2.0 | v3.0 |
|------|---------|------|------|
| **Node.js** (LTS) | JavaScript runtime | ✅ | ✅ |
| **npm** | Package manager | ✅ | ✅ |
| **npx** | Package executor | ✅ | ✅ |
| **pnpm** | Fast package manager | ✅ | ✅ |
| **bun** | Ultra-fast runtime | ✅ | ✅ |
| **nvm** | Version manager | ⚠️ | ✅ |
| **git** | Version control | ✅ | ✅ |
| **gh** | GitHub CLI | ✅ | ✅ |
| **uv** | Python package manager | ✅ | ✅ |
| **Process Management** | Auto-terminate servers | ❌ | ✅ |
| **Dev Folder** | Organized workspace | ✅ | ✅ |
| **Docker Aliases** | Podman compatibility | ✅ | ✅ |

✅ = Fully working | ⚠️ = Partial | ❌ = Not available

---

## 🎨 Optional Features

### Dev Folder with Guides

If you chose to create the Dev folder during setup, you'll have:

```bash
~/Dev/
├── projects/           # Your projects go here
└── docs/              # Comprehensive guides
    ├── README.md      # Overview
    ├── SETUP_GUIDE.md # Complete guide
    ├── CHEAT_SHEET.md # Quick reference
    └── QUICK_REF.md   # Common commands
```

### Docker/Podman Aliases

If you enabled Docker aliases:

```bash
# Use Docker commands with Podman
docker ps
docker run -it ubuntu bash
docker build -t myapp .
docker compose up
```

---

## 🔧 Working Inside the Container

Sometimes you need direct access:

```bash
# Enter the development container
distrobox enter main-dev

# Now you're inside Ubuntu 24.04
# Do whatever you need

# Exit when done
exit
```

---

## 🆘 Need Help?

### Tools not found?

```bash
# Add to PATH (if not automatic)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Want to start over?

```bash
# Remove everything and start fresh
distrobox rm main-dev --force
rm -rf ~/.local/bin/{node,npm,npx,pnpm,bun,git,gh,uv}
./setup.sh
```

### More Help

- 📖 **Full Documentation**: [README.md](README.md)
- 👤 **User Guide**: [USER_GUIDE.md](USER_GUIDE.md)
- 🔧 **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- ⭐ **Feature Status**: [COMPLETION_SUMMARY.md](COMPLETION_SUMMARY.md)

---

## 🧪 Running Tests

```bash
# Verify everything works (if test script exists)
chmod +x test-setup.sh
./test-setup.sh
```

---

## 🗑️ Uninstall

```bash
# Remove the container
distrobox rm main-dev --force

# Remove exported tools
rm -rf ~/.local/bin/{node,npm,npx,pnpm,bun,git,gh,uv}

# Clean up shell configs (optional)
# Edit ~/.bashrc, ~/.zshrc, etc. to remove added lines
```

---

## 🚀 Next Steps

1. **Create your first project** (see example above)
2. **Explore the Dev folder guides** (if created during setup)
3. **Read the [USER_GUIDE.md](USER_GUIDE.md)** for advanced usage
4. **Join the Bazzite community** and share your experience

---

**That's it! You're ready to develop!** 🎉

For detailed instructions and advanced usage, check out the [full README](README.md).

---

**Version:** 3.0 | **Status:** 100% Complete ✅ | **Recommended:** setup.sh (v3.0)
