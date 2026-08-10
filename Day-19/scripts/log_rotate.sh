#!/bin/bash
# Description: Compresses old logs and deletes expired archives

set -euo pipefail

# 1. Validate Arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <log_directory>"
    exit 1
fi

LOG_DIR="$1"

# 2. Verify Directory Exists
if [ ! -d "$LOG_DIR" ]; then
    echo "[ERROR] Log directory '$LOG_DIR' does not exist."
    exit 1
fi

echo "=== Log Rotation Started for: $LOG_DIR ==="

# 3. Count & Compress logs older than 7 days
COMPRESS_COUNT=$(find "$LOG_DIR" -type f -name "*.log" -mtime +7 | wc -l)
if [ "$COMPRESS_COUNT" -gt 0 ]; then
    find "$LOG_DIR" -type f -name "*.log" -mtime +7 -exec gzip {} \;
fi

# 4. Count & Delete compressed logs older than 30 days
DELETE_COUNT=$(find "$LOG_DIR" -type f -name "*.gz" -mtime +30 | wc -l)
if [ "$DELETE_COUNT" -gt 0 ]; then
    find "$LOG_DIR" -type f -name "*.gz" -mtime +30 -exec rm -f {} \;
fi

# 5. Summary Report
echo "[SUCCESS] Compressed $COMPRESS_COUNT file(s) older than 7 days."
echo "[SUCCESS] Deleted $DELETE_COUNT archive(s) older than 30 days."
echo "=== Log Rotation Completed ==="