# Quick Fix: Wrapper Not Working

## Problem Summary

Your diagnostic showed:
1. ✓ Wrappers exist at `~/.local/bin/`
2. ✓ Distrobox is available
3. ✓ Container 'main-dev' exists
4. ✗ **But wrappers have OLD code (missing container detection)**
5. ✗ Exit code 149 when running wrappers
6. ✗ Recursive wrapper issue inside container

## Root Cause

**Bash function caching**: When you ran `./setup.sh`, it may have used cached function definitions from a previous session, so the wrappers were created with the OLD code even though `export-tools.sh` has the NEW fixed code.

## Solution: Run This ONE Command

```bash
cd ~/bazzite-node-setup
git pull
./regenerate-wrappers.sh
```

This standalone script:
- Bypasses bash caching completely
- Generates wrappers with the latest fixed code
- Includes container detection
- Includes robust distrobox path detection

## Test After Running

```bash
# Should show version number
node -v

# Should work inside container too
distrobox enter main-dev
node -v  # Should NOT error with "distrobox: command not found"
exit
```

## What The Fix Does

### Before (Old Wrapper - BROKEN):
```bash
#!/usr/bin/env bash
# Auto-generated wrapper for node

# Create a process group
set -m

# Run in container
"/usr/bin/distrobox" enter -n "main-dev" -- "/usr/bin/node" "$@" &
```

**Problems:**
- Hard-coded distrobox path
- No container detection (fails inside container)
- No fallback if distrobox moves

### After (New Wrapper - FIXED):
```bash
#!/usr/bin/env bash
# Auto-generated wrapper for node

# CRITICAL: Check if already inside container
if [ -n "$CONTAINER_ID" ] && [ "$CONTAINER_ID" = "main-dev" ]; then
    exec "/usr/bin/node" "$@"  # Direct execution!
fi

# Smart distrobox detection with fallbacks
DISTROBOX_CMD=""
if [ -x "/usr/bin/distrobox" ]; then
    DISTROBOX_CMD="/usr/bin/distrobox"
elif command -v distrobox &>/dev/null; then
    DISTROBOX_CMD="distrobox"
# ... more fallbacks ...
fi

# Run in container
"$DISTROBOX_CMD" enter -n "main-dev" -- "/usr/bin/node" "$@" &
```

**Benefits:**
- ✓ Works on host
- ✓ Works inside container (no recursion)
- ✓ Works across different distrobox install locations
- ✓ Clear error messages if distrobox not found

## Still Having Issues?

### Check #1: View the new wrapper
```bash
head -50 ~/.local/bin/node
```

Should see "CRITICAL: Check if already inside container" near the top.

### Check #2: Test with debug output
```bash
bash -x ~/.local/bin/node -v 2>&1 | head -30
```

Look for the container detection check.

### Check #3: Test directly in container
```bash
distrobox enter main-dev -- /usr/bin/node -v
```

Should show: `v24.11.1` (not wrapper error)

### Check #4: Re-run diagnostic
```bash
./diagnose.sh
```

Section 5 should now show the new wrapper code with container detection.

## Why This Happened

1. You ran `./setup.sh` initially
2. Wrappers were created
3. I pushed fixes to `export-tools.sh`
4. You pulled and re-ran `./setup.sh`
5. But bash had cached the old function definitions
6. So new wrappers were created with old code
7. **Solution:** `regenerate-wrappers.sh` forces fresh generation

## Alternative: Fresh Shell Session

If `regenerate-wrappers.sh` doesn't work, try running setup in a completely fresh shell:

```bash
# Close all terminal windows
# Open new terminal
cd ~/bazzite-node-setup
git pull
exec bash -c './setup.sh'
```

The `exec bash -c` ensures no cached functions.
