# 🚀 Day 20 Solution: Log Analyzer and Report Generator

This document outlines the solution for the Day 20 Bash Scripting Challenge. The goal of this challenge was to create a robust system administration script (`log_analyzer.sh`) capable of parsing server logs, extracting critical metrics, and generating daily summary reports while handling file validation and archiving.

---

## 📜 The Bash Script (`log_analyzer.sh`)

Save the following code in a file named `log_analyzer.sh` and make it executable using `chmod +x log_analyzer.sh`.

```bash
#!/bin/bash

# ==============================================================================
# Script Name: log_analyzer.sh
# Description: Analyzes log files, extracts errors/critical events, 
#              generates a report, and optionally archives the processed log.
# ==============================================================================

# ------------------------------------------------------------------------------
# Task 1: Input and Validation
# ------------------------------------------------------------------------------
if [ -z "$1" ]; then
    echo "[ERROR] Usage: $0 <path_to_log_file>"
    exit 1
fi

LOG_FILE="$1"

if [ ! -f "$LOG_FILE" ]; then
    echo "[ERROR] File '$LOG_FILE' does not exist."
    exit 1
fi

# ------------------------------------------------------------------------------
# Set Variables for Reporting
# ------------------------------------------------------------------------------
DATE_STR=$(date +%Y-%m-%d)
REPORT_FILE="log_report_${DATE_STR}.txt"
TOTAL_LINES=$(wc -l < "$LOG_FILE")

echo "Analyzing log file: $LOG_FILE..."

# ------------------------------------------------------------------------------
# Task 2: Error Count
# ------------------------------------------------------------------------------
# Count lines containing 'ERROR' or 'Failed' (case-insensitive)
ERROR_COUNT=$(grep -iE "ERROR|Failed" "$LOG_FILE" | wc -l)
echo "[INFO] Total Error/Failed count: $ERROR_COUNT"

# ------------------------------------------------------------------------------
# Task 3: Critical Events
# ------------------------------------------------------------------------------
# grep -n extracts the line number, sed formats it to "Line X:"
CRITICAL_EVENTS=$(grep -n "CRITICAL" "$LOG_FILE" | sed 's/^\([0-9]*\):/Line \1: /')

echo -e "\n--- Critical Events ---"
if [ -z "$CRITICAL_EVENTS" ]; then
    echo "No critical events found."
else
    echo "$CRITICAL_EVENTS"
fi

# ------------------------------------------------------------------------------
# Task 4: Top Error Messages
# ------------------------------------------------------------------------------
# Extract lines with ERROR, strip the first 3 columns (usually timestamp/log level), 
# count unique occurrences, sort descending, and grab top 5.
TOP_ERRORS=$(grep "ERROR" "$LOG_FILE" | awk '{$1=$2=$3=""; print}' | sort | uniq -c | sort -rn | head -5)

echo -e "\n--- Top 5 Error Messages ---"
if [ -z "$TOP_ERRORS" ]; then
    echo "No errors found."
else
    echo "$TOP_ERRORS"
fi

# ------------------------------------------------------------------------------
# Task 5: Summary Report Generation
# ------------------------------------------------------------------------------
{
    echo "========================================"
    echo "          LOG ANALYSIS REPORT           "
    echo "========================================"
    echo "Date of analysis      : $DATE_STR"
    echo "Log file name         : $(basename "$LOG_FILE")"
    echo "Total lines processed : $TOTAL_LINES"
    echo "Total error count     : $ERROR_COUNT"
    
    echo -e "\n--- Top 5 Error Messages ---"
    if [ -z "$TOP_ERRORS" ]; then
        echo "None"
    else
        echo "$TOP_ERRORS"
    fi
    
    echo -e "\n--- Critical Events ---"
    if [ -z "$CRITICAL_EVENTS" ]; then
        echo "None"
    else
        echo "$CRITICAL_EVENTS"
    fi
} > "$REPORT_FILE"

echo -e "\n[SUCCESS] Summary report generated: $REPORT_FILE"

# ------------------------------------------------------------------------------
# Task 6: Archive Processed Logs (Optional)
# ------------------------------------------------------------------------------
ARCHIVE_DIR="archive"

if [ ! -d "$ARCHIVE_DIR" ]; then
    mkdir "$ARCHIVE_DIR"
fi

mv "$LOG_FILE" "$ARCHIVE_DIR/"
echo "[SUCCESS] Processed log file moved to $ARCHIVE_DIR/$(basename "$LOG_FILE")"

```

---

## 🛠️ Step-by-Step Approach & Explanation

### 1. Input Validation

The script uses standard conditional checks (`-z` to check for empty strings, `-f` to check if a file exists) to ensure the user provides a valid log file path. If validation fails, it triggers an `exit 1` to gracefully stop execution.

### 2. Error Counting (`grep` & `wc`)

To catch both `ERROR` and `Failed` keywords, the script utilizes `grep -iE`.

* `-i` ignores case sensitivity.
* `-E` allows extended regular expressions (the `|` OR operator).
* `wc -l` pipes the output to count the total lines matched.

### 3. Formatting Critical Events

The requirement asked for a specific format: `Line X: <log message>`.

* `grep -n "CRITICAL"` pulls the matching lines prefixed with the line number and a colon (e.g., `84: 2025-07-29...`).
* `sed 's/^\([0-9]*\):/Line \1: /'` uses a regex capture group to replace that initial number and colon with the exact string `Line X: `.

### 4. Extracting Top 5 Errors (`awk`, `sort`, `uniq`)

This pipeline is the core data manipulation step:

* `awk '{$1=$2=$3=""; print}'`: Strips out the timestamp and log-level columns (assuming standard log format) so that identical error *messages* can be grouped together regardless of when they happened.
* `sort | uniq -c`: Sorts the messages alphabetically so `uniq` can count adjacent identical lines.
* `sort -rn`: Re-sorts the output numerically (`-n`) and in reverse/descending order (`-r`) based on the counts.
* `head -5`: Grabs only the top 5 results.

### 5. Report Generation

Instead of echoing individual lines to the file using `>>` multiple times, the script wraps the report block in curly braces `{ ... } > "$REPORT_FILE"`. This captures all output generated inside the block and redirects it to the text file cleanly and efficiently.

### 6. Archiving Process

The script checks if the `archive/` directory exists using `! -d`. If not, it creates it. Finally, it uses `mv` to relocate the analyzed log file, keeping the working directory clean.

---

## 🚀 Execution & Usage

1. Create a dummy log file to test the script:
```bash
cat <<EOF>> sample_log.log
2026-08-11 10:15:23 CRITICAL Disk space below threshold
2026-08-11 10:16:00 ERROR Connection timed out
2026-08-11 10:16:05 ERROR Connection timed out
2026-08-11 10:17:01 Failed to authenticate user
2026-08-11 14:32:01 CRITICAL Database connection lost
2026-08-11 14:35:00 ERROR File not found
EOF

```


2. Run the script:
```bash
./log_analyzer.sh sample_log.log

```

<img width="2940" height="1848" alt="image" src="https://github.com/user-attachments/assets/4eb3dba5-fedd-4d41-91c6-9b15016c83e6" />


3. View the generated report:
```bash
cat log_report_2026-08-11.txt

```
<img width="517" height="260" alt="image" src="https://github.com/user-attachments/assets/b223fa8c-5219-41e6-bd0c-e4bf044ce2e0" />



```
