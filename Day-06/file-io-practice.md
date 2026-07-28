# 🐧 Day 6: Linux File Operations & File I/O — Hands-On Practice Guide

Welcome to Day 6 of the `#90DaysOfDevOps` challenge! Today's focus is on mastering **Linux File Operations, I/O Redirection, File Permissions, and Ownership**. As a DevOps engineer, managing files, modifying access rights, and redirecting outputs in shell commands are core daily tasks.

---

## 📋 Table of Contents
1. [Task 1: Creating and Editing Files with CLI Editors](#task-1-creating-and-editing-files-with-cli-editors)
2. [Task 2: Standard Output & Input Redirection (I/O)](#task-2-standard-output--input-redirection-io)
3. [Task 3: Managing File Permissions (`chmod`)](#task-3-managing-file-permissions-chmod)
4. [Task 4: Managing File Ownership (`chown`)](#task-4-managing-file-ownership-chown)
5. [Task 5: Hard Links vs. Soft Links (Symbolic Links)](#task-5-hard-links-vs-soft-links-symbolic-links)
6. [🏆 Challenge Task: Secure Log Directory Setup](#-challenge-task-secure-log-directory-setup)

---

## Task 1: Creating and Editing Files with CLI Editors

**Objective:** Get comfortable working with Linux CLI editors like `nano` and `vim`.

### Instructions:
1. Create a text file named `devops_notes.txt` using `touch`:

```bash
touch devops_notes.txt

```

2. Use `echo` to add an initial header:
```bash
echo "=== DevOps Day 6 Notes ===" > devops_notes.txt

```


3. Open `devops_notes.txt` using `nano` or `vim`:
* **Nano:** `nano devops_notes.txt`
* **Vim:** `vim devops_notes.txt`


4. Add 3 bullet points about Linux commands, save, and exit.
5. Display the file contents in the terminal using `cat`:
```bash
cat devops_notes.txt

```



---

## Task 2: Standard Output & Input Redirection (I/O)

**Objective:** Understand Linux Input/Output Streams:

* Standard Output (`stdout` -> `1`)
* Standard Error (`stderr` -> `2`)
* Append operator (`>>`) vs. Overwrite operator (`>`)

### Instructions:

1. **Overwrite (`>`):** Output system date to `timestamp.txt`:
```bash
date > timestamp.txt
cat timestamp.txt

```


2. **Append (`>>`):** Append system uptime without erasing existing content:
```bash
uptime >> timestamp.txt
cat timestamp.txt

```


3. **Redirect Standard Error (`2>`):** Try running a non-existent command and redirect error messages to `error.log`:
```bash
ls /non_existent_folder 2> error.log
cat error.log

```


4. **Combine `stdout` and `stderr` (`&>`):**
```bash
ls -l /etc/hosts /non_existent_folder &> combined.log
cat combined.log

```



---

## Task 3: Managing File Permissions (`chmod`)

**Objective:** Learn to view and modify file permissions using both **Symbolic Mode** and **Octal/Absolute Mode**.

### Step 1: Check Current Permissions

```bash
ls -l devops_notes.txt
# Example output: -rw-r--r-- 1 user user ...

```

### Step 2: Modify Permissions via Symbolic Mode

1. Add execute (`x`) permission for the owner/user (`u`):
```bash
chmod u+x devops_notes.txt

```


2. Remove read (`r`) and write (`w`) permissions for others (`o`):
```bash
chmod o-rw devops_notes.txt

```



### Step 3: Modify Permissions via Octal Mode

Set the permissions so that:

* **User/Owner:** Read, Write, Execute (`7`)
* **Group:** Read, Execute (`5`)
* **Others:** No permissions (`0`)

```bash
chmod 750 devops_notes.txt
ls -l devops_notes.txt

```

---

## Task 4: Managing File Ownership (`chown`)

**Objective:** Change file owner and group settings using `chown`.

### Instructions:

1. Create a dummy configuration file:
```bash
touch app_config.conf

```


2. Change the file owner to `nobody` (or a secondary user on your system) using `sudo`:
```bash
sudo chown nobody app_config.conf
ls -l app_config.conf

```


3. Change both owner and group simultaneously:
```bash
sudo chown nobody:nogroup app_config.conf  # On Ubuntu/Debian
# OR
sudo chown nobody:nobody app_config.conf   # On RHEL/CentOS

```


4. Revert the file ownership back to your default user:
```bash
sudo chown $USER:$USER app_config.conf

```



---

## Task 5: Hard Links vs. Soft Links (Symbolic Links)

**Objective:** Understand how Linux handles inodes and file references.

### Instructions:

1. **Create a Soft Link (Symlink):**
```bash
ln -s devops_notes.txt softlink_notes.txt
ls -l softlink_notes.txt

```


2. **Create a Hard Link:**
```bash
ln devops_notes.txt hardlink_notes.txt
ls -l devops_notes.txt hardlink_notes.txt

```


3. **Test the difference:**
* Delete the original file: `rm devops_notes.txt`
* Try reading `softlink_notes.txt` (`cat softlink_notes.txt`) — *Notice it fails/breaks.*
* Try reading `hardlink_notes.txt` (`cat hardlink_notes.txt`) — *Notice the content persists!*



---

## 🏆 Challenge Task: Secure Log Directory Setup

Write a single Bash script (`setup_logs.sh`) that performs the following tasks:

1. Creates a directory structure: `/tmp/app_logs/archive`
2. Creates three empty log files inside `/tmp/app_logs`: `access.log`, `error.log`, `system.log`.
3. Sets directory permissions so only the owner can read/write/execute (`700`).
4. Sets log file permissions so the owner can read/write, group can read-only, and others have no access (`640`).
5. Redirects the script's output confirmation to `/tmp/app_logs/setup.log`.

```bash
#!/bin/bash
# Shell script solution to the challenge
mkdir -p /tmp/app_logs/archive
touch /tmp/app_logs/{access.log,error.log,system.log}

chmod 700 /tmp/app_logs
chmod 640 /tmp/app_logs/*.log

echo "Log environment created on $(date)" > /tmp/app_logs/setup.log
echo "Directory and file permissions successfully set."

```

---

## 💡 Quick Reference / Glossary

| Command | Usage Description |
| --- | --- |
| `cat` | Concatenate and display file content |
| `echo` | Print text or direct string output to file |
| `>` | Redirect output (overwrite destination file) |
| `>>` | Redirect output (append to destination file) |
| `2>` | Redirect standard error stream |
| `chmod` | Change file/directory access mode/permissions |
| `chown` | Change file/directory user and group ownership |
| `ln -s` | Create a symbolic/soft link to a file |
