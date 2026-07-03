#!/bin/bash
set -e

echo "================================================"
echo " DataGuard — Project Setup"
echo "================================================"

# ─── 1. Create folder structure ───────────────────
echo ""
echo "[ 1/5 ] Creating folders..."

mkdir -p config/schema          # main config + schema definitions
mkdir -p data/incoming          # raw input files land here
mkdir -p data/valid             # files that passed all quality checks
mkdir -p data/quarantine        # files that failed validation
mkdir -p data/processed         # final clean output
mkdir -p logs                   # timestamped run logs
mkdir -p reports                # daily HTML summaries
mkdir -p scripts/lib            # shared library scripts

echo "   Folders created successfully."


# ─── 2. Create .gitkeep files ─────────────────────
echo ""
echo "[ 2/5 ] Creating .gitkeep files..."

touch data/incoming/.gitkeep
touch data/valid/.gitkeep
touch data/quarantine/.gitkeep
touch data/processed/.gitkeep
touch logs/.gitkeep
touch reports/.gitkeep

echo "   .gitkeep files created."


# ─── 3. Create .gitignore ─────────────────────────
echo ""
echo "[ 3/5 ] Creating .gitignore..."

cat > .gitignore << 'GITEOF'
# Ignore all data files — never commit real data to the repo
data/incoming/*
data/valid/*
data/quarantine/*
data/processed/*

# Ignore runtime logs and generated reports
logs/*
reports/*

# Keep folder structure tracked via .gitkeep files
!**/.gitkeep
GITEOF

echo "   .gitignore created."


# ─── 4. Create placeholder script files ───────────
echo ""
echo "[ 4/5 ] Creating script files..."

touch config/pipeline.conf
touch config/schema/sales.schema

touch scripts/lib/logger.sh     # logging functions (INFO · WARN · ERROR)
touch scripts/lib/config.sh     # config loader and validator
touch scripts/lib/utils.sh      # shared helper functions

touch scripts/01_ingest.sh      # data ingestion
touch scripts/02_validate.sh    # data quality gate
touch scripts/03_transform.sh   # cleaning and transformation
touch scripts/04_report.sh      # HTML report generation
touch scripts/05_alert.sh       # anomaly detection and alerting
touch scripts/pipeline.sh       # master orchestrator

echo "   Script files created."


# ─── 5. Set permissions and initialize git ────────
echo ""
echo "[ 5/5 ] Setting permissions and initializing git..."

chmod +x scripts/*.sh
chmod +x scripts/lib/*.sh

git init
git add .
git commit -m "chore: initialize DataGuard project structure"

echo ""
echo "================================================"
echo " DataGuard set up successfully!"
echo ""
echo " Next step: fill in config/pipeline.conf"
echo "================================================"