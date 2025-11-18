#!/usr/bin/env bash
################################################################################
# Force Fix All Wrappers
# Ensures correct code and regenerates all wrappers
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "================================================"
echo " Force Wrapper Fix Tool"
echo "================================================"
echo ""

# 1. Verify we have the correct template in regenerate-wrappers.sh
echo -e "${CYAN}[1] Verifying template code...${NC}"
if grep -q "exec.*DISTROBOX_CMD.*enter" regenerate-wrappers.sh && \
   ! grep -q "CHILD_PID" regenerate-wrappers.sh; then
    echo -e "${GREEN}✓${NC} Template code is correct (uses exec, no backgrounding)"
else
    echo -e "${RED}✗${NC} Template code is WRONG or outdated!"
    echo "Expected: exec with no backgrounding"
    echo "Please run: git pull origin claude/setup-nodejs-dev-01GxUzjsHiksRsfwtETSZB2d"
    exit 1
fi
echo ""

# 2. Remove ALL existing wrappers to ensure clean slate
echo -e "${CYAN}[2] Removing ALL existing wrappers...${NC}"
for tool in node npm npx pnpm bun bunx git gh; do
    if [ -f "$HOME/.local/bin/$tool" ]; then
        rm -f "$HOME/.local/bin/$tool"
        echo "  Removed: $tool"
    fi
done
echo -e "${GREEN}✓${NC} Old wrappers removed"
echo ""

# 3. Regenerate with correct template
echo -e "${CYAN}[3] Regenerating all wrappers...${NC}"
./regenerate-wrappers.sh
echo ""

# 4. Verify all wrappers have correct code
echo -e "${CYAN}[4] Verifying wrapper code...${NC}"
GOOD=0
BAD=0

for tool in node npm npx git gh pnpm; do
    if [ -f "$HOME/.local/bin/$tool" ]; then
        if grep -q "exec.*enter" "$HOME/.local/bin/$tool" && \
           ! grep -q "CHILD_PID" "$HOME/.local/bin/$tool"; then
            echo -e "${GREEN}✓${NC} $tool: correct code (exec, no CHILD_PID)"
            ((GOOD++))
        else
            echo -e "${RED}✗${NC} $tool: WRONG code (has CHILD_PID or no exec)"
            echo "  First 10 lines:"
            head -10 "$HOME/.local/bin/$tool" | sed 's/^/    /'
            ((BAD++))
        fi
    else
        echo -e "${YELLOW}!${NC} $tool: wrapper not found"
    fi
done
echo ""

# 5. Show results
echo "================================================"
if [ $BAD -eq 0 ]; then
    echo -e "${GREEN}✓ All wrappers verified: $GOOD correct${NC}"
    echo ""
    echo "Test the tools:"
    echo "  node -v"
    echo "  npm -v"
    echo "  git -v"
    echo "  gh --version"
    echo "  pnpm -v"
else
    echo -e "${RED}✗ Some wrappers have wrong code: $GOOD correct, $BAD wrong${NC}"
    echo ""
    echo "This indicates the regenerate script has bugs."
    echo "Please share this output with the developer."
fi
echo "================================================"

exit $([ $BAD -eq 0 ] && echo 0 || echo 1)
