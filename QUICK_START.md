# Quick Start Guide

Get up and running with Node.js development on Bazzite in 5 minutes!

## Installation (3 commands)

```bash
# 1. Make setup script executable
chmod +x setup-dev-container.sh

# 2. Run setup
./setup-dev-container.sh

# 3. Restart terminal or reload PATH
export PATH="$HOME/.local/bin:$PATH"
```

## Verify Installation

```bash
# Check all tools are working
node --version
npm --version
pnpm --version
bun --version
```

## Your First Project

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
  res.send('Hello from Bazzite!');
});

app.listen(3000, () => {
  console.log('Server running at http://localhost:3000');
});
EOF

# Run your app
node app.js
```

Open http://localhost:3000 in your browser!

## Common Commands

```bash
# Install packages
npm install express
pnpm add express      # faster
bun add express       # fastest

# Run scripts
npm run dev
pnpm dev
bun dev

# Execute without installing
npx create-react-app my-app
bunx create-react-app my-app

# Switch Node.js versions
nvm install 18
nvm use 18
nvm alias default 18
```

## What's Installed?

- ✅ **Node.js** (LTS) - JavaScript runtime
- ✅ **npm** - Package manager
- ✅ **npx** - Package executor
- ✅ **pnpm** - Fast package manager
- ✅ **bun** - Ultra-fast runtime
- ✅ **nvm** - Version manager

## Need Help?

- 📖 **Full Documentation**: [README.md](README.md)
- 👤 **User Guide**: [USER_GUIDE.md](USER_GUIDE.md)
- 🔧 **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Running Tests

```bash
# Verify everything works
chmod +x test-setup.sh
./test-setup.sh
```

## Uninstall

```bash
# Remove everything
chmod +x uninstall.sh
./uninstall.sh
```

---

**That's it! You're ready to develop!** 🚀

For detailed instructions and advanced usage, check out the [full documentation](README.md).
