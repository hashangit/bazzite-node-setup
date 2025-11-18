#!/usr/bin/env bash
################################################################################
# Export Diagnostics Script
# Helps identify why tool exports are failing
################################################################################

set -u

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CONTAINER_NAME="main-dev"

echo "=================================="
echo " Export Failure Diagnostics"
echo "=================================="
echo ""

# 1. Check if distrobox is available and where
echo -e "${CYAN}[1] Checking distrobox availability...${NC}"
if command -v distrobox &>/dev/null; then
    DISTROBOX_PATH=$(command -v distrobox)
    echo -e "${GREEN}✓${NC} distrobox found at: $DISTROBOX_PATH"
else
    echo -e "${RED}✗${NC} distrobox NOT found in PATH"

    # Check common locations
    for path in "/usr/bin/distrobox" "/usr/local/bin/distrobox" "/var/lib/flatpak/exports/bin/distrobox" "$HOME/.local/bin/distrobox"; do
        if [ -x "$path" ]; then
            echo -e "${YELLOW}!${NC} Found at: $path (but not in PATH)"
            DISTROBOX_PATH="$path"
            break
        fi
    done

    if [ -z "${DISTROBOX_PATH:-}" ]; then
        echo -e "${RED}✗${NC} distrobox not found anywhere!"
        echo "Please install distrobox or add it to PATH"
        exit 1
    fi
fi
echo ""

# 2. Check if container exists
echo -e "${CYAN}[2] Checking if container exists...${NC}"
if "$DISTROBOX_PATH" list 2>/dev/null | grep -q "$CONTAINER_NAME"; then
    echo -e "${GREEN}✓${NC} Container '$CONTAINER_NAME' exists"
else
    echo -e "${RED}✗${NC} Container '$CONTAINER_NAME' not found!"
    echo "Available containers:"
    "$DISTROBOX_PATH" list 2>/dev/null || echo "  (none)"
    exit 1
fi
echo ""

# 3. Check if tools are installed in container
echo -e "${CYAN}[3] Checking tools in container...${NC}"
for tool in node npm git gh pnpm; do
    if path=$("$DISTROBOX_PATH" enter "$CONTAINER_NAME" -- which "$tool" 2>/dev/null | tr -d '\r\n'); then
        if [ -n "$path" ]; then
            echo -e "${GREEN}✓${NC} $tool found at: $path"
        else
            echo -e "${RED}✗${NC} $tool not found in container"
        fi
    else
        echo -e "${RED}✗${NC} $tool not found or check failed"
    fi
done
echo ""

# 4. Check ~/.local/bin status
echo -e "${CYAN}[4] Checking ~/.local/bin...${NC}"
if [ -d "$HOME/.local/bin" ]; then
    echo -e "${GREEN}✓${NC} Directory exists: $HOME/.local/bin"
    echo "  Permissions: $(ls -ld "$HOME/.local/bin" | awk '{print $1, $3, $4}')"

    # Check for wrappers
    echo "  Wrappers found:"
    for tool in node npm git gh pnpm bun uv; do
        if [ -f "$HOME/.local/bin/$tool" ]; then
            echo -e "    ${GREEN}✓${NC} $tool $(ls -lh "$HOME/.local/bin/$tool" | awk '{print $1}')"
        else
            echo -e "    ${RED}✗${NC} $tool (not found)"
        fi
    done
else
    echo -e "${RED}✗${NC} Directory does not exist: $HOME/.local/bin"
    echo "  Creating it now..."
    mkdir -p "$HOME/.local/bin" && echo -e "${GREEN}✓${NC} Created successfully"
fi
echo ""

# 5. Check PATH configuration
echo -e "${CYAN}[5] Checking PATH configuration...${NC}"
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo -e "${GREEN}✓${NC} ~/.local/bin is in current PATH"
else
    echo -e "${YELLOW}!${NC} ~/.local/bin is NOT in current PATH"
    echo "  Current PATH: $PATH"
fi
echo ""

# 6. Check shell configuration files
echo -e "${CYAN}[6] Checking shell config files...${NC}"
for config in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$config" ]; then
        if grep -q "\.local/bin" "$config" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $config contains .local/bin in PATH"
        else
            echo -e "${YELLOW}!${NC} $config does NOT contain .local/bin"
        fi
    else
        echo -e "${YELLOW}!${NC} $config does not exist"
    fi
done
echo ""

# 7. Test creating a simple wrapper
echo -e "${CYAN}[7] Testing wrapper creation...${NC}"
TEST_WRAPPER="$HOME/.local/bin/test-wrapper-$$"
if cat > "$TEST_WRAPPER" <<'EOF'
#!/usr/bin/env bash
echo "Test wrapper works!"
EOF
then
    chmod +x "$TEST_WRAPPER"
    if [ -x "$TEST_WRAPPER" ]; then
        if "$TEST_WRAPPER" 2>/dev/null | grep -q "Test wrapper works"; then
            echo -e "${GREEN}✓${NC} Wrapper creation and execution works!"
        else
            echo -e "${YELLOW}!${NC} Wrapper created but execution failed"
        fi
    else
        echo -e "${RED}✗${NC} chmod +x failed or file not executable"
    fi
    rm -f "$TEST_WRAPPER"
else
    echo -e "${RED}✗${NC} Failed to create test wrapper"
    echo "  This indicates a permission or filesystem issue"
fi
echo ""

# 8. Test distrobox enter command
echo -e "${CYAN}[8] Testing distrobox enter...${NC}"
if "$DISTROBOX_PATH" enter "$CONTAINER_NAME" -- echo "Container access works!" 2>/dev/null | grep -q "Container access works"; then
    echo -e "${GREEN}✓${NC} Can execute commands in container"
else
    echo -e "${RED}✗${NC} Cannot execute commands in container"
fi
echo ""

echo "=================================="
echo " Diagnostics Complete"
echo "=================================="
echo ""
echo "Summary of potential issues:"
echo ""

# Provide recommendations
ISSUES_FOUND=0

if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo -e "${YELLOW}➤${NC} ~/.local/bin is not in PATH"
    echo "  Fix: Run 'source ~/.bashrc' or restart terminal"
    ((ISSUES_FOUND++))
fi

WRAPPER_COUNT=$(ls "$HOME/.local/bin"/{node,npm,git,gh,pnpm} 2>/dev/null | wc -l)
if [ "$WRAPPER_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}➤${NC} No wrappers found in ~/.local/bin"
    echo "  Fix: Run './regenerate-wrappers.sh' or './setup.sh'"
    ((ISSUES_FOUND++))
fi

if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo -e "${GREEN}No obvious issues found!${NC}"
    echo "If tools still don't work, check the full setup log."
else
    echo ""
    echo "Found $ISSUES_FOUND potential issue(s) above."
fi

echo ""
