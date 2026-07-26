# 🐧 Day 04: Advanced Linux Concepts & Hands-on Practice

Welcome to Day 04 of the **#90DaysOfDevOps** challenge! Today, we dive deeper into essential Linux commands, process management, file permissions, and text processing tools critical for DevOps engineers.

---

## 📑 Command Quick Reference

### 1. System & Hardware Information
| Command | Description | Example Usage |
| :--- | :--- | :--- |
| `uname -a` | Print system architecture and kernel info | `uname -a` |
| `df -h` | Display disk space usage in human-readable format | `df -h` |
| `free -h` | Show total, used, and free memory (RAM) | `free -h` |
| `uptime` | Show how long system has been running and load averages | `uptime` |
| `whoami` | Display current logged-in username | `whoami` |

### 2. Text Processing & Searching
| Command | Description | Example Usage |
| :--- | :--- | :--- |
| `grep` | Search for matching patterns in files | `grep -i "error" app.log` |
| `head` | Output the first part of files (default: 10 lines) | `head -n 20 app.log` |
| `tail` | Output the last part of files | `tail -f app.log` |
| `find` | Search for files in a directory hierarchy | `find /var/log -name "*.log"` |
| `wc` | Count lines, words, and characters in a file | `wc -l app.log` |

### 3. File Permissions & Ownership
| Command | Description | Example Usage |
| :--- | :--- | :--- |
| `chmod` | Change file/directory access permissions | `chmod 755 script.sh` |
| `chown` | Change file owner and group | `chown ubuntu:ubuntu file.txt` |

---

## 🛠️ Advanced Hands-on Tasks

### Task 1: Searching and Filtering Logs
1. Create a dummy log file named `server.log`.
2. Add multiple entries containing status codes (`200 OK`, `404 Not Found`, `500 Internal Server Error`).
3. Extract and display only lines containing `500` or `Error`.
4. Count how many total lines exist in `server.log`.

```bash
# Solution
cat << 'EOF' > server.log
2026-07-26 10:00:01 INFO User logged in
2026-07-26 10:01:15 ERROR Database connection failed 500
2026-07-26 10:02:10 INFO Request processed 200
2026-07-26 10:03:45 WARN Resource not found 404
2026-07-26 10:04:00 ERROR Out of memory 500
EOF

# Search for errors
grep -E "ERROR|500" server.log

# Count total lines
wc -l server.log

```

---

### Task 2: Managing File Permissions

1. Create an executable shell script named `deploy.sh`.
2. Write a simple echo statement inside it: `echo "Deployment started..."`.
3. Check default permissions using `ls -l`.
4. Modify permissions so only the owner can read, write, and execute (`700` or `rwx------`).
5. Execute the script.

```bash
# Solution
echo '#!/bin/bash' > deploy.sh
echo 'echo "Deployment started..."' >> deploy.sh

# View initial permissions
ls -l deploy.sh

# Change permission to owner-only execution
chmod 700 deploy.sh

# Run the script
./deploy.sh

```

---

### Task 3: Process and System Monitoring

1. View all active processes using `ps`.
2. Check real-time resource utilization using `top` or `htop`.
3. Find the Process ID (PID) of a specific service or application using `pgrep` or `ps aux | grep`.

```bash
# View active processes for the current user
ps aux

# Find PID of a running bash process
pgrep bash

# Check system disk and memory status
df -h
free -m

```

---

### Task 4: Input/Output Redirection & Pipes

1. Redirect standard output of a command to a file using `>`.
2. Append output to an existing file using `>>`.
3. Combine commands using the pipe operator (`|`).

```bash
# Save running processes list to a file
ps aux > running_processes.txt

# Append disk usage info to the same file
df -h >> running_processes.txt

# List only the top 5 largest files in /var/log
ls -lhS /var/log | head -n 6

```

---

## 💡 Troubleshooting Cheat Sheet for DevOps

* **File Permission Denied:** Use `ls -l` to check permissions. Update with `chmod +x filename` if trying to execute a script.
* **Disk Space Full:** Run `df -h` to see which mount point is at 100%, then use `du -sh /*` to identify large directories.
* **Live Log Tracking:** Use `tail -f /path/to/logfile` to view logs in real time as events occur.

---
