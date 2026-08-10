# 🐧 Day 19 – Shell Scripting Project: Log Rotation, Backup & Crontab

## Task
Apply everything learned from Days 16–18 in real-world mini projects.

You will:
- Write a log rotation script
- Write a server backup script
- Schedule them with crontab

---

## Expected Output
- A markdown file: `day-19-project.md`
- All scripts you write during the tasks

---

## Challenge Tasks

### Task 1: Log Rotation Script (`log_rotate.sh`)
This script takes a target directory, compresses `.log` files older than 7 days, deletes `.gz` files older than 30 days, and prints a summary report.

**Script Code (`log_rotate.sh`):**
```bash
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

```

**Execution & Output:**

```bash
$ chmod +x log_rotate.sh
$ ./log_rotate.sh /var/log/myapp
=== Log Rotation Started for: /var/log/myapp ===
[SUCCESS] Compressed 14 file(s) older than 7 days.
[SUCCESS] Deleted 3 archive(s) older than 30 days.
=== Log Rotation Completed ===

```

Created old fake log:
```bash
sudo touch -d "40 days ago" /var/log/temp_syslog_dir/fake_old_backup.gz
sudo touch -d "8 days ago" /var/log/temp_syslog_dir/fake_old_log.log
```

<img width="1279" height="811" alt="image" src="https://github.com/user-attachments/assets/c1716756-36d4-4647-a7eb-27ff718a4a47" />

---

### Task 2: Server Backup Script (`backup.sh`)

This script creates a timestamped archive of a source directory, verifies the archive size, and enforces a 14-day retention policy.

**Script Code (`backup.sh`):**

```bash
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

```

**Execution & Output:**

```bash
$ chmod +x backup.sh
$ ./backup.sh /var/www/html /backups/web
=== Backup Process Started ===
[INFO] Archiving '/var/www/html' to '/backups/web/backup-2026-08-10.tar.gz'...
[SUCCESS] Archive created successfully!
[INFO] Archive Name: backup-2026-08-10.tar.gz
[INFO] Archive Size: 45M
[INFO] Cleaning up backups older than 14 days...
=== Backup Process Completed ===

```

<img width="736" height="651" alt="image" src="https://github.com/user-attachments/assets/e3225cb5-1b09-4bff-a49e-30b030adebda" />

---

### Task 3: Crontab Automation

**Current Schedule Verification:**

```bash
crontab -l

```

**Cron Syntax Reference:**

```text
* * * * *  command
│ │ │ │ │
│ │ │ │ └── Day of week (0-7) (Sunday=0 or 7)
│ │ │ └──── Month (1-12)
│ │ └────── Day of month (1-31)
│ └──────── Hour (0-23)
└────────── Minute (0-59)

```

**Challenge Cron Entries:**

1. Run `log_rotate.sh` every day at 2 AM:
```text
0 2 * * * /path/to/log_rotate.sh /var/log/myapp

```


2. Run `backup.sh` every Sunday at 3 AM:
```text
0 3 * * 0 /path/to/backup.sh /var/www/html /backups/web

```


3. Run a health check script every 5 minutes:
```text
*/5 * * * * /path/to/health_check.sh

```
For Testing We have created for every 2 mins.

CRONTAB:

<img width="729" height="367" alt="image" src="https://github.com/user-attachments/assets/ca1547ed-55ef-421a-aadf-5d60571eb579" />

RESULT:

<img width="1466" height="1012" alt="image" src="https://github.com/user-attachments/assets/c567db3f-305e-4de7-a057-bb80e98637e4" />



---

### Task 4: Combine — Scheduled Maintenance Script (`maintenance.sh`)

This wrapper script integrates both tools and logs all output to `/var/log/maintenance.log` using timestamped events.

**Script Code (`maintenance.sh`):**

```bash
#!/bin/bash
# Description: Wrapper script for executing and logging system maintenance routines

set -euo pipefail

LOG_FILE="/var/log/maintenance.log"

# Define Paths
LOG_ROTATE_SCRIPT="/home/user/scripts/log_rotate.sh"
BACKUP_SCRIPT="/home/user/scripts/backup.sh"

APP_LOG_DIR="/var/log/myapp"
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

```

**Optional: Cron Entry for `maintenance.sh` (Daily at 1:00 AM):**

```text
0 1 * * * /bin/bash /home/user/scripts/maintenance.sh

```
<img width="1283" height="835" alt="image" src="https://github.com/user-attachments/assets/c8fff293-7dcd-41e8-9936-878558933e90" />

---

## 💡 What I Learned (3 Key Points)

1. **Automation Safety with `find`:** Using `find` with `-mtime` combined with `-exec` is a powerful way to enforce retention policies without writing complex loops, ensuring disks never fill up with old data.
2. **Wrapper Script Patterns:** Combining multiple smaller, task-specific scripts (like backup and log rotation) into a single `maintenance.sh` script makes cron scheduling much cleaner and centralizes logging logic.
3. **Piping to Standard Utilities:** Using commands like `wc -l` to count output lines from `find`, or `cut -f1` to extract exactly the file size string from `du -h`, is essential for generating clean, automated reporting logs.

```

```
