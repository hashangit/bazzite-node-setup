# Root Cause Analysis: UV Wrapper Hang

## The Problem Chain

### 1. UV Installation Location
- UV installer: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Installs to: `$HOME/.local/bin/uv` (INSIDE container)

### 2. Wrapper Creation
- Code creates wrapper: `cat > "$HOME/.local/bin/$tool_name"`  
- Creates at: `$HOME/.local/bin/uv` (on HOST)

### 3. The Critical Issue: Shared $HOME
- In distrobox, `$HOME` is BIND-MOUNTED and SHARED between host and container
- When we create `$HOME/.local/bin/uv` on host, it OVERWRITES the file in container
- The actual UV binary is DESTROYED and replaced with the wrapper script

### 4. The Infinite Loop
When line 321 runs: `distrobox enter "$CONTAINER_NAME" -- "$uv_path" --version`

Step by step:
1. `$uv_path` = `$HOME/.local/bin/uv`
2. distrobox enters container
3. Runs `$HOME/.local/bin/uv --version`
4. This executes the WRAPPER (because we overwrote the binary)
5. Wrapper checks: `if [ -n "$CONTAINER_ID" ] && [ "$CONTAINER_ID" = "main-dev" ]`
6. Inside container, CONTAINER_ID="main-dev" (set by distrobox)
7. Wrapper executes: `exec "$HOME/.local/bin/uv" "$@"`
8. This execs THE WRAPPER ITSELF
9. Wrapper starts again → step 5 → INFINITE EXEC LOOP

### 5. Why It Appears to Hang
- The process keeps exec'ing itself in an infinite loop
- No output, no progress, just CPU spinning
- The command never completes

## Why Other Tools Don't Have This Issue

### Node.js tools (node, npm, npx)
- Install to: `/usr/bin/` (system location)
- Wrapper at: `$HOME/.local/bin/`
- DIFFERENT PATHS → No conflict ✓

### pnpm  
- Install to: `$HOME/.local/share/pnpm/` (NOT .local/bin)
- Wrapper at: `$HOME/.local/bin/pnpm`
- DIFFERENT PATHS → No conflict ✓

### bun
- Install to: `$HOME/.bun/bin/bun`
- Wrapper at: `$HOME/.local/bin/bun`
- DIFFERENT PATHS → No conflict ✓

### git, gh
- Install to: `/usr/bin/` (system location)
- Wrapper at: `$HOME/.local/bin/`
- DIFFERENT PATHS → No conflict ✓

### UV (PROBLEM)
- Install to: `$HOME/.local/bin/uv`
- Wrapper at: `$HOME/.local/bin/uv`
- SAME PATH + SHARED $HOME → OVERWRITES BINARY → INFINITE LOOP ✗

## Additional Cascading Issues

### Issue 1: No timeout on version check
- Line 321: No timeout wrapper
- If it hangs, it hangs forever
- Should use `timeout 5` command

### Issue 2: No protection against overwriting
- No check if wrapper would overwrite actual binary
- No backup of original binary before creating wrapper
- No detection of path conflicts

### Issue 3: Same wrapper logic for all tools
- Template assumes binary and wrapper are at different paths
- Works for system binaries, fails for user-local binaries
- Need different strategy for $HOME-installed tools

## The Fix Strategy

### Option 1: Move UV binary before wrapping
```bash
# Before creating wrapper:
if [[ "$binary_path" == "$HOME"* ]]; then
    # Binary is in $HOME, need to move it to avoid overwrite
    mkdir -p "$HOME/.local/bin/.real"
    mv "$HOME/.local/bin/uv" "$HOME/.local/bin/.real/uv"
    binary_path="$HOME/.local/bin/.real/uv"
fi
# Then create wrapper at $HOME/.local/bin/uv pointing to .real/uv
```

### Option 2: Install UV to different location
```bash
# Modify UV installation to use custom location
export UV_INSTALL_DIR="$HOME/.local/lib/uv"
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Option 3: Use symlinks instead of wrappers for user-local binaries
```bash
# For binaries in $HOME, use distrobox-export instead
distrobox-export --bin "$binary_path" --export-path "$HOME/.local/bin"
```

## Recommended Fix: Option 1 with safeguards
1. Detect if binary_path is in $HOME
2. Create `.real` subdirectory for actual binaries
3. Move binary to `.real` before creating wrapper
4. Update wrapper BINARY_PATH to point to `.real` location
5. Add timeout to all version checks
6. Add error handling for path conflicts

