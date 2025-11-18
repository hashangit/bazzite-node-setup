#!/usr/bin/env bash
################################################################################
# Debug wrapper execution
################################################################################

set -x  # Enable debug mode

echo "================================"
echo "Testing npm wrapper directly"
echo "================================"
echo ""

echo "Current shell: $SHELL"
echo "Current user: $USER"
echo "Current HOME: $HOME"
echo ""

echo "--- Wrapper content ---"
head -30 ~/.local/bin/npm
echo ""

echo "--- Testing with full path ---"
/var/home/hashan/.local/bin/npm -v
NPM_EXIT=$?
echo "npm exit code: $NPM_EXIT"
echo ""

echo "--- Testing via PATH ---"
npm -v
NPM_EXIT2=$?
echo "npm exit code: $NPM_EXIT2"
echo ""

echo "--- Testing git ---"
/var/home/hashan/.local/bin/git -v
GIT_EXIT=$?
echo "git exit code: $GIT_EXIT"
echo ""

echo "--- Testing gh ---"
/var/home/hashan/.local/bin/gh -v 2>&1
GH_EXIT=$?
echo "gh exit code: $GH_EXIT"
echo ""

echo "--- Comparing working (node) vs broken (npm) ---"
echo "node wrapper:"
ls -la ~/.local/bin/node
echo ""
echo "npm wrapper:"
ls -la ~/.local/bin/npm
echo ""

echo "--- Direct distrobox test ---"
echo "Testing: distrobox enter main-dev -- /usr/bin/npm -v"
distrobox enter main-dev -- /usr/bin/npm -v
echo "Exit code: $?"
