# 🚀 Day 19 Cheat Sheet: Log Rotation, Backups & Cron

---

## 1. 🕒 Crontab (Automated Scheduling)

### Cron Syntax
A cron schedule consists of 5 fields followed by the command to execute.
```text
* * * * *  /path/to/script.sh
│ │ │ │ │
│ │ │ │ └── Day of week (0-7) (Sunday=0 or 7)
│ │ │ └──── Month (1-12)
│ │ └────── Day of month (1-31)
│ └──────── Hour (0-23)
└────────── Minute (0-59)

```

### Common Cron Examples

| Schedule | Cron Expression |
| --- | --- |
| Every minute | `* * * * *` |
| Every 5 minutes | `*/5 * * * *` |
| Every day at 2:00 AM | `0 2 * * *` |
| Every Sunday at 3:00 AM | `0 3 * * 0` |

### Cron Commands & Debugging

* **Edit Crontab:** `sudo crontab -e` (Use `sudo` to run jobs as root).
* **List Cron Jobs:** `crontab -l`
* **Log Cron Output (Crucial for Debugging):**
```bash
*/5 * * * * /path/to/script.sh >> /var/log/cron-script.log 2>&1

```


*(The `2>&1` ensures that both standard output and error messages are captured in the log).*

---

## 2. 🗄️ Archiving & Compression (`tar`)

### Creating a Backup

```bash
tar -czf /backups/archive.tar.gz -C /var/www/html .

```

* **`-c`**: **C**reate a new archive.
* **`-z`**: Compress using g**z**ip (makes it a `.tar.gz`).
* **`-f`**: Output to the specified **f**ile.
* **`-C /path`**: **C**hange to this directory *before* backing up (prevents absolute path nesting).
* **`.`**: Compress everything in the current directory (relies on `-C`).

---

## 3. 🔍 Finding & Managing Old Files (`find`)

The `find` command is the engine behind retention policies and log rotation.

### Syntax Breakdown

```bash
find /path/to/logs -type f -name "*.log" -mtime +7 -exec gzip {} \;

```

* **`-type f`**: Look for **f**iles only (ignore directories).
* **`-name "*.log"`**: Match files ending in `.log`.
* **`-mtime +7`**: Look for files modified strictly **more than** 7 days ago.
* **`-exec ... {} \;`**: Execute a command on every file found. The `{}` acts as a placeholder for the file name.

### Common `find` Operations

| Goal | Command |
| --- | --- |
| **Count old files** | `find /dir -mtime +30 | wc -l` |
| **Delete old backups** | `find /dir -name "*.gz" -mtime +14 -exec rm -f {} \;` |
| **Compress old logs** | `find /dir -name "*.log" -mtime +7 -exec gzip {} \;` |

---

## 4. ⏱️ Date Formatting (Timestamps)

When running scripts frequently (like every 5 minutes), you must include hours, minutes, and seconds in your filename to prevent overwriting.

```bash
# Correct Timestamp: 2026-08-10_14-05-30
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')

# Applying it to a backup file
ARCHIVE_NAME="backup-${TIMESTAMP}.tar.gz"

```

*(⚠️ **Pro-Tip:** Never put a space between the `+` and the quote, or the `date` command will fail with an "extra operand" error).*

---

## 5. 🛡️ Scripting Best Practices

### Input Validation (Guard Clauses)

Always ensure users provide the correct arguments before the script runs.

```bash
if [ $# -lt 2 ]; then
    echo "Usage: $0 <source_dir> <dest_dir>"
    exit 1
fi

```

### Directory Validation

Never assume a directory exists. Check it before running destructive or backup commands.

```bash
if [ ! -d "/var/www/html" ]; then
    echo "Error: Directory does not exist!"
    exit 1
fi

```

### Centralized Logging Function

When building wrapper scripts (like `maintenance.sh`), use a function to standardize your log format.

```bash
log_event() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> /var/log/maintenance.log
}

# Usage:
log_event "Backup process started successfully."

```

---

## 6. 🔄 Preserving Timestamps (Copying Files)

When copying files manually or in a script, standard `cp` overwrites the creation/modification time. Use these flags to retain original dates:

* **Individual Files:** `cp -p source.txt dest/` (Preserves mode, ownership, and timestamps)
* **Whole Directories:** `cp -a /source/ /dest/` (Archive mode: preserves everything and copies recursively)
* **Production Standard:** `rsync -a /source/ /dest/`

```
