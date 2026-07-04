#!/bin/bash
# ================================================
#  DataGuard — Config Loader
# ================================================

load_config() {

    # ─── 1. Locate project root ───────────────────
    # Resolves the absolute path of the project root
    # regardless of where the script is called from
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    CONFIG_FILE="$PROJECT_ROOT/config/pipeline.conf"

    # ─── 2. Verify config file exists ────────────
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "ERROR: config file not found: $CONFIG_FILE"
        exit 1
    fi

    # ─── 3. Load config into current shell ───────
    # 'source' runs the file in the current shell so
    # all variables become available to the caller
    source "$CONFIG_FILE"

    # ─── 4. Validate required variables ──────────
    # Any missing variable causes an immediate exit
    local required_vars=(
        "INCOMING_DIR"
        "VALID_DIR"
        "QUARANTINE_DIR"
        "PROCESSED_DIR"
        "LOG_DIR"
        "REPORT_DIR"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "ERROR: required variable not set: $var"
            exit 1
        fi
    done

    # ─── 5. Create directories if missing ────────
    # Ensures the pipeline can always write output
    # even on a fresh clone
    mkdir -p "$INCOMING_DIR"
    mkdir -p "$VALID_DIR"
    mkdir -p "$QUARANTINE_DIR"
    mkdir -p "$PROCESSED_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$REPORT_DIR"
}