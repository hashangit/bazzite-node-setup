#!/usr/bin/env bash
################################################################################
# Standalone Wrapper Regeneration Script
#
# This script regenerates tool wrappers without re-running full setup.
# Useful for fixing export issues after updates.
#
# Usage: ./regenerate-wrappers.sh
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="main-dev"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "================================================"
echo " Wrapper Regeneration Tool"
echo "================================================"
echo ""
echo "This will regenerate wrappers for all installed tools"
echo "in your $CONTAINER_NAME container."
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

# Cleanup function to kill process tree (for signals only)
cleanup() {
    if [ -n "$CHILD_PID" ]; then
        # Only kill if process is still running
        if kill -0 $CHILD_PID 2>/dev/null; then
            # Kill the entire process group
            kill -- -$CHILD_PID 2>/dev/null || true
            # Wait a moment for graceful shutdown
            sleep 0.5
            # Force kill if still alive
            kill -9 -- -$CHILD_PID 2>/dev/null || true
        fi
    fi
}

# Trap signals to cleanup on abnormal termination
# Do NOT trap EXIT - we handle exit normally below
trap cleanup TERM INT HUP QUIT

# Run command in container as background process (NOT exec!)
# This preserves the wrapper shell and its trap handlers
"$DISTROBOX_CMD" enter -n "CONTAINER_NAME" -- "BINARY_PATH" "$@" &
CHILD_PID=$!

# Wait for the process to complete
# This blocks but allows traps to work
wait $CHILD_PID
EXIT_CODE=$?

# Exit with the same code as the container command
# Do NOT call cleanup here - the process has already finished naturally
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
# IMPORTANT: Use explicit paths to avoid finding wrappers in ~/.local/bin
echo "Detecting tool paths in container..."

# NodeSource installs to /usr/bin
NODE_PATH="/usr/bin/node"
NPM_PATH="/usr/bin/npm"
NPX_PATH="/usr/bin/npx"

# pnpm standalone installer location
PNPM_PATH="$HOME/.local/share/pnpm/pnpm"

# Bun installer location
BUN_PATH="$HOME/.bun/bin/bun"
BUNX_PATH="$HOME/.bun/bin/bunx"

# System tools
GIT_PATH="/usr/bin/git"
GH_PATH="/usr/bin/gh"

# UV location (shared between host and container)
UV_PATH="$HOME/.local/bin/uv"

# Verify paths exist in container
echo "Verifying binary paths..."
for tool_name in NODE_PATH NPM_PATH NPX_PATH GIT_PATH GH_PATH; do
    tool_path="${!tool_name}"
    if ! $DISTROBOX_PATH enter "$CONTAINER_NAME" -- test -x "$tool_path" 2>/dev/null; then
        echo "  Warning: $tool_name ($tool_path) not found"
        eval "$tool_name=''"
    else
        echo "  ✓ $tool_name: $tool_path"
    fi
done

# Check pnpm (user directory)
if ! $DISTROBOX_PATH enter "$CONTAINER_NAME" -- test -x "$PNPM_PATH" 2>/dev/null; then
    echo "  Warning: pnpm not found at $PNPM_PATH"
    PNPM_PATH=""
else
    echo "  ✓ pnpm: $PNPM_PATH"
fi

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
if [ $FAILED -eq 0 ]; then
    echo -e " ${GREEN}✓ Results: $SUCCESS wrappers created successfully${NC}"
else
    echo -e " ${YELLOW}⚠ Results: $SUCCESS created, $FAILED failed${NC}"
fi
echo "================================================"
echo ""

if [ $SUCCESS -gt 0 ]; then
    echo "Testing wrappers..."

    # Test node if available
    if [ -x "$HOME/.local/bin/node" ]; then
        if timeout 5 "$HOME/.local/bin/node" -v &>/dev/null; then
            echo -e "${GREEN}✓${NC} node wrapper works!"
        else
            echo -e "${YELLOW}⚠${NC} node wrapper exists but test timed out"
            echo "  This might be normal on first run. Try: node -v"
        fi
    fi

    echo ""
    echo -e "${GREEN}Wrappers regenerated!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.bashrc"
    echo "2. Test tools from host: node -v, npm -v, git -v, gh -v"
    echo "3. Test tools in container: distrobox enter $CONTAINER_NAME"
    echo "4. Run full verification: ./verify-setup.sh"
    echo ""
    echo -e "${YELLOW}Note:${NC} If pnpm hangs, enter the container and run:"
    echo "   distrobox enter $CONTAINER_NAME"
    echo "   pnpm --version  # to test it directly"
else
    echo -e "${RED}No wrappers were created!${NC}"
    echo ""
    echo "Possible issues:"
    echo "1. Container '$CONTAINER_NAME' doesn't exist or isn't running"
    echo "2. Tools aren't installed in the container"
    echo ""
    echo "Try running: ./setup.sh"
fi

exit 0
