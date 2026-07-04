#!/bin/bash
# ================================================
#  DataGuard — Logger Library
# ================================================

# ANSI Color Codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Default log directory if LOG_DIR is not already set
LOG_DIR="${LOG_DIR:-logs}"

# ─── Internal Helper Function ───────────────────
_log() {
    local level=$1
    local message=$2
    local color=$3
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local formatted="[${timestamp}] [${level}] ${message}"

    # Print to console with color and append to the log file
    echo -e "${color}${formatted}${RESET}" | tee -a "$LOG_DIR/pipeline.log"
}

# ─── Core Logging Functions ─────────────────────
log_info()  { _log "INFO " "$1" "$GREEN";  }
log_warn()  { _log "WARN " "$1" "$YELLOW"; }
log_error() { _log "ERROR" "$1" "$RED";    }