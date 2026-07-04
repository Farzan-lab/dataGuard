#!/bin/bash
# ================================================
#  DataGuard — Master Pipeline Orchestrator
# ================================================
set -e

# ─── 1. Bootstrap ────────────────────────────────
# Resolve paths relative to this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/utils.sh"


# ─── 2. Initialize run ───────────────────────────
load_config
check_dependencies

RUN_ID=$(get_timestamp)
LOG_FILE="$LOG_DIR/pipeline_${RUN_ID}.log"
START_TIME=$(date +%s)

log_info "================================================"
log_info " DataGuard Pipeline — Run ID: $RUN_ID"
log_info " Version: $VERSION"
log_info "================================================"


# ─── 3. Stage runner ─────────────────────────────
# Runs a single stage script and handles failure
run_stage() {
    local stage_name=$1
    local stage_script=$2

    log_info "--- Stage: $stage_name ---"

    if bash "$stage_script"; then
        log_info "$stage_name completed successfully"
    else
        log_error "$stage_name failed — pipeline aborted"
        exit 1
    fi
}


# ─── 4. Run all stages in order ──────────────────
run_stage "01 ingest"    "$SCRIPT_DIR/01_ingest.sh"
run_stage "02 validate"  "$SCRIPT_DIR/02_validate.sh"
run_stage "03 transform" "$SCRIPT_DIR/03_transform.sh"
run_stage "04 report"    "$SCRIPT_DIR/04_report.sh"
run_stage "05 alert"     "$SCRIPT_DIR/05_alert.sh"


# ─── 5. Final summary ────────────────────────────
END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))

log_info "================================================"
log_info " Pipeline completed in ${DURATION}s"
log_info " Log: $LOG_FILE"
log_info "================================================"