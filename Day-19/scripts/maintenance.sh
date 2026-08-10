#!/bin/bash
# Description: Wrapper script for executing and logging system maintenance routines

set -euo pipefail

LOG_FILE="/var/log/maintenance.log"

# Define Paths
LOG_ROTATE_SCRIPT="log_rotate.sh"
BACKUP_SCRIPT="backup.sh"

APP_LOG_DIR="/var/log/temp_syslog_dir/"
APP_DATA_DIR="/var/www/html"
BACKUP_DEST="/backups/web"

# Logging Function
log_event() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Ensure log directory exists (if running as root)
touch "$LOG_FILE" || { echo "Permission denied to write to $LOG_FILE"; exit 1; }

log_event "START: Daily Maintenance Routine initiated."

# 1. Execute Log Rotation
log_event "INFO: Executing Log Rotation..."
if bash "$LOG_ROTATE_SCRIPT" "$APP_LOG_DIR" >> "$LOG_FILE" 2>&1; then
    log_event "SUCCESS: Log Rotation completed."
else
    log_event "ERROR: Log Rotation failed."
fi

# 2. Execute System Backup
log_event "INFO: Executing System Backup..."
if bash "$BACKUP_SCRIPT" "$APP_DATA_DIR" "$BACKUP_DEST" >> "$LOG_FILE" 2>&1; then
    log_event "SUCCESS: System Backup completed."
else
    log_event "ERROR: System Backup failed."
fi

log_event "END: Daily Maintenance Routine finished."
