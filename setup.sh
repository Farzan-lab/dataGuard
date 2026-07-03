#!/bin/bash
set -e

echo "================================================"
echo " DataGuard — Project Setup"
echo "================================================"

# ─── ۱. ساخت پوشه‌ها ──────────────────────────────
echo ""
echo "[ 1/5 ] creating folders..."

mkdir -p config/schema          # تنظیمات
mkdir -p data/incoming           # schema فایل‌های
mkdir -p logs           # فایل‌های خام ورودی
mkdir -p reports           # فایل‌های تأییدشده
mkdir -p scripts/lib           # فایل‌های رد شده
mkdir -p data/quarantine           # فایل‌های نهایی
mkdir -p data/valid           # لاگ‌ها
mkdir -p data/processed           # گزارش‌ها

echo " Files and folders created successfully."


# ─── ۲. فایل‌های .gitkeep ──────────────────────────
echo ""
echo "[ 2/5 ] creating .gitkeep files..."

touch data/incoming/.gitkeep
touch data/valid/.gitkeep
touch data/quarantine/.gitkeep
touch data/processed/.gitkeep
touch logs/.gitkeep
touch reports/.gitkeep

echo "   .gitkeep files created."

# ─── ۳. نوشتن .gitignore ───────────────────────────
echo ""
echo "[ 3/5 ] creating .gitignore..."

cat > .gitignore << 'GITEOF'
data/incoming/*
data/valid/*
data/quarantine/*
data/processed/*
logs/*
reports/*
!**/.gitkeep
GITEOF
 
echo "   .gitignore created."


# ─── ۴. فایل‌های placeholder اسکریپت‌ها ────────────
echo ""
echo "[ 4/5 ] creating script files..."

touch config/pipeline.conf
touch config/schema/sales.schema

touch scripts/lib/logger.sh
touch scripts/lib/config.sh
touch scripts/lib/utils.sh

touch scripts/01_ingest.sh
touch scripts/02_validate.sh
touch scripts/03_transform.sh
touch scripts/04_report.sh
touch scripts/05_alert.sh
touch scripts/pipeline.sh

echo "   Script files created."


# ─── ۵. chmod + git ────────────────────────────────
echo ""
echo "[ 5/5 ] setting permissions and initializing git..."

chmod +x scripts/0*.sh
chmod +x scripts/lib/*.sh

git init
git add .
git commit -m "chore: initialize DataGuard project structure"

echo ""
echo "================================================"
echo " DataGuard runs successfully!"
echo ""
echo "================================================"