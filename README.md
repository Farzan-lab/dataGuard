# DataGuard

**Automated Data Quality & ETL Pipeline — Built in Pure Bash**

> Shell-native pipeline that ingests raw CSV/JSON files, enforces configurable quality rules, quarantines invalid records, transforms clean data, and delivers HTML reports. No dependencies beyond standard Unix tools.

![Shell](https://img.shields.io/badge/Shell-Bash%204.0%2B-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-lightgrey)
![Status](https://img.shields.io/badge/Status-Active-success)

---

## Why DataGuard?

Every data team receives raw files daily — CSV exports from ERP systems, JSON from vendor APIs, FTP drops from suppliers. Before these files touch a database or dashboard, they must pass a quality gate. Tools like Informatica, Talend, and Apache NiFi solve this problem but cost tens of thousands of dollars per year.

DataGuard solves the same problem with shell scripting: a configurable, auditable, zero-dependency pipeline that runs on any Unix server.

---

## How It Works

```
  Data Sources  (CSV · JSON · TSV · API)
        │
        ▼
  01_ingest.sh       ←  fetch · stage · rename with timestamp
        │
        ▼
  02_validate.sh     ←  schema · null check · range · duplicates
       /  \
      ▼    ▼
data/valid/   data/quarantine/   ←  rejected records + error report
      │
      ▼
  03_transform.sh    ←  normalize · enrich · aggregate
        │
     ┌──┴──┐
     ▼     ▼
04_report  05_alert  ←  HTML daily report · anomaly notifications
```

All stages are orchestrated by `pipeline.sh` and scheduled via cron.

---

## Features

- **Config-driven** — change pipeline behaviour by editing `config/pipeline.conf`, no code changes needed
- **Quarantine system** — invalid records never enter the pipeline; they are isolated with a full error report
- **Structured logging** — every stage writes timestamped `[INFO]` / `[WARN]` / `[ERROR]` entries to `logs/`
- **Anomaly detection** — `05_alert.sh` flags when today's metrics deviate from the rolling average
- **HTML reports** — `04_report.sh` generates a stakeholder-ready daily summary
- **Idempotent** — safe to re-run without corrupting data
- **Cron-ready** — one line to schedule daily or hourly execution

---

## Project Structure

```
dataGuard/
├── config/
│   ├── pipeline.conf          # main settings (paths, thresholds, endpoints)
│   └── schema/
│       └── sales.schema       # column definitions, types, constraints
│
├── data/
│   ├── incoming/              # raw files land here
│   ├── valid/                 # passed all quality checks
│   ├── quarantine/            # failed validation — isolated + logged
│   └── processed/             # final clean output
│
├── logs/                      # timestamped run logs per execution
├── reports/                   # daily HTML summaries
│
└── scripts/
    ├── lib/
    │   ├── logger.sh          # logging functions  (INFO · WARN · ERROR)
    │   ├── config.sh          # config loader and validator
    │   └── utils.sh           # shared helper functions
    ├── 01_ingest.sh           # data ingestion
    ├── 02_validate.sh         # data quality gate
    ├── 03_transform.sh        # cleaning and transformation
    ├── 04_report.sh           # HTML report generation
    ├── 05_alert.sh            # anomaly detection and alerting
    └── pipeline.sh            # master orchestrator
```

---

## Requirements

| Tool | Purpose | Install |
|---|---|---|
| Bash 4.0+ | scripting runtime | pre-installed on Linux/macOS |
| awk · sed · grep | data processing | pre-installed |
| jq | JSON parsing | `apt install jq` / `brew install jq` |
| curl | API ingestion | `apt install curl` |
| csvkit | CSV stats (optional) | `pip install csvkit` |

No proprietary software. Runs on any Linux server or macOS machine.

---

## Quick Start

```bash
# 1. clone the repo
git clone https://github.com/your-username/dataGuard.git
cd dataGuard

# 2. edit your settings
nano config/pipeline.conf

# 3. drop a raw file into incoming/
cp your_data.csv data/incoming/

# 4. run the full pipeline
bash scripts/pipeline.sh

# 5. view today's report
open reports/report_$(date +%Y-%m-%d).html
```

---

## Configuration

All pipeline behaviour is controlled by `config/pipeline.conf`:

```bash
# ── Paths ──────────────────────────────────────
INCOMING_DIR="data/incoming"
VALID_DIR="data/valid"
QUARANTINE_DIR="data/quarantine"
PROCESSED_DIR="data/processed"
LOG_DIR="logs"
REPORT_DIR="reports"

# ── Validation thresholds ───────────────────────
MAX_NULL_PCT=5          # fail if >5% of rows have null values
MIN_ROWS=10             # fail if file has fewer than 10 rows
AMOUNT_MIN=0            # reject rows where amount < 0
AMOUNT_MAX=99999999     # reject rows where amount > 99,999,999

# ── Anomaly detection ───────────────────────────
ALERT_DROP_PCT=20       # alert if today's total drops >20% vs rolling avg

# ── Accepted formats ────────────────────────────
ACCEPTED_EXTENSIONS="csv json tsv"
```

---

## Schema Definition

Column rules are defined in `config/schema/sales.schema`:

```
# column_name | type    | required | min | max
id             | integer | yes      | 1   |
city           | string  | yes      |     |
product        | string  | yes      |     |
amount         | number  | yes      | 0   | 99999999
date           | date    | yes      |     |
```

---

## Scheduling with Cron

```bash
# open crontab
crontab -e
```

Add this line to run the pipeline every day at 02:00 AM:

```
0 2 * * * /absolute/path/to/dataGuard/scripts/pipeline.sh >> /absolute/path/to/dataGuard/logs/cron.log 2>&1
```

---

## Skills Demonstrated

| Area | Tools Used |
|---|---|
| Data processing | `awk`, `sed`, `grep`, `cut`, `sort`, `uniq`, `wc` |
| JSON handling | `jq` |
| CSV tooling | `csvkit` — `csvlook`, `csvstat`, `csvgrep` |
| HTTP / APIs | `curl`, `wget` |
| Shell scripting | functions, variables, loops, conditionals, exit codes |
| Scheduling | `cron` |
| Remote operations | `ssh`, `scp`, `sftp` |
| Version control | `git` |

---

## Example Output

```
[2026-06-19 02:00:01] [INFO]  pipeline started
[2026-06-19 02:00:02] [INFO]  01_ingest    — 3 file(s) staged to data/incoming/
[2026-06-19 02:00:04] [INFO]  02_validate  — 1847 rows passed · 3 rows quarantined
[2026-06-19 02:00:04] [WARN]  02_validate  — sales.csv row 47: amount out of range (value: -500)
[2026-06-19 02:00:06] [INFO]  03_transform — normalized 1847 rows → data/processed/
[2026-06-19 02:00:07] [INFO]  04_report    — report saved → reports/report_2026-06-19.html
[2026-06-19 02:00:07] [INFO]  05_alert     — no anomalies detected (total: 38,195,000)
[2026-06-19 02:00:07] [INFO]  pipeline completed in 6s
```

---

## License

MIT — free to use, modify, and distribute.
