#!/usr/bin/env bash
################################################################################
# DEPRECATED: This script is no longer needed
# setup.sh now properly handles function reloading
#
# Just run: ./setup.sh
################################################################################

echo "⚠️  This script is deprecated."
echo ""
echo "Please run: ./setup.sh instead"
echo ""
echo "setup.sh now properly regenerates wrappers automatically."
exit 1

################################################################################
# Legacy Standalone Wrapper Regeneration Script
# Kept for reference only - DO NOT USE
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="main-dev"

echo "================================================"
echo " Standalone Wrapper Regeneration"
echo "================================================"
echo ""

# Detect distrobox path
DISTROBOX_PATH=""
if command -v distrobox &>/dev/null; then
    DISTROBOX_PATH=$(command -v distrobox)
elif [ -x "/usr/bin/distrobox" ]; then
    DISTROBOX_PATH="/usr/bin/distrobox"
elif [ -x "/usr/local/bin/distrobox" ]; then
    DISTROBOX_PATH="/usr/local/bin/distrobox"
else
    echo "ERROR: distrobox not found!"
    exit 1
fi

echo "✓ Using distrobox at: $DISTROBOX_PATH"
echo "✓ Target container: $CONTAINER_NAME"
echo ""

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Function to create a single wrapper with new fixed code
create_wrapper() {
    local tool_name=$1
    local binary_path=$2

    echo "Creating wrapper for $tool_name..."

    cat > "$HOME/.local/bin/$tool_name" <<'WRAPPER_EOF'
#!/usr/bin/env bash
# Auto-generated wrapper for TOOL_NAME
# Ensures process termination when terminal closes

# CRITICAL: Check if we're already inside the target container
# This prevents recursive container entry and allows wrappers to work inside containers
if [ -n "$CONTAINER_ID" ] && [ "$CONTAINER_ID" = "CONTAINER_NAME" ]; then
    # Already inside target container - exec the native binary directly
    exec "BINARY_PATH" "$@"
fi

# Check if distrobox is available
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
    echo "Please ensure distrobox is installed and in your PATH" >&2
    exit 127
fi

# Create a process group so we can kill all children
set -m

# Track the background process PID
CHILD_PID=""

# Cleanup function to kill process tree
cleanup() {
    if [ -n "$CHILD_PID" ]; then
        # Kill the entire process group
        kill -- -$CHILD_PID 2>/dev/null || true
        # Wait a moment for graceful shutdown
        sleep 0.5
        # Force kill if still alive
        kill -9 -- -$CHILD_PID 2>/dev/null || true
    fi
    exit
}

# Trap all terminal close signals
trap cleanup EXIT TERM INT HUP QUIT

# Run command in container as background process (NOT exec!)
# This preserves the wrapper shell and its trap handlers
"$DISTROBOX_CMD" enter -n "CONTAINER_NAME" -- "BINARY_PATH" "$@" &
CHILD_PID=$!

# Verify process started (wait briefly and check)
sleep 0.1
if ! kill -0 $CHILD_PID 2>/dev/null; then
    echo "Error: Failed to start TOOL_NAME in container" >&2
    exit 1
fi

# Wait for the process to complete
# This blocks but allows traps to work
wait $CHILD_PID
EXIT_CODE=$?

# Clean up and exit with same code
cleanup
exit $EXIT_CODE
WRAPPER_EOF

    # Replace placeholders
    sed -i "s@TOOL_NAME@$tool_name@g" "$HOME/.local/bin/$tool_name"
    sed -i "s@CONTAINER_NAME@$CONTAINER_NAME@g" "$HOME/.local/bin/$tool_name"
    sed -i "s@BINARY_PATH@$binary_path@g" "$HOME/.local/bin/$tool_name"
    sed -i "s@DISTROBOX_PATH@$DISTROBOX_PATH@g" "$HOME/.local/bin/$tool_name"

    chmod +x "$HOME/.local/bin/$tool_name"

    if [ -x "$HOME/.local/bin/$tool_name" ]; then
        echo "  ✓ $tool_name wrapper created"
        return 0
    else
        echo "  ✗ $tool_name wrapper failed"
        return 1
    fi
}

# Get tool paths from container
echo "Detecting tool paths in container..."
NODE_PATH=$($DISTROBOX_PATH enter "$CONTAINER_NAME" -- which node 2>/dev/null | tr -d '\r\n' || echo "")
NPM_PATH=$($DISTROBOX_PATH enter "$CONTAINER_NAME" -- which npm 2>/dev/null | tr -d '\r\n' || echo "")
NPX_PATH=$($DISTROBOX_PATH enter "$CONTAINER_NAME" -- which npx 2>/dev/null | tr -d '\r\n' || echo "")
PNPM_PATH=$($DISTROBOX_PATH enter "$CONTAINER_NAME" -- bash -lc "which pnpm" 2>/dev/null | tr -d '\r\n' || echo "")
BUN_PATH="$HOME/.bun/bin/bun"
BUNX_PATH="$HOME/.bun/bin/bunx"
GIT_PATH=$($DISTROBOX_PATH enter "$CONTAINER_NAME" -- which git 2>/dev/null | tr -d '\r\n' || echo "")
GH_PATH=$($DISTROBOX_PATH enter "$CONTAINER_NAME" -- which gh 2>/dev/null | tr -d '\r\n' || echo "")
UV_PATH="$HOME/.local/bin/uv"

echo ""
echo "Generating wrappers..."
echo ""

SUCCESS=0
FAILED=0

# Create wrappers for each tool
[ -n "$NODE_PATH" ] && create_wrapper "node" "$NODE_PATH" && ((SUCCESS++)) || ((FAILED++))
[ -n "$NPM_PATH" ] && create_wrapper "npm" "$NPM_PATH" && ((SUCCESS++)) || ((FAILED++))
[ -n "$NPX_PATH" ] && create_wrapper "npx" "$NPX_PATH" && ((SUCCESS++)) || ((FAILED++))
[ -n "$PNPM_PATH" ] && create_wrapper "pnpm" "$PNPM_PATH" && ((SUCCESS++)) || ((FAILED++))
$DISTROBOX_PATH enter "$CONTAINER_NAME" -- bash -c "[ -f $BUN_PATH ]" 2>/dev/null && create_wrapper "bun" "$BUN_PATH" && ((SUCCESS++)) || ((FAILED++))
$DISTROBOX_PATH enter "$CONTAINER_NAME" -- bash -c "[ -f $BUNX_PATH ]" 2>/dev/null && create_wrapper "bunx" "$BUNX_PATH" && ((SUCCESS++)) || ((FAILED++))
[ -n "$GIT_PATH" ] && create_wrapper "git" "$GIT_PATH" && ((SUCCESS++)) || ((FAILED++))
[ -n "$GH_PATH" ] && create_wrapper "gh" "$GH_PATH" && ((SUCCESS++)) || ((FAILED++))
$DISTROBOX_PATH enter "$CONTAINER_NAME" -- bash -c "[ -f $UV_PATH ]" 2>/dev/null && create_wrapper "uv" "$UV_PATH" && ((SUCCESS++)) || ((FAILED++))

echo ""
echo "================================================"
echo " Results: $SUCCESS wrappers created, $FAILED failed"
echo "================================================"
echo ""

if [ $SUCCESS -gt 0 ]; then
    echo "Testing a wrapper..."
    if timeout 5 "$HOME/.local/bin/node" -v &>/dev/null; then
        echo "✓ node wrapper works!"
    else
        echo "⚠ node wrapper exists but test failed"
        echo "  Try: bash -x ~/.local/bin/node -v"
    fi
    echo ""
    echo "All wrappers regenerated successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Test: node -v"
    echo "2. Test in container: distrobox enter $CONTAINER_NAME && node -v"
    echo "3. Run full verification: ./verify-setup.sh"
fi

exit 0
