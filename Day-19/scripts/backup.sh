#!/bin/bash
# Description: Automated Directory Backup with 14 day Retention

set -euo pipefail
# 1. Validate Argument

if [ $# -ne 2 ]; then
    echo "Usage: $0 <Source Directory> <Backup_Directory>"
    exit 1
fi

SOURCE_DIR="$1"
DESTINATION_DIR="$2"

#2. Verify Sourcce Exists

if [ ! -d "$SOURCE_DIR" ]; then
    echo "[ERROR!] source directory '$SOURCE_DIR' doesn't exists"
    exit 1
fi

#Create Destination If Doesn't Exists

mkdir -p "$DESTINATION_DIR"

#3. Define Archive File Name

TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
ARCHIVE_NAME="Backup-${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${DESTINATION_DIR}/${ARCHIVE_NAME}"

echo "=== Backup Process Started ==="

echo "[INFO] Archiving '$SOURCE_DIR' to '$ARCHIVE_PATH'..."

#4.Create Archive
tar -czf "$ARCHIVE_PATH" -C "$SOURCE_DIR" .

# 5. Verify & Print Size

if [ -f "$ARCHIVE_PATH" ]; then
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    echo "[SUCCESS] Archive created successfully!"
    echo "[INFO] Archive Name: $ARCHIVE_NAME"
    echo "[INFO] Archive Size: $ARCHIVE_SIZE"
else
    echo "[ERROR] Archive creation failed"
    exit 1
fi

# 6. Retention cleanup (Older then 14 days)\
echo "[INFO] cleaning up backups older then 14 days..."
find "$DESTINATION_DIR" -type f -name "backup-*.tar.gz" -mtime +14 -exec rm -f {} \;
echo "=== Backup Process Completed ==="