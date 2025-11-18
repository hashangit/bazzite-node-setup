# 🚀 Turn Your Bazzite Gaming PC into a Development Powerhouse

**One command. No headaches. Start coding in minutes.**

Transform your Bazzite gaming system into a professional development environment without compromising your gaming setup. Everything runs in an isolated container - your games stay untouched, your dev tools stay organized.

---

## 🎯 What This Does

Think of this as a **"Dev Environment in a Box"** for Bazzite:

- ✅ Creates a separate, isolated workspace for coding
- ✅ Installs the tools developers actually use (Node.js, Python, Git, etc.)
- ✅ Makes everything work seamlessly from your regular terminal
- ✅ Keeps your gaming system clean and unaffected
- ✅ Can be completely removed without leaving a trace

**Perfect for:**
- Gamers who want to learn programming
- Students taking coding courses
- Developers who game on Bazzite
- Anyone wanting a clean dev setup without the hassle

---

## ⚡ Quick Start

### **Step 1: Run the Setup**
```bash
./setup.sh
```

### **Step 2: Answer a Few Questions**
The script will ask you simple yes/no questions:
- Do you want Node.js for JavaScript projects? (Usually: Yes)
- Do you want Python tools? (Usually: Yes)
- Do you want Git for version control? (Usually: Yes)
- Do you want GitHub integration? (If you use GitHub: Yes)

### **Step 3: Wait 5-10 Minutes**
Grab a coffee ☕ The script is:
- Creating your development container
- Installing your selected tools
- Setting up everything automatically

### **Step 4: Restart Your Terminal**
Close your terminal and open a new one.

### **Step 5: Start Coding!**
```bash
node --version    # See your Node.js version
npm --version     # npm is ready
git --version     # Git is ready
```

**That's it. You're ready to code.**

---

## 🎁 What You Get

### **Development Tools** (You Choose)

#### JavaScript/TypeScript Development
- **Node.js** - The JavaScript runtime everyone uses
- **npm** - Node's package manager (comes with Node.js)
- **pnpm** - Faster, more efficient package manager
- **bun** - Super-fast all-in-one JavaScript toolkit

*Perfect for: Building websites, web apps, React/Vue/Angular projects, backend APIs*

#### Python Development
- **UV** - Modern, blazing-fast Python package manager
  - 10-100x faster than pip
  - Better dependency management
  - Virtual environment built-in

*Perfect for: Data science, automation, ML projects, Python apps*

#### Version Control
- **Git** - Industry-standard version control
- **GitHub CLI (gh)** - Manage GitHub from your terminal

*Perfect for: Saving your work, collaborating, managing code history*

#### Docker/Podman Integration
- Automatic aliases so Docker commands work with Podman
- Follow Docker tutorials using Podman
- Container-based development

*Perfect for: Modern web development, microservices, following tutorials*

#### Development Folder (Optional)
- Pre-organized folder structure (`~/Dev/projects`)
- Built-in documentation and cheat sheets
- Quick reference guides
- Setup instructions

*Perfect for: Staying organized, quick command lookups*

---

## 🛡️ Safety Features

### **Two Setup Modes**

**1. Update/Fix Mode (Recommended)**
- Keeps your existing setup
- Updates wrappers and fixes issues
- **100% safe** - no data loss
- Use this if something stops working

**2. Clean Install Mode**
- Removes everything and starts fresh
- Only use if things are seriously broken
- Requires confirmation for safety

### **Smart Design**
- ✅ Run the script as many times as you want - it's safe
- ✅ Container is isolated - won't affect your games
- ✅ Easy removal - delete container and wrappers, done
- ✅ Built-in diagnostics and verification

---

## 🎮 Why This Exists (For Gamers New to Coding)

### **The Problem**
You want to learn programming or do some coding, but:
- Installing dev tools can mess up your gaming setup
- Package managers conflict with each other
- Node.js installations break mysteriously
- Your system gets cluttered
- Uninstalling is a nightmare

### **The Solution**
This tool creates a **separate, isolated "coding room"** on your Bazzite PC:
- Gaming stuff stays in the main house (host system)
- Coding stuff stays in the separate room (container)
- You can walk between them seamlessly (wrappers make it transparent)
- Don't like the coding room? Delete it. Your house is untouched.

### **Real-World Example**
```bash
# You're in your regular terminal (gaming PC)
$ node --version
v20.11.0

# Behind the scenes: The tool automatically runs this in the container
# You don't see or feel any difference - it just works
```

---

## 📋 Common Questions

### **Q: Will this slow down my games?**
**A:** No. The container only runs when you use dev tools. Games are completely unaffected.

### **Q: How much disk space does it need?**
**A:** About 1-2 GB depending on which tools you select. The script checks before installing.

### **Q: Can I remove everything later?**
**A:** Yes! Run `./setup.sh`, choose "Clean Install", and confirm. Everything is removed.

### **Q: I don't know what Node.js is. Should I install it?**
**A:** If you're learning web development or JavaScript, yes! If you're only doing Python, you can skip it.

### **Q: What's the difference between Bazzite and Bazzite DX?**
**A:**
- **Bazzite** = Gaming-focused (what you probably have)
- **Bazzite DX** = Gaming + Developer tools pre-installed

The script will detect this and give you recommendations.

### **Q: Something broke. What do I do?**
**A:**
```bash
./setup.sh    # Just run it again
# Choose option 1 (Update/Fix)
# Restart your terminal
```
This fixes 90% of issues.

---

## 🔧 Troubleshooting

### **Tools not found after setup?**
**→ Restart your terminal** (PATH needs to refresh)

### **"node -v" shows nothing?**
```bash
./setup.sh         # Re-run setup
# Restart terminal
node -v            # Should work now
```

### **Need detailed diagnostics?**
```bash
./diagnose.sh      # Shows everything about your setup
```

### **Want to verify everything works?**
```bash
./verify-setup.sh  # Tests all installed tools
```

### **Still stuck?**
1. Run `./setup.sh` again (seriously, this fixes most things)
2. Read `TROUBLESHOOTING.md` for detailed help
3. Run `./diagnose.sh` and check the output

---

## 🎓 What's Next After Setup?

### **For Complete Beginners**

**1. Create Your First Project**
```bash
cd ~/Dev/projects              # Go to projects folder
mkdir my-first-project         # Create a folder
cd my-first-project            # Enter it
npm init -y                    # Initialize a Node.js project
```

**2. Try a React App (Web Development)**
```bash
cd ~/Dev/projects
npm create vite@latest my-app -- --template react
cd my-app
npm install
npm run dev
```
Open your browser to the URL shown. You just created a web app!

**3. Learn the Basics**
- Check `~/Dev/docs/QUICK_REF.md` for command cheat sheet
- Read `~/Dev/docs/SETUP_GUIDE.md` for detailed guide
- Try `~/Dev/docs/CHEAT_SHEET.md` for common commands

### **For Experienced Developers**

Your containerized environment is ready:
- All tools accessible from host terminal
- Proper process management (servers stop with terminal)
- Podman socket mounted (Docker compatibility)
- Direct container access: `distrobox enter main-dev`

Check the technical docs:
- `FIXES_CONTAINER_ERRORS.md` - Implementation details
- `specs.md` - Full technical specification
- `TOOL_EXPORT_STRATEGY.md` - How wrappers work

---

## 📚 What Gets Installed (Technical Overview)

### **The Container**
- **Name:** `main-dev`
- **Base:** Ubuntu 24.04 LTS
- **Access:** Seamless via wrapper scripts
- **Location:** Managed by distrobox/podman

### **Tool Installation Methods**
| Tool | Method | Location |
|------|--------|----------|
| Node.js | NodeSource APT repo | `/usr/bin/node` |
| npm/npx | Bundled with Node.js | `/usr/bin/npm` |
| pnpm | Standalone installer | `~/.local/share/pnpm` |
| bun | Official installer | `~/.bun/bin/bun` |
| UV | Official installer | `~/.local/bin/uv` |
| Git | Ubuntu APT | `/usr/bin/git` |
| gh | GitHub APT repo | `/usr/bin/gh` |

### **Wrapper Scripts**
- **Location:** `~/.local/bin/`
- **Purpose:** Make container tools accessible from host
- **Features:**
  - Container detection (prevents recursion)
  - Process management (cleanup on exit)
  - Transparent operation (feels native)

### **Shell Configuration**
Modified files (non-destructive, additive only):
- `~/.bashrc` - Bash configuration
- `~/.bash_profile` - Bash profile
- `~/.zshrc` - Zsh configuration (if exists)
- `~/.config/fish/config.fish` - Fish configuration (if exists)

Changes:
- Adds `~/.local/bin` to PATH
- Docker/Podman aliases (optional)
- NVM wrapper function (optional)

---

## 🗂️ Repository Structure

```
.
├── setup.sh                    # Main setup script (START HERE)
├── verify-setup.sh             # Verify everything works (generated after setup)
├── diagnose.sh                 # Diagnostic tool for troubleshooting
│
├── README.md                   # This file
├── TROUBLESHOOTING.md          # Detailed troubleshooting guide
├── FIXES_CONTAINER_ERRORS.md   # Technical implementation details
├── specs.md                    # Complete technical specification
│
└── modules/                    # Internal modules (don't touch)
    ├── setup-container.sh      # Container creation logic
    ├── install-tools.sh        # Tool installation logic
    ├── export-tools.sh         # Wrapper creation logic
    ├── configure-shell.sh      # Shell configuration logic
    └── common.sh               # Shared utilities
```

**You only need to run:** `./setup.sh`

---

## 🎯 Design Philosophy

### **For Non-Developers**
- One command to rule them all
- Interactive questions, not cryptic config files
- Clear explanations of what each tool does
- Safe defaults, easy to undo

### **For Developers**
- Modular, maintainable code
- Idempotent operations
- Comprehensive logging
- Process-aware wrappers
- Multi-shell support

### **For Everyone**
- Just works™
- Fix 90% of issues by re-running setup
- Built-in diagnostics
- Comprehensive documentation

---

## ⚙️ Advanced Features

### **Direct Container Access**
```bash
distrobox enter main-dev    # Enter the container
# Now you're inside - all tools are native
node --version
exit                        # Leave the container
```

### **Process Management**
Dev servers automatically stop when you:
- Close the terminal
- Press Ctrl+C
- Exit the session

No more orphaned processes!

### **Docker Compatibility**
With Podman socket mounted:
```bash
# These work the same
docker ps                   # (actually using podman)
docker run hello-world      # (actually using podman)
docker-compose up           # (actually using podman-compose)
```

### **Multiple Shell Support**
Automatically configures:
- Bash (most common)
- Zsh (Oh My Zsh users)
- Fish (modern shell)

### **Idempotent Design**
Run `./setup.sh` as many times as you want:
- Detects existing container (won't recreate)
- Updates wrappers to latest version
- Fixes common issues automatically
- Safe, no data loss

---

## 📊 System Requirements

### **Minimum**
- Bazzite OS (any variant)
- 5 GB free disk space
- Internet connection (for downloading tools)

### **Recommended**
- Bazzite DX variant (the script will help you switch if needed)
- 10 GB+ free disk space
- Active internet connection

### **Pre-installed on Bazzite DX**
- distrobox
- podman
- Development libraries

If you're on base Bazzite, the script will check and guide you.

---

## 🤝 Contributing

Found a bug? Have a suggestion? Contributions welcome!

1. Check existing issues
2. Create a detailed bug report
3. Submit pull requests with clear descriptions

See `CONTRIBUTING.md` for guidelines.

---

## 📜 Version History

- **v3.0** - Modular architecture, process-aware wrappers, multi-shell support
- **v2.0** - Container detection, wrapper improvements
- **v1.0** - Initial release

---

## 📄 License

This project is designed for the Bazzite community. Use freely, modify as needed, share improvements.

---

## 🙏 Credits

Built for the Bazzite gaming and development community.

**Special thanks to:**
- Bazzite team for the amazing OS
- distrobox creators for seamless container integration
- Everyone who reported issues and helped improve this tool

---

## 🎮 Happy Coding!

You're all set. Your Bazzite gaming PC is now a development machine too.

**Need help?** Read `TROUBLESHOOTING.md`
**Want details?** Read `specs.md`
**Ready to code?** `./setup.sh` and go!

---

*Last updated: 2025-01-18 | Version 3.0*
