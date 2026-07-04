#!/bin/bash
# ================================================
#  DataGuard — Utility Functions
# ================================================


# ─── 1. Check required tools are installed ───────
check_dependencies() {
    local tools=("awk" "sed" "grep" "jq" "curl")

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            echo "ERROR: required tool not installed: $tool"
            exit 1
        fi
    done

    echo "INFO: all dependencies satisfied"
}


# ─── 2. Return a filesystem-safe timestamp ───────
get_timestamp() {
    date '+%Y-%m-%d_%H-%M-%S'
}


# ─── 3. Count data rows in a CSV (excluding header)
count_csv_rows() {
    local file=$1

    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi

    echo $(( $(wc -l < "$file") - 1 ))
}