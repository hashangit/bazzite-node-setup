# Troubleshooting Guide

## The Simple Answer

**90% of issues are fixed by:**

```bash
./setup.sh
```

Just run it. It's safe, idempotent, and fixes most problems.

---

## Quick Checks

### Are wrappers working?

```bash
node -v
```

If you see a version number: **✓ Working**
If you see nothing or an error: **✗ Run `./setup.sh` again**

### Did you restart your terminal?

```bash
# Close terminal and open a new one, then:
node -v
```

PATH changes require a new shell session.

### Is distrobox installed?

```bash
which distrobox
```

Should show: `/usr/bin/distrobox` or similar

### Does the container exist?

```bash
distrobox list | grep main-dev
```

Should show the `main-dev` container running

---

## Common Problems

### Problem: "node -v" shows nothing

**Solution:**
```bash
./setup.sh  # Re-run setup
# Then restart terminal
node -v
```

### Problem: "distrobox: command not found" inside container

**Solution:**
```bash
./setup.sh  # Wrappers now have container detection
```

This was a bug in old wrappers. Re-running setup fixes it.

### Problem: Wrappers timeout or hang

**Solution:**
```bash
./setup.sh  # Gets latest wrapper code
```

### Problem: "Bad substitution" error

**Solution:**
```bash
git pull  # Get latest fixes
./setup.sh
```

This was fixed in recent commits.

---

## Diagnostic Tool

For detailed information about your setup:

```bash
./diagnose.sh
```

This checks:
- PATH configuration
- Wrapper file existence
- Distrobox availability
- Container status
- Wrapper content

---

## Manual Checks

### Check wrapper has new code:

```bash
head -50 ~/.local/bin/node
```

Look for: `"CRITICAL: Check if we're already inside the target container"`

If missing: Run `./setup.sh`

### Test wrapper manually:

```bash
bash -x ~/.local/bin/node -v 2>&1 | head -30
```

Shows exactly what the wrapper is doing.

### Test directly in container:

```bash
distrobox enter main-dev -- /usr/bin/node -v
```

Should show version, not error.

---

## Still Stuck?

1. **Run setup again:**
   ```bash
   ./setup.sh
   ```

2. **Check diagnostic:**
   ```bash
   ./diagnose.sh > diag.txt
   cat diag.txt
   ```

3. **Verify container is running:**
   ```bash
   distrobox list
   podman ps -a | grep main-dev
   ```

4. **Try entering container directly:**
   ```bash
   distrobox enter main-dev
   which node
   node -v
   exit
   ```

5. **Read the detailed docs:**
   - FIXES_CONTAINER_ERRORS.md - What was broken
   - QUICK_FIX.md - Specific fixes

---

## Why Does Running setup.sh Again Work?

setup.sh is **idempotent** - it:
- Detects existing container (doesn't recreate)
- Regenerates wrappers with latest code
- Forces fresh function loading (no bash caching)
- Updates shell configuration if needed

It's safe to run multiple times.

---

## Technical Details

### How wrappers work:

1. Check if already inside target container → exec native binary
2. Find distrobox (multiple fallback locations)
3. Run `distrobox enter container -- binary args`
4. Process management (cleanup on exit)

### Container detection:

Wrappers check `$CONTAINER_ID` environment variable to prevent recursion.

### Distrobox path detection:

Tries these in order:
1. Setup-time detected path
2. Current PATH
3. `/usr/bin/distrobox`
4. `/usr/local/bin/distrobox`
5. `/home/linuxbrew/.linuxbrew/bin/distrobox`

---

**Remember: ./setup.sh fixes almost everything**
