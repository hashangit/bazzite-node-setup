#!/usr/bin/env bash

################################################################################
# Common Functions and Variables
# Shared utilities for all setup modules
################################################################################

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export BOLD='\033[1m'
export NC='\033[0m'

# Configuration
export CONTAINER_NAME="main-dev"
export CONTAINER_IMAGE="ubuntu:24.04"
export NODE_VERSION="lts"
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export LOG_FILE="${SCRIPT_DIR}/setup.log"
export REPORT_FILE="${SCRIPT_DIR}/setup-report.md"

# State tracking
declare -gA TOOL_STATUS
declare -gA TOOL_VERSION
declare -gA TOOL_ERRORS
declare -gA RECOVERY_ACTIONS
declare -ga WARNINGS
declare -ga INSTALLED_TOOLS
declare -ga FAILED_TOOLS

################################################################################
# Logging Functions
################################################################################

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"
    echo "[$timestamp] [INFO] $*" >> "$LOG_FILE"
}

log_warn() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
    echo "[$timestamp] [WARN] $*" >> "$LOG_FILE"
    WARNINGS+=("$*")
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
    echo "[$timestamp] [ERROR] $*" >> "$LOG_FILE"
}

log_success() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$LOG_FILE"
    echo "[$timestamp] [SUCCESS] $*" >> "$LOG_FILE"
}

log_step() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $*"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo "" >> "$LOG_FILE"
    echo "============================================================" >> "$LOG_FILE"
    echo "STEP: $*" >> "$LOG_FILE"
    echo "============================================================" >> "$LOG_FILE"
}

separator() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

################################################################################
# Utility Functions
################################################################################

record_tool_status() {
    local tool=$1
    local status=$2
    local version=${3:-"N/A"}
    local error=${4:-""}

    TOOL_STATUS["$tool"]=$status
    TOOL_VERSION["$tool"]=$version

    if [ -n "$error" ]; then
        TOOL_ERRORS["$tool"]=$error
    fi

    if [ "$status" == "success" ]; then
        INSTALLED_TOOLS+=("$tool")
    elif [ "$status" == "failed" ]; then
        FAILED_TOOLS+=("$tool")
    fi
}

try_with_retry() {
    local max_attempts=3
    local attempt=1
    local cmd="$1"
    local description="$2"

    while [ $attempt -le $max_attempts ]; do
        log "Attempt $attempt/$max_attempts: $description"

        if eval "$cmd" >> "$LOG_FILE" 2>&1; then
            log_success "$description - succeeded"
            return 0
        fi

        log_warn "$description - failed (attempt $attempt/$max_attempts)"
        attempt=$((attempt + 1))

        if [ $attempt -le $max_attempts ]; then
            local wait_time=$((2 ** (attempt - 1)))
            log "Waiting ${wait_time}s before retry..."
            sleep $wait_time
        fi
    done

    log_error "$description - failed after $max_attempts attempts"
    return 1
}

progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))

    printf "\r${CYAN}Progress: [${NC}"
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "${CYAN}] ${percentage}%%${NC}"

    if [ $current -eq $total ]; then
        echo ""
    fi
}

# Export functions for use in other modules
export -f log log_warn log_error log_success log_step separator
export -f record_tool_status try_with_retry progress_bar
