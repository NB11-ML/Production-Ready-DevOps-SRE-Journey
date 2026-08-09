# Day 18 – Shell Scripting: Functions, System Monitoring & Automated Backups

## Task
Level up your production scripting skills by writing modular functions, monitoring system metrics, parsing log files, and automating tasks using Crontab.

---

## Expected Output
- A markdown file: `01-Day-18-scripting.md`
- All scripts created during the challenge tasks

---

## Challenge Tasks

### Task 1: Reusable Functions (`functions.sh`)
1. Create `functions.sh` that defines modular functions:
   - `log_message()`: Takes a level and message, printing it with a timestamp `[YYYY-MM-DD HH:MM:SS]`.
   - `check_service()`: Takes a service name as an argument and checks its active status.
2. Call both functions in the main execution block.

**Script Code (`functions.sh`):**
```bash
#!/bin/bash
# Description: Demonstrate reusable functions and timestamped logging in Bash

log_message() {
    local LEVEL="$1"
    local MSG="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$LEVEL] $MSG"
}

check_service() {
    local SERVICE="$1"
    log_message "INFO" "Checking status for service: $SERVICE"
    
    if systemctl is-active --quiet "$SERVICE"; then
        log_message "SUCCESS" "Service '$SERVICE' is running."
        return 0
    else
        log_message "WARNING" "Service '$SERVICE' is NOT running."
        return 1
    fi
}

# Main Execution Block
log_message "INFO" "Script execution started."
check_service "sshd"
check_service "nginx" || log_message "ERROR" "Nginx needs attention!"
log_message "INFO" "Script execution completed."

```

**Execution & Output:**

```bash
$ chmod +x functions.sh
$ ./functions.sh
[2026-08-09 16:30:00] [INFO] Script execution started.
[2026-08-09 16:30:00] [INFO] Checking status for service: sshd
[2026-08-09 16:30:00] [SUCCESS] Service 'sshd' is running.
[2026-08-09 16:30:00] [INFO] Checking status for service: nginx
[2026-08-09 16:30:00] [SUCCESS] Service 'nginx' is running.
[2026-08-09 16:30:00] [INFO] Script execution completed.

```

**Detailed Code Explanation:**

* **`local` Keyword:** Declaring variables with `local LEVEL="$1"` ensures variables stay inside the function scope, preventing accidental overwrites of global script variables.
* **`systemctl is-active --quiet`:** Checks if a service is actively running. The `--quiet` flag suppresses output so the script can handle custom logging cleanly.
* **Return Codes (`return 0` vs `return 1`):** Returning `0` signals success to Bash, whereas `1` signals failure. This allows the use of logical OR (`||`) operators like `check_service "nginx" || log_message "ERROR" ...`.

---

### Task 2: System Health Monitor (`monitor_system.sh`)

1. Create `monitor_system.sh` that:
* Extracts current **Disk Usage (%)** on root `/`.
* Extracts current **Memory Usage (%)**.
* Compares metrics against a predefined safety threshold (e.g., `80%`).
* Prints an `[ALERT]` if usage exceeds the limit, otherwise prints `[OK]`.



**Script Code (`monitor_system.sh`):**

```bash
#!/bin/bash
# Description: Monitor Disk and Memory thresholds and trigger alerts

THRESHOLD=80

echo "=== System Health Metrics Check ==="

# 1. Check Disk Usage on Root Partition
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
echo "Current Disk Usage: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
    echo "[ALERT] Disk usage exceeded threshold of ${THRESHOLD}%!"
else
    echo "[OK] Disk usage is within safe limits."
fi

# 2. Check Memory Usage Percentage
MEM_USAGE=$(free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}')
echo "Current Memory Usage: ${MEM_USAGE}%"

if [ "$MEM_USAGE" -gt "$THRESHOLD" ]; then
    echo "[ALERT] Memory usage exceeded threshold of ${THRESHOLD}%!"
else
    echo "[OK] Memory usage is within safe limits."
fi

```

**Execution & Output:**

```bash
$ chmod +x monitor_system.sh
$ ./monitor_system.sh
=== System Health Metrics Check ===
Current Disk Usage: 34%
[OK] Disk usage is within safe limits.
Current Memory Usage: 42%
[OK] Memory usage is within safe limits.

```

**Detailed Code Explanation:**

* **`df -h / | awk 'NR==2 {print $5}' | tr -d '%'`**:
* `df -h /`: Displays disk filesystem statistics for root `/`.
* `awk 'NR==2 {print $5}'`: Selects the 2nd line (`NR==2`) and extracts the 5th column (`Use%`).
* `tr -d '%'`: Strips the `%` character so Bash can evaluate it as a raw integer.


* **`free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}'`**:
* `free`: Displays total, used, and free system memory.
* `awk '/Mem:/ ...'`: Searches for the memory row, divides used memory (`$3`) by total memory (`$2`), multiplies by 100, and rounds to a whole integer (`%.0f`).


* **`[ "$DISK_USAGE" -gt "$THRESHOLD" ]`**: Evaluates whether current utilization is strictly greater than the integer threshold limit.

---

### Task 3: Log Parser (`log_parser.sh`)

1. Create `log_parser.sh` that:
* Accepts a log file path as `$1` (defaults to `/var/log/nginx/access.log`).
* Counts total log entries.
* Parses and lists the top 5 IP addresses hitting the server.
* Counts occurrences of `404 Not Found` HTTP status codes.



**Script Code (`log_parser.sh`):**

```bash
#!/bin/bash
# Description: Parse web access logs for client IP frequency and HTTP 404 errors

LOG_FILE="${1:-/var/log/nginx/access.log}"

# Check if file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' does not exist."
    exit 1
fi

echo "=== Log Analysis Report for: $LOG_FILE ==="
echo "Total Request Count: $(wc -l < "$LOG_FILE")"

echo "-----------------------------------"
echo "Top 5 Client IP Addresses:"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 5

echo "-----------------------------------"
echo "Total 404 Not Found Errors:"
grep -c ' 404 ' "$LOG_FILE" || echo "0"

```

**Execution & Output:**

```bash
$ chmod +x log_parser.sh
$ ./log_parser.sh /var/log/nginx/access.log
=== Log Analysis Report for: /var/log/nginx/access.log ===
Total Request Count: 1420
-----------------------------------
Top 5 Client IP Addresses:
    450 192.168.1.105
    310 10.0.0.12
    180 172.16.0.4
     95 192.168.1.200
     40 127.0.0.1
-----------------------------------
Total 404 Not Found Errors:
12

```

**Detailed Code Explanation:**

* **`${1:-/var/log/nginx/access.log}`**: Parameter expansion trick. If positional parameter `$1` is passed by the user, it uses `$1`; otherwise, it falls back to `/var/log/nginx/access.log`.
* **Pipeline Breakdown (`awk '{print $1}' | sort | uniq -c | sort -nr | head -n 5`)**:
* `awk '{print $1}'`: Extracts column 1 (client IP address in standard web access logs).
* `sort`: Sorts IP addresses sequentially (required before `uniq`).
* `uniq -c`: Filters duplicate consecutive lines and prepends each line with its frequency count.
* `sort -nr`: Sorts the aggregated list **n**umerically in **r**everse order (highest traffic first).
* `head -n 5`: Limits output to the top 5 IP addresses.


* **`grep -c ' 404 '`**: The `-c` flag counts matching lines containing spaces around `404` to prevent false positives with timestamps or file sizes containing 404.

---

### Task 4: Automated Backup Script (`backup.sh`)

1. Create `backup.sh` that:
* Takes a **source directory** (`$1`) and a **backup destination directory** (`$2`).
* Generates a timestamped tarball archive (`backup_YYYY-MM-DD_HHMMSS.tar.gz`).
* Implements retention logic to delete backup archives older than **7 days**.



**Script Code (`backup.sh`):**

```bash
#!/bin/bash
# Description: Compress target directory and enforce 7-day retention policy

SRC_DIR="$1"
DEST_DIR="$2"

# 1. Validate Command Line Arguments
if [ -z "$SRC_DIR" ] || [ -z "$DEST_DIR" ]; then
    echo "Usage: $0 <source_directory> <backup_destination>"
    exit 1
fi

# 2. Verify Source Directory Existence
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: Source directory '$SRC_DIR' does not exist."
    exit 1
fi

# Create Destination Directory if missing
mkdir -p "$DEST_DIR"

# 3. Generate Timestamped Archive Name
TIMESTAMP=$(date +'%Y-%m-%d_%H%M%S')
BACKUP_FILE="$DEST_DIR/backup_$TIMESTAMP.tar.gz"

echo "[INFO] Creating backup of '$SRC_DIR' at '$BACKUP_FILE'..."
tar -czf "$BACKUP_FILE" -C "$SRC_DIR" .

if [ $? -eq 0 ]; then
    echo "[SUCCESS] Backup completed successfully."
else
    echo "[ERROR] Backup process failed!"
    exit 1
fi

# 4. Enforce 7-Day Retention Cleanup
echo "[INFO] Cleaning up backups older than 7 days..."
find "$DEST_DIR" -type f -name "backup_*.tar.gz" -mtime +7 -exec rm -f {} \;
echo "[SUCCESS] Retention cleanup completed."

```

**Execution & Output:**

```bash
$ chmod +x backup.sh
$ ./backup.sh /var/www/html /var/backups/www
[INFO] Creating backup of '/var/www/html' at '/var/backups/www/backup_2026-08-09_163000.tar.gz'...
[SUCCESS] Backup completed successfully.
[INFO] Cleaning up backups older than 7 days...
[SUCCESS] Retention cleanup completed.

```

**Detailed Code Explanation:**

* **`tar -czf "$BACKUP_FILE" -C "$SRC_DIR" .`**:
* `-c`: **C**reate a new archive.
* `-z`: Compress using **g**zip compression.
* `-f`: Specify the output **f**ilename (`$BACKUP_FILE`).
* `-C "$SRC_DIR" .`: Changes directory to `$SRC_DIR` before archiving, ensuring clean relative pathing inside the tarball without absolute directory trees.


* **`find "$DEST_DIR" -type f -name "backup_*.tar.gz" -mtime +7 -exec rm -f {} \;`**:
* `find "$DEST_DIR"`: Scans specified backup directory.
* `-type f`: Restricts search strictly to files.
* `-name "backup_*.tar.gz"`: Matches generated backup filename pattern.
* `-mtime +7`: Filters files modified **more than 7 days ago**.
* `-exec rm -f {} \;`: Executes removal (`rm -f`) for every matching file found.



---

### Task 5: Cron Job Automation

1. Schedule `backup.sh` to execute automatically every day at **2:00 AM**.
2. Save log outputs to `/var/log/cron_backup.log`.

**Configuration Procedure:**
Open the user crontab configuration editor:

```bash
crontab -e

```

Add the following schedule entry at the end of the file:

```text
0 2 * * * /bin/bash /home/user/scripts/backup.sh /var/www/html /var/backups/www >> /var/log/cron_backup.log 2>&1

```

**Verify Active Cron Jobs:**

```bash
$ crontab -l
0 2 * * * /bin/bash /home/user/scripts/backup.sh /var/www/html /var/backups/www >> /var/log/cron_backup.log 2>&1

```

**Detailed Code Explanation:**

* **Cron Timing Syntax (`0 2 * * *`)**:
* `0`: Minute 0.
* `2`: Hour 2 (2:00 AM in 24-hour time).
* `*`: Every day of the month.
* `*`: Every month.
* `*`: Every day of the week.


* **Full Paths Requirement**: Cron runs in a minimal background shell environment without standard user `$PATH` definitions. Specifying full paths (`/bin/bash`, `/home/user/scripts/backup.sh`) prevents command-not-found errors.
* **`>> /var/log/cron_backup.log 2>&1`**: Redirects standard output (`stdout`) and standard error (`stderr`) into a persistent log file for auditing.

---

## Key Learnings

1. **Modular Script Architecture:**
Wrapping logic into functions with scoped variables (`local`) improves script clarity, reduces code duplication, and simplifies debugging.
2. **System Diagnostic Pipelines:**
Chaining tools like `df`, `free`, `awk`, `grep`, and `uniq` allows extracting precise real-time system metrics and log analytics.
3. **Automated Maintenance & Retention:**
Combining archiving (`tar`), expiration cleanup (`find -mtime`), and Crontab scheduling establishes self-maintaining systems that preserve disk capacity.

---

## Hints Reference

* Function syntax: `my_func() { local VAR="$1"; ... }`
* AWK column printing: `awk '{print $1}'`
* Tar compression: `tar -czf archive.tar.gz -C /path .`
* Find expired files: `find /path -type f -mtime +7 -exec rm -f {} \;`
* Daily 2 AM Cron: `0 2 * * * /path/to/script.sh`

---

## Submission Workflow

```bash
# Prepare directory structure
mkdir -p Day-18/Documentation Day-18/Scripts

# Move scripts and markdown files into corresponding folders
mv *.sh Day-18/Scripts/
mv *.md Day-18/Documentation/

# Ensure executable permissions
chmod +x Day-18/Scripts/*.sh

# Commit and push to repository
git add Day-18/
git commit -m "Add Day 18 Shell Scripting: Functions, System Monitoring & Automated Backups"
git push origin main

```

---
