#!/usr/bin/env bash

################################################################################
# Comprehensive Test Script for Bazzite Node.js Development Container
#
# This script performs thorough testing of the development environment setup
# to ensure everything is working correctly with no conflicts or issues.
################################################################################

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly CONTAINER_NAME="main-dev"
readonly TEST_DIR="/tmp/bazzite-node-test-$$"
readonly TEST_LOG="test-results.log"

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$TEST_LOG"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$TEST_LOG"
}

separator() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

test_start() {
    ((TESTS_TOTAL++))
    echo -e "\n${BLUE}[TEST $TESTS_TOTAL]${NC} $*" | tee -a "$TEST_LOG"
}

test_pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓ PASS${NC}" | tee -a "$TEST_LOG"
}

test_fail() {
    ((TESTS_FAILED++))
    echo -e "${RED}✗ FAIL${NC}: $*" | tee -a "$TEST_LOG"
}

################################################################################
# Test Functions
################################################################################

test_distrobox_available() {
    test_start "Checking if distrobox is available"

    if command -v distrobox &> /dev/null; then
        log "distrobox is available"
        test_pass
    else
        test_fail "distrobox not found"
    fi
}

test_container_exists() {
    test_start "Checking if container '$CONTAINER_NAME' exists"

    if distrobox list 2>/dev/null | grep -q "^$CONTAINER_NAME"; then
        log "Container '$CONTAINER_NAME' exists"
        test_pass
    else
        test_fail "Container '$CONTAINER_NAME' not found"
    fi
}

test_container_running() {
    test_start "Checking if container can be entered"

    if distrobox enter "$CONTAINER_NAME" -- echo "Container is accessible" &> /dev/null; then
        log "Container is accessible"
        test_pass
    else
        test_fail "Cannot enter container"
    fi
}

test_node_accessible() {
    test_start "Checking if node is accessible from host"

    if command -v node &> /dev/null; then
        local version
        version=$(node --version 2>&1)
        log "node is accessible (version: $version)"
        test_pass
    else
        test_fail "node not found in PATH"
    fi
}

test_npm_accessible() {
    test_start "Checking if npm is accessible from host"

    if command -v npm &> /dev/null; then
        local version
        version=$(npm --version 2>&1)
        log "npm is accessible (version: $version)"
        test_pass
    else
        test_fail "npm not found in PATH"
    fi
}

test_npx_accessible() {
    test_start "Checking if npx is accessible from host"

    if command -v npx &> /dev/null; then
        local version
        version=$(npx --version 2>&1)
        log "npx is accessible (version: $version)"
        test_pass
    else
        test_fail "npx not found in PATH"
    fi
}

test_pnpm_accessible() {
    test_start "Checking if pnpm is accessible from host"

    if command -v pnpm &> /dev/null; then
        local version
        version=$(pnpm --version 2>&1)
        log "pnpm is accessible (version: $version)"
        test_pass
    else
        test_fail "pnpm not found in PATH"
    fi
}

test_bun_accessible() {
    test_start "Checking if bun is accessible from host"

    if command -v bun &> /dev/null; then
        local version
        version=$(bun --version 2>&1)
        log "bun is accessible (version: $version)"
        test_pass
    else
        test_fail "bun not found in PATH"
    fi
}

test_nvm_in_container() {
    test_start "Checking if NVM is installed in container"

    if distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm --version' &> /dev/null; then
        local version
        version=$(distrobox enter "$CONTAINER_NAME" -- bash -lc 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm --version' 2>&1)
        log "NVM is installed in container (version: $version)"
        test_pass
    else
        test_fail "NVM not found in container"
    fi
}

test_node_execution() {
    test_start "Testing Node.js script execution"

    local result
    result=$(node -e "console.log('Hello from Node.js')" 2>&1)

    if [[ "$result" == "Hello from Node.js" ]]; then
        log "Node.js execution works correctly"
        test_pass
    else
        test_fail "Node.js execution failed: $result"
    fi
}

test_npm_package_install() {
    test_start "Testing npm package installation"

    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"

    # Initialize a test project
    npm init -y &> /dev/null

    # Install a small package
    if npm install lodash &> /dev/null; then
        log "npm package installation works"
        test_pass
    else
        test_fail "npm package installation failed"
    fi

    cd - &> /dev/null
}

test_pnpm_package_install() {
    test_start "Testing pnpm package installation"

    mkdir -p "$TEST_DIR/pnpm-test"
    cd "$TEST_DIR/pnpm-test"

    # Initialize a test project
    pnpm init &> /dev/null

    # Install a small package
    if pnpm add lodash &> /dev/null; then
        log "pnpm package installation works"
        test_pass
    else
        test_fail "pnpm package installation failed"
    fi

    cd - &> /dev/null
}

test_bun_package_install() {
    test_start "Testing bun package installation"

    mkdir -p "$TEST_DIR/bun-test"
    cd "$TEST_DIR/bun-test"

    # Initialize a test project
    bun init -y &> /dev/null

    # Install a small package
    if bun add lodash &> /dev/null; then
        log "bun package installation works"
        test_pass
    else
        test_fail "bun package installation failed"
    fi

    cd - &> /dev/null
}

test_path_priority() {
    test_start "Checking PATH priority for exported tools"

    local node_path
    node_path=$(which node 2>&1)

    if [[ "$node_path" == "$HOME/.local/bin/node" ]]; then
        log "Correct PATH priority: $node_path"
        test_pass
    else
        log_warn "Node path is $node_path, expected $HOME/.local/bin/node"
        test_fail "PATH priority may be incorrect"
    fi
}

test_no_version_conflicts() {
    test_start "Checking for version conflicts"

    # Check if multiple node installations exist
    local node_count
    node_count=$(whereis node | tr ' ' '\n' | grep -c "bin/node" || echo "1")

    if [[ "$node_count" -eq 1 ]]; then
        log "No conflicting Node.js installations found"
        test_pass
    else
        log_warn "Multiple Node.js installations may exist"
        log "Node locations: $(whereis node)"
        test_fail "Potential version conflicts detected"
    fi
}

test_home_directory_access() {
    test_start "Checking if container can access host home directory"

    local test_file="$HOME/.bazzite-node-test-$$"
    echo "test" > "$test_file"

    if distrobox enter "$CONTAINER_NAME" -- bash -c "[ -f '$test_file' ]"; then
        log "Container can access host home directory"
        rm -f "$test_file"
        test_pass
    else
        rm -f "$test_file"
        test_fail "Container cannot access host home directory"
    fi
}

test_working_directory_preservation() {
    test_start "Checking if working directory is preserved"

    mkdir -p "$TEST_DIR/wd-test"
    cd "$TEST_DIR/wd-test"

    local pwd_in_container
    pwd_in_container=$(node -e "console.log(process.cwd())" 2>&1)

    if [[ "$pwd_in_container" == "$TEST_DIR/wd-test" ]]; then
        log "Working directory is preserved correctly"
        test_pass
    else
        test_fail "Working directory mismatch: expected $TEST_DIR/wd-test, got $pwd_in_container"
    fi

    cd - &> /dev/null
}

test_environment_variables() {
    test_start "Checking if environment variables are passed"

    export TEST_VAR="bazzite-test-value"

    local result
    result=$(node -e "console.log(process.env.TEST_VAR)" 2>&1)

    if [[ "$result" == "bazzite-test-value" ]]; then
        log "Environment variables are passed correctly"
        test_pass
    else
        test_fail "Environment variables not passed correctly"
    fi

    unset TEST_VAR
}

test_stdin_handling() {
    test_start "Checking if stdin is handled correctly"

    local result
    result=$(echo "test input" | node -e "process.stdin.on('data', d => console.log(d.toString().trim()))" 2>&1)

    if [[ "$result" == "test input" ]]; then
        log "stdin is handled correctly"
        test_pass
    else
        test_fail "stdin handling failed: got '$result'"
    fi
}

test_file_operations() {
    test_start "Testing file operations from container"

    mkdir -p "$TEST_DIR/file-test"
    cd "$TEST_DIR/file-test"

    # Create a file using Node.js
    node -e "require('fs').writeFileSync('test.txt', 'Hello from Node')" 2>&1

    if [[ -f "test.txt" ]] && [[ "$(cat test.txt)" == "Hello from Node" ]]; then
        log "File operations work correctly"
        test_pass
    else
        test_fail "File operations failed"
    fi

    cd - &> /dev/null
}

test_network_access() {
    test_start "Testing network access from container"

    # Try to fetch from npm registry
    local result
    result=$(node -e "
        const https = require('https');
        https.get('https://registry.npmjs.org/lodash/latest', (res) => {
            console.log(res.statusCode);
        }).on('error', (err) => {
            console.error('Error:', err.message);
            process.exit(1);
        });
    " 2>&1)

    if [[ "$result" == "200" ]]; then
        log "Network access works correctly"
        test_pass
    else
        log_warn "Network access may be limited: $result"
        test_fail "Network access issues detected"
    fi
}

test_npx_execution() {
    test_start "Testing npx package execution"

    local result
    result=$(npx --yes cowsay "Test" 2>&1 | grep -c "Test" || echo "0")

    if [[ "$result" -gt 0 ]]; then
        log "npx execution works correctly"
        test_pass
    else
        test_fail "npx execution failed"
    fi
}

test_global_package_install() {
    test_start "Testing global package installation"

    # Install a small global package
    if npm install -g is-online &> /dev/null; then
        log "Global package installation works"

        # Clean up
        npm uninstall -g is-online &> /dev/null

        test_pass
    else
        test_fail "Global package installation failed"
    fi
}

cleanup_tests() {
    log "Cleaning up test files..."
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

################################################################################
# Main Test Execution
################################################################################

main() {
    separator
    echo -e "${GREEN}Bazzite Node.js Development Container - Comprehensive Tests${NC}"
    separator

    # Initialize log
    echo "Test started at $(date)" > "$TEST_LOG"

    # Run all tests
    test_distrobox_available
    test_container_exists
    test_container_running

    test_node_accessible
    test_npm_accessible
    test_npx_accessible
    test_pnpm_accessible
    test_bun_accessible

    test_nvm_in_container
    test_node_execution
    test_path_priority
    test_no_version_conflicts

    test_home_directory_access
    test_working_directory_preservation
    test_environment_variables
    test_stdin_handling

    test_npm_package_install
    test_pnpm_package_install
    test_bun_package_install

    test_file_operations
    test_network_access
    test_npx_execution
    test_global_package_install

    # Cleanup
    cleanup_tests

    # Print summary
    separator
    echo -e "\n${BLUE}Test Summary${NC}"
    separator
    echo -e "Total Tests: ${BLUE}$TESTS_TOTAL${NC}"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    separator

    echo -e "\nDetailed results saved to: ${BLUE}$TEST_LOG${NC}\n"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed! Your setup is production-ready.${NC}\n"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed. Please review the errors above.${NC}\n"
        exit 1
    fi
}

# Run main function
main "$@"
