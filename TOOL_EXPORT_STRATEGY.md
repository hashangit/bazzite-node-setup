# Tool Installation Location Analysis

## Where Each Tool Installs

### Node.js Stack
| Tool | Installation Method | Location | Shared? | Needs Wrapper? |
|------|-------------------|----------|---------|----------------|
| **node** | NodeSource apt repository | `/usr/bin/node` | ❌ No (container-only) | ✅ Yes - for host access + process mgmt |
| **npm** | Bundled with Node.js | `/usr/bin/npm` | ❌ No (container-only) | ✅ Yes - for host access + process mgmt |
| **npx** | Bundled with Node.js | `/usr/bin/npx` | ❌ No (container-only) | ✅ Yes - for host access + process mgmt |
| **pnpm** | Corepack OR standalone | `$HOME/.local/share/pnpm/` OR corepack location | ⚠️ Partially | ⚠️ Maybe - depends on install method |
| **bun** | Official installer | `$HOME/.bun/bin/bun` | ✅ Yes (shared $HOME) | ⚠️ Partial - shared but not in host PATH |

### Python
| Tool | Installation Method | Location | Shared? | Needs Wrapper? |
|------|-------------------|----------|---------|----------------|
| **uv** | Official installer | `$HOME/.local/bin/uv` | ✅ Yes (shared $HOME) | ❌ NO - already accessible! |

### Git Tools
| Tool | Installation Method | Location | Shared? | Needs Wrapper? |
|------|-------------------|----------|---------|----------------|
| **git** | Ubuntu apt | `/usr/bin/git` | ❌ No (container-only) | ✅ Yes - for host access only |
| **gh** | GitHub apt repository | `/usr/bin/gh` | ❌ No (container-only) | ✅ Yes - for host access only |

## Key Insights

### UV is UNIQUE
- **Only tool** that installs to `$HOME/.local/bin/` directly
- This is already in host PATH (we configure it in shell setup)
- **Host can run it directly without any wrapper!**
- Creating a wrapper at the same location OVERWRITES the binary

### Other $HOME Tools (bun, pnpm)
- Install to **different $HOME subdirectories** (`$HOME/.bun/bin/`, `$HOME/.local/share/pnpm/`)
- These are NOT in host PATH
- Wrapper provides convenience (adds to PATH via $HOME/.local/bin)
- No path conflict because wrapper location ≠ binary location

### System Tools (node, npm, npx, git, gh)
- Install to `/usr/bin/` (container's system directories)
- NOT shared with host
- Wrapper is REQUIRED for host to access them

## What Actually Needs Wrappers?

### Process Management Wrappers (Complex)
**Purpose**: Ensure dev servers terminate when terminal closes

**Needed for**:
- node ✅
- npm ✅  
- npx ✅
- pnpm ✅
- bun ✅

**Why**: These run long-lived processes (dev servers, build watchers)

### Basic Export Wrappers (Simple)
**Purpose**: Make container binaries accessible on host

**Needed for**:
- git ✅ (in /usr/bin, not shared)
- gh ✅ (in /usr/bin, not shared)

### NO WRAPPER NEEDED
**Why**: Already in shared $HOME/.local/bin which is in host PATH

**List**:
- uv ❌ **Should NOT create wrapper!**

## The Problem with Current Approach

```bash
# Current code for UV:
export_binary_with_wrapper "uv" "$HOME/.local/bin/uv" "$CONTAINER_NAME"
```

**What happens**:
1. UV binary exists at: `$HOME/.local/bin/uv` (inside container)
2. Since $HOME is shared, host can already see it
3. Creating wrapper at: `$HOME/.local/bin/uv` (on host)
4. **Wrapper OVERWRITES the binary** (same file in shared filesystem!)
5. Wrapper tries to call itself → infinite loop

**What SHOULD happen**:
1. UV binary exists at: `$HOME/.local/bin/uv` (container)
2. Since $HOME is shared, host can already see and execute it
3. **Don't create wrapper at all!**
4. Just verify it's accessible and PATH is configured

## Recommended Fix

### For UV (and any future tools in $HOME/.local/bin):
```bash
export_python_tools() {
    # UV is in shared $HOME/.local/bin - already accessible!
    local uv_path="$HOME/.local/bin/uv"
    
    if [ -f "$uv_path" ]; then
        local uv_version
        uv_version=$("$uv_path" --version 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_success "UV $uv_version accessible at $uv_path (shared)"
        record_tool_status "uv" "success" "$uv_version"
        return 0
    fi
    
    log_error "UV not found at $uv_path"
    return 1
}
```

### For git/gh (system binaries, simple wrappers):
```bash
# These need wrappers, but NOT process-aware ones
# They don't run long-lived processes
# Use simple distrobox-export or basic wrapper
```

### For node/npm/etc (system binaries + process management):
```bash
# Keep current process-aware wrappers
# These genuinely need the trap/cleanup logic
```

## Summary

**Only UV has this problem** because it's the only tool that:
1. Installs to `$HOME/.local/bin/` (shared location)
2. Uses the same path we export to

**Other tools** either:
- Install to `/usr/bin` (not shared) → need wrappers for access
- Install to different $HOME subdirs → need wrappers for PATH convenience

**Solution**: Don't wrap UV at all - it's already accessible from host!
