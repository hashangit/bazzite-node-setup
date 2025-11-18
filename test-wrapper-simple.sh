#!/usr/bin/env bash
################################################################################
# Simple Wrapper Test
# Tests if a single wrapper works and shows detailed debug output
################################################################################

set -x  # Enable debug output

echo "================================================"
echo " Testing node wrapper"
echo "================================================"
echo ""

# Check if wrapper exists
if [ ! -f "$HOME/.local/bin/node" ]; then
    echo "ERROR: Wrapper does not exist at $HOME/.local/bin/node"
    exit 1
fi

echo "Wrapper exists. Content:"
cat "$HOME/.local/bin/node"
echo ""
echo "================================================"
echo ""

# Check if executable
if [ ! -x "$HOME/.local/bin/node" ]; then
    echo "ERROR: Wrapper is not executable"
    ls -l "$HOME/.local/bin/node"
    exit 1
fi

echo "Wrapper is executable"
echo ""

# Check PATH
echo "Current PATH:"
echo "$PATH" | tr ':' '\n' | nl
echo ""

# Check if ~/.local/bin is in PATH
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo "✓ ~/.local/bin is in PATH"
else
    echo "✗ ~/.local/bin is NOT in PATH"
    echo "Adding it temporarily..."
    export PATH="$HOME/.local/bin:$PATH"
fi
echo ""

# Try to run wrapper with full path
echo "Testing with full path..."
"$HOME/.local/bin/node" --version
echo "Exit code: $?"
echo ""

# Try to run via PATH
echo "Testing via PATH (which node)..."
which node
echo ""

echo "Running: node --version"
node --version
echo "Exit code: $?"
echo ""

echo "Test complete!"
