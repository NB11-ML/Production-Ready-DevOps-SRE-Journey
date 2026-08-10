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
#ARCHIVE_DIR="archive"

#if [ ! -d "$ARCHIVE_DIR" ]; then
#    mkdir "$ARCHIVE_DIR"
#fi

#mv "$LOG_FILE" "$ARCHIVE_DIR/"
#echo "[SUCCESS] Processed log file moved to $ARCHIVE_DIR/$(basename "$LOG_FILE")"