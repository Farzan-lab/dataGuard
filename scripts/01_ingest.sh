#!/bin/bash
# ================================================
#  DataGuard — Stage 01: Ingest
# ================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/utils.sh"
load_config

# ─── 1. Check incoming directory has files ───────
file_count=$(find "$INCOMING_DIR" -maxdepth 1 -type f ! -name ".gitkeep" | wc -l)

if [ "$file_count" -eq 0 ]; then
    log_warn "no files found in $INCOMING_DIR — skipping ingest"
    exit 0
fi

log_info "found $file_count file(s) in $INCOMING_DIR"

# ─── 2. Process each file ────────────────────────
ingested=0
skipped=0
RUN_TS=$(get_timestamp)

for file in "$INCOMING_DIR"/*; do
    [ -f "$file" ] || continue
    [ "$(basename "$file")" = ".gitkeep" ] && continue

    filename=$(basename "$file")
    extension="${filename##*.}"
    name="${filename%.*}"

    log_info "processing: $filename"

    # ─── 3. Check extension is accepted ──────────
    if ! echo "$ACCEPTED_EXTENSIONS" | grep -qw "$extension"; then
        log_warn "unsupported format [$extension]: $filename — skipped"
        skipped=$(( skipped + 1 ))
        continue
    fi

    # ─── 4. Convert JSON to CSV ──────────────────
    if [ "$extension" = "json" ]; then
        log_info "converting JSON to CSV: $filename"
        csv_file="$INCOMING_DIR/${name}.csv"
        jq -r '(.[0] | keys_unsorted) as $keys |
                $keys, (.[] | [.[$keys[]]])
                | @csv' "$file" > "$csv_file"
        rm "$file"
        file="$csv_file"
        extension="csv"
        filename=$(basename "$file")
        name="${filename%.*}"
        log_info "converted to: $(basename "$csv_file")"
    fi

    # ─── 5. Add timestamp to filename ────────────
    new_name="${name}_${RUN_TS}.${extension}"
    mv "$file" "$INCOMING_DIR/$new_name"
    log_info "staged as: $new_name"

    ingested=$(( ingested + 1 ))
done

# ─── 6. Summary ──────────────────────────────────
log_info "ingest complete — ingested: $ingested | skipped: $skipped"