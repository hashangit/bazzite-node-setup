# Troubleshooting: Tools Not Working on Host

## Issue
You ran `node -v` on the host and it returns no output (fails silently).

## Root Cause Analysis

The setup you ran earlier created wrappers with OLD code that has bugs. The wrappers I just fixed include:
1. Container detection to prevent recursive entry
2. Robust distrobox path detection with fallbacks
3. Better error messages

**You need to regenerate the wrappers with the new code.**

## Step-by-Step Fix

### Step 1: Pull Latest Changes
```bash
cd ~/bazzite-node-setup
git pull origin claude/fix-distrobox-container-error-011CV5PVWhhuDwgy9LRmYXww
```

### Step 2: Run Diagnostic (Optional but Recommended)
This will help identify the current state:
```bash
./diagnose.sh 2>&1 | tee diagnostic-output.txt
```

**Please share the output with me** so I can see exactly what's wrong.

### Step 3: Re-run Setup to Regenerate Wrappers
```bash
./setup.sh
```

**Important**: You can skip the interactive prompts by just pressing Enter to accept defaults.

### Step 4: Test on Host
```bash
# Test that tools work on host
node -v
npm -v
pnpm -v
git --version
gh --version
```

You should see version numbers, not errors or silence.

### Step 5: Test Inside Container
```bash
# Enter container
distrobox enter main-dev

# Test tools (should work without "distrobox: command not found")
node -v
npm -v
git --version

# Exit container
exit
```

## Quick Diagnostic Commands

### Check #1: Is ~/.local/bin in your PATH?
```bash
echo $PATH | grep -o "$HOME/.local/bin"
```

If nothing, restart terminal or run: `source ~/.bashrc`

### Check #2: Are wrappers executable?
```bash
ls -l ~/.local/bin/node
```

### Check #3: Is distrobox available?
```bash
which distrobox
```

### Check #4: Does container exist?
```bash
distrobox list | grep main-dev
```

### Check #5: Manual wrapper test
```bash
bash -x ~/.local/bin/node -v 2>&1 | head -50
```

This shows exactly where it fails.

## Alternative: Manual Wrapper Regeneration

Don't want to re-run full setup? Regenerate just the wrappers:

```bash
cd ~/bazzite-node-setup
source modules/common.sh
source modules/export-tools.sh
export CONTAINER_NAME="main-dev"
export INSTALL_NODEJS=true
export INSTALL_GIT=true
export INSTALL_GITHUB_CLI=true
export INSTALL_PYTHON=true
export_all_tools
```

## Need More Help?

Run diagnostic and share output:
```bash
./diagnose.sh 2>&1 | tee diagnostic-output.txt
```

Then share the `diagnostic-output.txt` content.
