#!/bin/bash

# ==============================================================================
# Script Name: backup.sh
# Description: Automated backup script to backup 90DaysOfDevops Folder
# Usage:       ./backup.sh
# Day:         Day 07 - Linux File System & Scenario Practice
# ==============================================================================

set -euo pipefail

# Configuration / Environment variables

SOURCE_DIR="~/git-repo/90DaysOfDevops"
DEST_DIR="/tmp/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="90DaysOfDevops_Backup_${TIMESTAMP}.tar.gz"
LOG_FILE="/tmp/backup.log"

#Function to write timestamped log entries

log_message() {
	local MSG="$1"
	echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${MSG}" | tee -a "${LOG_FILE}"
}
log_message "Starting Backup process..."

#Step 1: Ensure that Destination directory Exists

if [ ! -d "${DEST_DIR}" ]; then
	log_message "Creating destination directory at ${DEST_DIR}..."
	mkdir -p "${DEST_DIR}"
fi

#Step 2 Create Archive

log_message "Compressing ${SOURCE_DIR} inro ${DEST_DIR}/${BACKUP_NAME}..."
tar -czf "${DEST_DIR}/${BACKUP_NAME}" "${SOURCE_DIR}" 2>/dev/null || true

#Step 3 Verify Archive Creation
if [ -f "${DEST_DIR}/${BACKUP_NAME}" ]; then
	FILE_SIZE=$(du -sh "${DEST_DIR}/${BACKUP_NAME}" | cut -f1)
	log_message "Backup Completed Successfully! File: ${DEST_DIR}/${BACKUP_NAME} (Size: ${FILE_SIZE}) "
else
	log_message "Error: Backup archive creation failed."
	exit 1
fi

#Step 4 Cleanup backup older then 7 days
log_message "Cleaning up old backups (> 7 days) in ${DEST_DIR}...)"
find "${DEST_DIR}" -type f -name "90DaysOfDevops_Backup_*.tar.gz" -mtime +7 -exec rm -f {} \;

log_message "Backup Script Execution Finished"