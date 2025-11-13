#!/usr/bin/env bash
# Diagnostic script to identify wrapper issues

set -euo pipefail

echo "==================================="
echo "Bazzite Setup Diagnostic Tool"
echo "==================================="
echo ""

# Check 1: PATH includes ~/.local/bin
echo "1. Checking PATH..."
if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "   ✓ ~/.local/bin is in PATH"
else
    echo "   ✗ ~/.local/bin is NOT in PATH"
    echo "   Current PATH: $PATH"
fi
echo ""

# Check 2: Wrapper files exist
echo "2. Checking if wrapper files exist..."
for tool in node npm npx pnpm bun git gh uv; do
    if [ -f "$HOME/.local/bin/$tool" ]; then
        if [ -x "$HOME/.local/bin/$tool" ]; then
            echo "   ✓ $tool exists and is executable"
        else
            echo "   ⚠ $tool exists but is NOT executable"
        fi
    else
        echo "   ✗ $tool does NOT exist"
    fi
done
echo ""

# Check 3: Distrobox availability
echo "3. Checking distrobox availability..."
if command -v distrobox &>/dev/null; then
    distrobox_path=$(command -v distrobox)
    echo "   ✓ distrobox found at: $distrobox_path"
    distrobox --version 2>&1 | head -1 || true
else
    echo "   ✗ distrobox NOT found in PATH"
    echo "   Checking standard locations..."
    for path in /usr/bin/distrobox /usr/local/bin/distrobox /home/linuxbrew/.linuxbrew/bin/distrobox; do
        if [ -x "$path" ]; then
            echo "   ✓ Found at: $path"
        fi
    done
fi
echo ""

# Check 4: Container exists
echo "4. Checking if container exists..."
if distrobox list 2>/dev/null | grep -q "main-dev"; then
    echo "   ✓ Container 'main-dev' exists"
    distrobox list | grep "main-dev" || true
else
    echo "   ✗ Container 'main-dev' NOT found"
    echo "   Available containers:"
    distrobox list 2>/dev/null || echo "   (none)"
fi
echo ""

# Check 5: Examine node wrapper
echo "5. Examining node wrapper content..."
if [ -f "$HOME/.local/bin/node" ]; then
    echo "   First 30 lines of wrapper:"
    head -30 "$HOME/.local/bin/node" | sed 's/^/   | /'
    echo ""
    echo "   Checking for placeholder replacement..."
    if grep -q "TOOL_NAME\|CONTAINER_NAME\|BINARY_PATH\|DISTROBOX_PATH" "$HOME/.local/bin/node"; then
        echo "   ✗ WARNING: Wrapper still contains unreplaced placeholders!"
        grep -n "TOOL_NAME\|CONTAINER_NAME\|BINARY_PATH\|DISTROBOX_PATH" "$HOME/.local/bin/node" | sed 's/^/   | /'
    else
        echo "   ✓ All placeholders appear to be replaced"
    fi
else
    echo "   ✗ Node wrapper not found"
fi
echo ""

# Check 6: Test running wrapper manually
echo "6. Testing node wrapper manually..."
if [ -f "$HOME/.local/bin/node" ]; then
    echo "   Running: bash -x ~/.local/bin/node -v 2>&1 | head -50"
    echo "   Output:"
    timeout 5 bash -x "$HOME/.local/bin/node" -v 2>&1 | head -50 | sed 's/^/   | /' || echo "   (command timed out or failed)"
else
    echo "   ✗ Cannot test - wrapper doesn't exist"
fi
echo ""

# Check 7: Test distrobox enter directly
echo "7. Testing distrobox enter directly..."
echo "   Running: distrobox enter main-dev -- which node"
if timeout 5 distrobox enter main-dev -- which node 2>&1 | head -5; then
    echo "   ✓ Can access node in container"
else
    echo "   ✗ Cannot access container or node not found"
fi
echo ""

echo "==================================="
echo "Diagnostic complete!"
echo "==================================="
echo ""
echo "Please share this output to help diagnose the issue."
