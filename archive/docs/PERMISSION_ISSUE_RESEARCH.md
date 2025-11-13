# pnpm Installation Permission Issue - Research & Solution

## Issue Summary

**Error:**
```
EACCES: permission denied, symlink '../lib/node_modules/corepack/dist/pnpm.js' -> '/usr/bin/pnpm'
```

**Location:** `modules/install-tools.sh:187`

**Impact:** pnpm installation fails during automated setup, preventing users from accessing the pnpm package manager.

---

## Root Cause Analysis

### Problem

When Node.js is installed system-wide via APT (NodeSource repository), it installs to system directories:
- Binaries: `/usr/bin/node`, `/usr/bin/npm`
- Modules: `/usr/lib/node_modules/`

Corepack (bundled with Node.js) attempts to create symlinks in `/usr/bin/` when running `corepack enable`, but `/usr/bin/` requires root permissions to modify.

### Why Previous Solutions Failed

**Attempt 1:** Use Corepack without sudo (commit e990a6c)
- **Assumption:** Corepack wouldn't need sudo
- **Result:** EACCES permission denied error

**Attempt 2:** Add sudo to `corepack enable` (commit 71d58ef)
- **Solution:** `sudo corepack enable`
- **Problem:** In automated flows, sudo might:
  - Prompt for password (breaking automation)
  - Not be configured as passwordless in all distrobox setups
  - Fail silently if sudo isn't properly configured
  - Raise security concerns (modifying system directories)

---

## Recommended Solutions

### ✅ Solution 1: Corepack with User Directory (RECOMMENDED)

**Command:**
```bash
corepack enable --install-directory ~/.local/bin
```

**Why This Is Best:**
- ✅ **No sudo required** - writes to user directory only
- ✅ **Works in all environments** - containers, CI/CD, restricted systems
- ✅ **More secure** - doesn't modify system directories
- ✅ **Already compatible** - setup script already uses `~/.local/bin`
- ✅ **Official Corepack feature** - supported flag since early versions
- ✅ **Automated-flow friendly** - no interactive prompts

**Implementation:**
```bash
install_pnpm() {
    if [ "$INSTALL_NODEJS" != true ]; then
        log "Skipping pnpm installation (not selected)"
        return 0
    fi

    log_step "Installing pnpm..."

    local install_pnpm='
        set -e

        # Check if already installed
        if command -v pnpm &> /dev/null; then
            echo "pnpm already installed"
            pnpm --version
            exit 0
        fi

        # Ensure ~/.local/bin exists
        mkdir -p "$HOME/.local/bin"

        # Use Corepack to enable pnpm (no sudo needed!)
        # Install to user directory to avoid permission issues
        echo "Enabling pnpm via Corepack..."
        corepack enable --install-directory "$HOME/.local/bin"

        # Add to PATH for this session
        export PATH="$HOME/.local/bin:$PATH"

        # Verify pnpm is now available
        pnpm --version
    '

    if distrobox enter "$CONTAINER_NAME" -- bash -c "$install_pnpm" >> "$LOG_FILE" 2>&1; then
        local pnpm_version
        pnpm_version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc "pnpm --version" 2>&1 || echo "unknown")
        log_success "pnpm $pnpm_version installed"
        record_tool_status "pnpm" "success" "$pnpm_version"
        return 0
    else
        log_error "Failed to install pnpm"
        record_tool_status "pnpm" "failed" "N/A" "Installation failed"
        RECOVERY_ACTIONS["pnpm"]="Install manually: curl -fsSL https://get.pnpm.io/install.sh | sh -"
        return 1
    fi
}
```

---

### ✅ Solution 2: Standalone pnpm Installer (FALLBACK)

**Command:**
```bash
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

**Why Use This:**
- ✅ **Automatic fallback** if Corepack fails
- ✅ **Installs to user directory** (`~/.local/share/pnpm`)
- ✅ **No Node.js required** (though we have it)
- ✅ **Official pnpm method**
- ✅ **Version pinning** via `PNPM_VERSION` env var

**Implementation as Fallback:**
```bash
install_pnpm() {
    # ... (same start)

    local install_pnpm='
        set -e

        # Check if already installed
        if command -v pnpm &> /dev/null; then
            echo "pnpm already installed"
            pnpm --version
            exit 0
        fi

        # Ensure ~/.local/bin exists
        mkdir -p "$HOME/.local/bin"

        # PRIMARY METHOD: Corepack with user directory
        echo "Enabling pnpm via Corepack..."
        if corepack enable --install-directory "$HOME/.local/bin" 2>/dev/null; then
            export PATH="$HOME/.local/bin:$PATH"
            if pnpm --version 2>/dev/null; then
                echo "✓ pnpm installed via Corepack"
                exit 0
            fi
        fi

        # FALLBACK: Standalone installer
        echo "Corepack failed, using standalone installer..."
        curl -fsSL https://get.pnpm.io/install.sh | sh -

        # Reload PATH and verify
        export PATH="$HOME/.local/share/pnpm:$PATH"
        pnpm --version
    '

    # ... (same verification)
}
```

---

### ❌ Solution 3: Keep Using Sudo (NOT RECOMMENDED)

**Why NOT to use this:**
- ❌ Requires passwordless sudo configuration
- ❌ May prompt for password in some setups
- ❌ Modifies system directories (security concern)
- ❌ Not guaranteed to work in all distrobox configurations
- ❌ Breaks automation principle

**Only use if:** You want to ensure system-wide availability and have full control over the environment.

---

## Implementation Plan

### Phase 1: Primary Fix
1. Update `modules/install-tools.sh` to use `--install-directory ~/.local/bin`
2. Remove sudo requirement
3. Ensure PATH includes `~/.local/bin` (already configured)
4. Test in fresh container

### Phase 2: Add Fallback
1. Add error handling to detect Corepack failure
2. Implement standalone installer as fallback
3. Log which method succeeded
4. Update recovery actions

### Phase 3: Verification
1. Test on fresh Bazzite system
2. Verify pnpm is accessible from host
3. Confirm wrapper scripts work correctly
4. Document PATH requirements

---

## Testing Commands

### Verify Corepack flag support:
```bash
distrobox enter main-dev -- corepack enable --help
```

### Test installation manually:
```bash
distrobox enter main-dev -- bash -c '
    mkdir -p ~/.local/bin
    corepack enable --install-directory ~/.local/bin
    export PATH="$HOME/.local/bin:$PATH"
    pnpm --version
'
```

### Verify from host:
```bash
pnpm --version
```

---

## References

- [Corepack GitHub Issue #265](https://github.com/nodejs/corepack/issues/265) - Permission denied on Linux
- [Stack Overflow: EACCES permission denied symlink](https://stackoverflow.com/questions/73156323/internal-error-eacces-permission-denied-symlink-lib-node-modules-corepack)
- [pnpm Official Installation Docs](https://pnpm.io/installation)
- [Corepack npm Package](https://www.npmjs.com/package/corepack)

---

## Expected Outcome

After implementing Solution 1:
- ✅ pnpm installs without errors
- ✅ No sudo prompts or permission issues
- ✅ Works in all automated flows
- ✅ Accessible from both container and host
- ✅ Wrapper scripts function correctly
- ✅ No system directory modifications

---

## Summary

**Problem:** Corepack tries to write to `/usr/bin/` which requires root permissions.

**Solution:** Use `corepack enable --install-directory ~/.local/bin` to install to user directory.

**Benefits:** No sudo, works everywhere, more secure, automation-friendly.

**Fallback:** Standalone installer if Corepack fails for any reason.
