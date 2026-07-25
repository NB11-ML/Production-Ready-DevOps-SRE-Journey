
# Day-07 Here is the exact implementation of `backup.sh` dissected step by step.

### 1. Shebang & Metadata

```bash
#!/bin/bash

```

* **Shebang (`#!/bin/bash`):** Tells the OS kernel to execute this file using the Bash interpreter located at `/bin/bash`.

---

### 2. Enabling Strict Mode

```bash
set -euo pipefail

```

* Ensures script safety, error catching, and pipeline failure detection.

---

### 3. Defining Configuration Variables

```bash
SOURCE_DIR="/etc"
DEST_DIR="/tmp/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="config_backup_${TIMESTAMP}.tar.gz"
LOG_FILE="/tmp/backup.log"

```

* **`SOURCE_DIR="/etc"`:** Target directory to back up (contains critical system configurations).
* **`DEST_DIR="/tmp/backups"`:** Target destination directory for archives.
* **`TIMESTAMP=$(date +"%Y%m%d_%H%M%S")`:** Generates a unique timestamp string (e.g., `20260729_175500`) to prevent overwriting older archives.
* **`BACKUP_NAME`:** Constructs the archive filename using dynamic string interpolation.
* **`LOG_FILE="/tmp/backup.log"`:** Defines log location for output tracking.

---

### 4. Logging Helper Function

```bash
log_message() {
    local MSG="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${MSG}" \vert{} tee -a "${LOG_FILE}"
}

```

* **`local MSG="$1"`:** Captures the first argument passed to `log_message` in a scoped local variable.
* **`tee -a "${LOG_FILE}"`:** Writes output simultaneously to standard output (`stdout` / screen) and appends (`-a`) to the log file.

---

### 5. Step 1: Destination Directory Check

```bash
if [ ! -d "${DEST_DIR}" ]; then
    log_message "Creating destination directory at ${DEST_DIR}..."
    mkdir -p "${DEST_DIR}"
fi

```

* **`[ ! -d "${DEST_DIR}" ]`:** Checks if the destination directory does **not** exist.
* **`mkdir -p`:** Creates the directory structure safely (won't throw an error if it already exists).

---

### 6. Step 2: Creating the Compressed Archive

```bash
log_message "Compressing ${SOURCE_DIR} into ${DEST_DIR}/${BACKUP_NAME}..."
tar -czf "${DEST_DIR}/${BACKUP_NAME}" "${SOURCE_DIR}" 2>/dev/null || true

```

* **`tar -czf`:**
* `-c`: Create a new archive.
* `-z`: Compress the archive using `gzip`.
* `-f`: Specify the filename of the archive.


* **`2>/dev/null`:** Redirects warnings/errors (like files changing while being read) away from stdout.
* **`|| true`:** Prevents `tar` warnings (non-fatal exit codes) from triggering `set -e` prematurely.

---

### 7. Step 3: Archive Verification

```bash
if [ -f "${DEST_DIR}/${BACKUP_NAME}" ]; then
    FILE_SIZE=$(du -sh "${DEST_DIR}/${BACKUP_NAME}" | cut -f1)
    log_message "Backup completed successfully! File: ${DEST_DIR}/${BACKUP_NAME} (Size:${FILE_SIZE})"
else
    log_message "ERROR: Backup archive creation failed."
    exit 1
fi

```

* **`[ -f ... ]`:** Tests if the expected output archive file actually exists on disk.
* **`du -sh ... | cut -f1`:** Measures human-readable file size (`du -sh`) and extracts just the size column using `cut`.

---

### 8. Step 4: Automated Retention & Cleanup

```bash
log_message "Cleaning up old backups (>7 days) in ${DEST_DIR}..."
find "${DEST_DIR}" -type f -name "config_backup_*.tar.gz" -mtime +7 -exec rm -f {} \;

```

* **`find "${DEST_DIR}"`:** Searches inside the backup folder.
* **`-type f`:** Restricts search to files only.
* **`-name "config_backup_*.tar.gz"`:** Filters for matching backup archive naming patterns.
* **`-mtime +7`:** Selects files modified more than 7 days ago.
* **`-exec rm -f {} \;`:** Automatically deletes (`rm -f`) all matched legacy backups.

---

## 🎯 Summary Checklist for Production Shell Scripts

1. Always use `#!/bin/bash` at line 1.
2. Enable `set -euo pipefail` right after the shebang.
3. Quote all variable expansions (e.g., `"${DEST_DIR}"`) to handle paths with spaces safely.
4. Add clear logging with timestamps.
5. Make sure the script is executable via `chmod +x backup.sh`.
"""

file_path = "backup-script-explanation.md"
with open(file_path, "w", encoding="utf-8") as f:
f.write(md_content)

print(f"File created successfully at {file_path}")

```

```text?code_stdout&code_event_index=1
File created successfully at backup-script-explanation.md


```

I've created the detailed explanation file named **`backup-script-explanation.md`** for your workspace !

Below is a step-by-step breakdown explaining **Bash Strict Mode** (`set -euo pipefail`) and dissecting every section of `backup.sh` line by line.

---

# 🛡️ Step-by-Step Breakdown: `set -euo pipefail` (Bash Strict Mode)

By default, Bash is very forgiving: if a command fails or a variable is misspelled, Bash ignores the error and keeps executing the rest of the script. In DevOps automation, this default behavior can lead to accidental data loss or silent failures.

Adding `set -euo pipefail` enforces safety and predictability:

| Option | Flag Name | What It Does | Danger Prevented |
| --- | --- | --- | --- |
| **`set -e`** | **Exit on Error** | Immediately exits the script if any command returns a non-zero exit code (an error). | Prevents running `tar` if `mkdir -p` failed due to lack of write permissions. |
| **`set -u`** | **Unset Variables** | Treats undefined/uninitialized variables as an error and exits immediately. | Prevents typos in variable names (e.g., `rm -rf "$DEST_DR/*"`, where `$DEST_DR` is empty, causing `rm -rf "/*"`). |
| **`set -o pipefail`** | **Pipeline Failures** | Returns a failure exit code if **any** command in a piped chain (`cmd1 | cmd2`) fails, not just the last one. | Prevents silent failures in chains like `cat missing_file.txt | grep "ERROR"`. |

---

# 📝 Line-by-Line Breakdown of `backup.sh`

### 1. Shebang & Strict Mode Initialization

```bash
#!/bin/bash
set -euo pipefail

```

* **Line 1:** Tells the Linux kernel to execute this file using the Bash interpreter located at `/bin/bash`.
* **Line 2:** Activates Bash Strict Mode immediately.

---

### 2. Defining Configuration Variables

```bash
SOURCE_DIR="/etc"
DEST_DIR="/tmp/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="config_backup_${TIMESTAMP}.tar.gz"
LOG_FILE="/tmp/backup.log"

```

* **`SOURCE_DIR="/etc"`:** Target directory containing system configurations.
* **`DEST_DIR="/tmp/backups"`:** Destination path where compressed archives will be saved.
* **`TIMESTAMP=$(date ...)`:** Dynamically generates a timestamp string (e.g., `20260729_175500`) to guarantee unique backup file names.
* **`BACKUP_NAME`:** Assembles the output `.tar.gz` filename.
* **`LOG_FILE`:** Path where script execution logs will be recorded.

---

### 3. Reusable Logging Helper Function

```bash
log_message() {
    local MSG="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${MSG}" | tee -a "${LOG_FILE}"
}

```

* **`local MSG="$1"`:** Stores the message string passed to the function in a scoped variable.
* **`tee -a "${LOG_FILE}"`:** Prints the log message to standard output (terminal screen) and appends (`-a`) it to the log file simultaneously.

---

### 4. Step 1: Destination Directory Verification

```bash
if [ ! -d "${DEST_DIR}" ]; then
    log_message "Creating destination directory at ${DEST_DIR}..."
    mkdir -p "${DEST_DIR}"
fi

```

* **`[ ! -d "${DEST_DIR}" ]`:** Checks if the destination directory does **not** exist.
* **`mkdir -p`:** Creates the folder path safely (prevents throwing an error if the directory already exists).

---

### 5. Step 2: Creating the Compressed Archive

```bash
log_message "Compressing ${SOURCE_DIR} into ${DEST_DIR}/${BACKUP_NAME}..."
tar -czf "${DEST_DIR}/${BACKUP_NAME}" "${SOURCE_DIR}" 2>/dev/null || true

```

* **`tar -czf`:**
* **`-c`**: Create new archive.
* **`-z`**: Compress with `gzip`.
* **`-f`**: Output to the specified filename.


* **`2>/dev/null`:** Suppresses non-fatal warnings (e.g., files changing during read).
* **`|| true`:** Prevents `set -e` from terminating the script if `tar` returns a non-zero exit code due to minor file warnings.

---

### 6. Step 3: Archive Verification

```bash
if [ -f "${DEST_DIR}/${BACKUP_NAME}" ]; then
    FILE_SIZE=$(du -sh "${DEST_DIR}/${BACKUP_NAME}" | cut -f1)
    log_message "Backup completed successfully! File: ${DEST_DIR}/${BACKUP_NAME} (Size: ${FILE_SIZE})"
else
    log_message "ERROR: Backup archive creation failed."
    exit 1
fi

```

* **`[ -f ... ]`:** Verifies that the `.tar.gz` file was created on disk.
* **`du -sh ... | cut -f1`:** Calculates the human-readable file size (`du -sh`) and isolates the size column using `cut`.

---

### 7. Step 4: Automated Maintenance & Retention

```bash
log_message "Cleaning up old backups (>7 days) in ${DEST_DIR}..."
find "${DEST_DIR}" -type f -name "config_backup_*.tar.gz" -mtime +7 -exec rm -f {} \;

```

* **`find "${DEST_DIR}"`:** Searches inside the backup directory.
* **`-type f -name "config_backup_*.tar.gz"`:** Targets matching backup archives.
* **`-mtime +7`:** Filters for files modified more than 7 days ago.
* **`-exec rm -f {} \;`:** Automatically deletes (`rm -f`) all matched old backups to conserve disk space.
