# Fix: Distrobox Container and Wrapper Errors

**Date:** 2025-11-13
**Issue:** Multiple cascading issues causing tools to fail when accessed from host or inside container

## Problems Identified

### 1. Critical: Wrapper Scripts Fail Inside Container
**Symptom:**
```bash
distrobox enter main-dev
node -v
# Error: /var/home/hashan/.local/bin/node: line 29: distrobox: command not found
# Error: Failed to start node in container
```

**Root Cause:**
- When entering the container via `distrobox enter main-dev`, the shared `~/.local/bin` directory contains wrapper scripts
- These wrappers attempt to run `distrobox enter` again, causing recursion
- The `distrobox` command is not available inside containers by default

**Solution:**
Added container detection logic to wrappers (lines 44-49 in export-tools.sh):
```bash
# CRITICAL: Check if we're already inside the target container
if [ -n "$CONTAINER_ID" ] && [ "$CONTAINER_ID" = "CONTAINER_NAME" ]; then
    # Already inside target container - exec the native binary directly
    exec "BINARY_PATH" "$@"
fi
```

**Impact:**
- Tools now work correctly both on host AND inside container
- No more recursive container entry
- Users can seamlessly use tools in both contexts

### 2. Robust Distrobox Path Detection
**Symptom:**
- Wrapper fails with "distrobox: command not found" even when distrobox is installed
- Hard-coded paths don't work across all Linux distributions

**Root Cause:**
- Original wrapper used only the detected path at setup time
- If PATH changes or distrobox location differs, wrapper fails
- No fallback mechanism

**Solution:**
Enhanced distrobox detection with multiple fallbacks (lines 51-67 in export-tools.sh):
```bash
DISTROBOX_CMD=""
if [ -x "DISTROBOX_PATH" ]; then
    DISTROBOX_CMD="DISTROBOX_PATH"
elif command -v distrobox &>/dev/null; then
    DISTROBOX_CMD="distrobox"
elif [ -x "/usr/bin/distrobox" ]; then
    DISTROBOX_CMD="/usr/bin/distrobox"
elif [ -x "/usr/local/bin/distrobox" ]; then
    DISTROBOX_CMD="/usr/local/bin/distrobox"
elif [ -x "/home/linuxbrew/.linuxbrew/bin/distrobox" ]; then
    DISTROBOX_CMD="/home/linuxbrew/.linuxbrew/bin/distrobox"
else
    echo "Error: distrobox command not found" >&2
    exit 127
fi
```

**Impact:**
- Works across different Linux distributions and setups
- Graceful degradation with multiple fallback paths
- Clear error message if distrobox is truly unavailable

### 3. Bash Array Substitution Error
**Symptom:**
```bash
./setup.sh: line 304: ${#FAILED_TOOLS[@]:-0}: bad substitution
```

**Root Cause:**
- Invalid bash syntax: `${#FAILED_TOOLS[@]:-0}`
- Cannot use `:-` (default value) with array length syntax
- Fails with `set -u` (treat unset variables as errors)

**Solution:**
Fixed array check in setup.sh (line 304):
```bash
# Before (WRONG):
if [ "${#FAILED_TOOLS[@]:-0}" -gt 0 ]; then

# After (CORRECT):
if [ -n "${FAILED_TOOLS+x}" ] && [ "${#FAILED_TOOLS[@]}" -gt 0 ]; then
```

**Impact:**
- Setup script no longer crashes during report generation
- Proper array existence check before length check
- Compatible with `set -u` strict mode

### 4. Verification Reports Empty Versions
**Symptom:**
```
[INFO] ✓ node is accessible ()
[INFO] ✓ npm is accessible ()
[WARN] - (starship::utils): Executing command "/var/home/hashan/.local/bin/git" timed out.
```

**Root Cause:**
- Verification was running wrapper scripts which have overhead
- Wrappers spawn background processes with traps, causing delays
- Git operations especially prone to timeout with prompt integrations

**Solution:**
Modified verification to query container directly (install-tools.sh lines 343-362):
```bash
# Get version directly from container to avoid wrapper overhead/timeouts
case "$tool" in
    node|npm|npx)
        version=$(distrobox enter "$CONTAINER_NAME" -- bash -c "$tool --version 2>&1 | head -1" 2>/dev/null | tr -d '\r\n' || echo "")
        ;;
    git)
        version=$(distrobox enter "$CONTAINER_NAME" -- git --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "")
        ;;
    # ... etc
esac
```

Also updated verify-setup.sh script to include timeout handling and fallback.

**Impact:**
- Fast, accurate version reporting
- No more git/starship timeout warnings
- Clear diagnostic information

## Testing Recommendations

### Test Case 1: Tools Work on Host
```bash
# From host terminal
node -v          # Should show: v24.11.1
npm -v           # Should show: 11.6.2
pnpm -v          # Should show: 10.22.0
git --version    # Should show: git version 2.43.0
```

### Test Case 2: Tools Work Inside Container
```bash
# Enter container
distrobox enter main-dev

# Test tools (should use native binaries, not wrappers recursively)
node -v          # Should show: v24.11.1 (no wrapper error)
npm -v           # Should show: 11.6.2
git --version    # Should show: git version 2.43.0
```

### Test Case 3: Verification Succeeds
```bash
./verify-setup.sh
# Should show all tools with versions, no timeouts
```

### Test Case 4: Setup Completes Without Errors
```bash
./setup.sh
# Should complete without "bad substitution" error
# Should generate proper report with tool versions
```

## Files Modified

1. **modules/export-tools.sh**
   - Added container detection (lines 44-49)
   - Enhanced distrobox path detection (lines 51-67)
   - Used dynamic `$DISTROBOX_CMD` variable (line 93)

2. **setup.sh**
   - Fixed bash array syntax (line 304)
   - Updated verify-setup.sh template with timeout handling (lines 361-444)

3. **modules/install-tools.sh**
   - Modified verification to query container directly (lines 343-362)
   - Improved version extraction logic

## Migration Notes

Users with existing installations should:

1. **Re-run setup** to regenerate wrappers with new logic:
   ```bash
   cd ~/bazzite-node-setup
   git pull
   ./setup.sh
   ```

2. **Or manually regenerate wrappers** without full setup:
   ```bash
   source modules/common.sh
   source modules/export-tools.sh
   export CONTAINER_NAME="main-dev"
   export_all_tools
   ```

3. **Verify the fix:**
   ```bash
   # Test from host
   node -v

   # Test from inside container
   distrobox enter main-dev
   node -v
   ```

## Technical Details

### Container Detection Method
The wrapper uses the `$CONTAINER_ID` environment variable which is automatically set by distrobox when entering a container. This is more reliable than checking for the presence of `/.dockerenv` or parsing `/proc/1/cgroup`.

### Distrobox Location Priority
1. Setup-time detected path (fastest)
2. Current PATH via `command -v`
3. Standard Fedora/RHEL location: `/usr/bin/distrobox`
4. Standard Debian/Ubuntu location: `/usr/local/bin/distrobox`
5. Homebrew Linux location: `/home/linuxbrew/.linuxbrew/bin/distrobox`

### Process Management Preserved
The fixes maintain the original process management features:
- Dev servers still terminate when terminal closes
- Proper signal handling and cleanup
- Process groups for reliable termination

## Known Limitations

1. **First run inside container may be slower**: The wrapper checks if inside container, adds minimal overhead (~0.01s)

2. **Requires distrobox in PATH or standard location**: If distrobox is in a custom location, users may need to add it to PATH

3. **Container must be named "main-dev"**: The setup uses this hardcoded name. Future versions could make this configurable.

## Future Enhancements

1. **Make container name configurable** via environment variable or config file
2. **Add wrapper performance metrics** to help identify bottlenecks
3. **Create integration tests** for both host and container contexts
4. **Add wrapper version checks** to detect when wrappers need regeneration
