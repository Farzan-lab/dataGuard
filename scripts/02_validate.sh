#!/bin/bash
# ================================================
#  DataGuard — Stage 02: Validate
# ================================================
set -e

# ─── Bootstrap ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/utils.sh"
load_config

PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMA_FILE="$PROJECT_ROOT/config/schema/sales.schema"

passed=0
failed=0


# ─── Validate a single CSV file ──────────────────
# Runs 6 checks and moves the file to valid/ or
# quarantine/ depending on the result
validate_file() {
    local file=$1
    local filename
    filename=$(basename "$file")
    local errors=""
    local has_error=0


    # ── Check 1: Minimum row count ────────────────
    # Reject files that are too small to be meaningful
    local rows
    rows=$(count_csv_rows "$file")

    if [ "$rows" -lt "$MIN_ROWS" ]; then
        errors="${errors}  - row count too low: $rows (minimum: $MIN_ROWS)\n"
        has_error=1
    fi
    log_info "check 1 row count: $rows row(s)"


    # ── Check 2: Column header match ─────────────
    # Compare file headers against schema definition
    # Schema columns are extracted and joined with commas
    local expected_header
    expected_header=$(grep -v '^#' "$SCHEMA_FILE" | grep -v '^$' \
                      | awk -F'|' '{gsub(/ /,"",$1); printf "%s,",$1}' \
                      | sed 's/,$//')

    local actual_header
    actual_header=$(head -1 "$file" | tr -d '\r')

    if [ "$actual_header" != "$expected_header" ]; then
        errors="${errors}  - header mismatch\n"
        errors="${errors}    expected: $expected_header\n"
        errors="${errors}    actual  : $actual_header\n"
        has_error=1
    fi
    log_info "check 2 headers: ok"


    # ── Check 3: Null/empty field percentage ──────
    # Count empty fields across all data rows
    # Fail if the percentage exceeds MAX_NULL_PCT
    local total_values null_count null_pct
    total_values=$(awk -F',' 'NR>1{count += NF} END{print count+0}' "$file")
    null_count=$(awk -F',' 'NR>1{
        for(i=1;i<=NF;i++) if($i=="") empty++
    } END{print empty+0}' "$file")

    if [ "$total_values" -gt 0 ]; then
        null_pct=$(( null_count * 100 / total_values ))
    else
        null_pct=0
    fi

    if [ "$null_pct" -gt "$MAX_NULL_PCT" ]; then
        errors="${errors}  - null percentage too high: ${null_pct}% (max: ${MAX_NULL_PCT}%)\n"
        has_error=1
    fi
    log_info "check 3 nulls: ${null_pct}%"


    # ── Check 4: Amount column range ─────────────
    # Find the index of the 'amount' column dynamically
    # then flag any row where amount is out of range
    local amount_col bad_amounts
    amount_col=$(head -1 "$file" | tr ',' '\n' | grep -n "^amount$" | cut -d: -f1)

    bad_amounts=$(awk -F',' \
                      -v col="$amount_col" \
                      -v mn="$AMOUNT_MIN" \
                      -v mx="$AMOUNT_MAX" \
                  'NR>1 && $col!="" && ($col+0 < mn || $col+0 > mx) {
                      print "    row "NR": amount="$col
                  }' "$file")

    if [ -n "$bad_amounts" ]; then
        errors="${errors}  - amount out of range [$AMOUNT_MIN - $AMOUNT_MAX]:\n${bad_amounts}\n"
        has_error=1
    fi
    log_info "check 4 amount range: ok"


    # ── Check 5: Date format YYYY-MM-DD ──────────
    # Use regex to validate every value in the date column
    local date_col bad_dates
    date_col=$(head -1 "$file" | tr ',' '\n' | grep -n "^date$" | cut -d: -f1)

    bad_dates=$(awk -F',' -v col="$date_col" \
                'NR>1 && $col!="" && $col !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ {
                    print "    row "NR": date="$col
                }' "$file")

    if [ -n "$bad_dates" ]; then
        errors="${errors}  - invalid date format (expected YYYY-MM-DD):\n${bad_dates}\n"
        has_error=1
    fi
    log_info "check 5 date format: ok"


    # ── Check 6: Duplicate IDs ────────────────────
    # Extract all id values, sort them, and count duplicates
    local id_col dupe_count
    id_col=$(head -1 "$file" | tr ',' '\n' | grep -n "^id$" | cut -d: -f1)

    dupe_count=$(awk -F',' -v col="$id_col" \
                 'NR>1{print $col}' "$file" \
                 | sort | uniq -d | wc -l)

    if [ "$dupe_count" -gt 0 ]; then
        errors="${errors}  - found $dupe_count duplicate ID(s)\n"
        has_error=1
    fi
    log_info "check 6 duplicates: $dupe_count"


    # ── Route file based on validation result ─────
    if [ "$has_error" -eq 0 ]; then
        # All checks passed — move to valid/
        mv "$file" "$VALID_DIR/$filename"
        log_info "PASSED: $filename → $VALID_DIR"
        return 0
    else
        # At least one check failed — quarantine the file
        # and write a human-readable error report alongside it
        mv "$file" "$QUARANTINE_DIR/$filename"

        local report="$QUARANTINE_DIR/${filename%.csv}_errors.txt"
        printf "File    : %s\nChecked : %s\nErrors  :\n%b" \
               "$filename" \
               "$(date '+%Y-%m-%d %H:%M:%S')" \
               "$errors" > "$report"

        log_warn "FAILED: $filename → $QUARANTINE_DIR"
        log_warn "error report: $(basename "$report")"
        return 1
    fi
}


# ─── Main: loop through all staged CSV files ─────
file_count=$(find "$INCOMING_DIR" -maxdepth 1 -name "*.csv" \
             ! -name ".gitkeep" | wc -l)

if [ "$file_count" -eq 0 ]; then
    log_warn "no CSV files found in $INCOMING_DIR — skipping validate"
    exit 0
fi

log_info "validating $file_count file(s)..."

for file in "$INCOMING_DIR"/*.csv; do
    [ -f "$file" ] || continue
    [ "$(basename "$file")" = ".gitkeep" ] && continue

    if validate_file "$file"; then
        passed=$(( passed + 1 ))
    else
        failed=$(( failed + 1 ))
    fi
done


# ─── Summary ─────────────────────────────────────
log_info "validate complete — passed: $passed | failed: $failed"