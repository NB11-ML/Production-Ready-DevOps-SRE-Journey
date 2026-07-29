# :penguin: 📂 Day 07 – Linux File System Hierarchy & Scenario-Based Practice

## Part 1: Linux File System Hierarchy

### 1. Core Directories (Must Know)

* **`/` (root)**
* **Description:** Starting point of the entire Linux directory tree.
* **`ls -l` snippet:** `drwxr-xr-x 115 root root 12288 Jul 29 09:15 etc`
* **Usage:** *"I would use this when navigating from the base of the system to access any sub-folder or absolute path."*


* **`/home`**
* **Description:** Holds user home directories and user-specific configurations.
* **`ls -l` snippet:** `drwxr-xr-x 5 devops devops 4096 Jul 28 14:22 devops`
* **Usage:** *"I would use this when managing non-root user data, SSH keys (`~/.ssh`), or user-specific application configs."*


* **`/root`**
* **Description:** Home directory for the root administrator user.
* **`ls -l` snippet:** `-rw------- 1 root root 1240 Jul 29 07:30 .bash_history`
* **Usage:** *"I would use this when logged in as root to store root-specific deployment scripts, secrets, or temporary administrative files."*


* **`/etc`**
* **Description:** Stores system-wide application configurations and settings files.
* **`ls -l` snippet:** `-rw-r--r-- 1 root root 12 Jul 29 03:40 hostname`
* **Usage:** *"I would use this when modifying system configurations, such as editing Nginx block configs, SSH server settings, or network hostname configurations."*


* **`/var/log`**
* **Description:** Houses system and application runtime log files.
* **`ls -l` snippet:** `-rw-r--r-- 1 root root 1048576 Jul 29 10:00 syslog`
* **Usage:** *"I would use this when investigating service failure root causes, application errors, security audits, or disk space issues due to growing log files."*


* **`/tmp`**
* **Description:** Temporary files created by system applications (often wiped on reboot).
* **`ls -l` snippet:** `srwxrwxrwx 1 mysql mysql 0 Jul 29 08:00 mysql.sock`
* **Usage:** *"I would use this when writing short-lived execution scripts, caching temporary file transformations, or inspecting lock files."*



### 2. Additional Directories (Good to Know)

* **`/bin`**: Essential binaries/commands (`ls`, `cp`, `bash`).
* **`/usr/bin`**: Non-essential binaries used by regular users (`git`, `curl`, `python3`).
* **`/opt`**: Third-party/optional standalone software (`datadog-agent`, `containerd`).

### 3. Hands-on Commands

```bash
# Find 5 largest log files/directories in /var/log
du -sh /var/log/* 2>/dev/null | sort -h | tail -5

# Check hostname config file in /etc
cat /etc/hostname

# View user home directory permissions and files
ls -la ~

```

---

## Part 2: Scenario-Based Practice

### Solved Example: Check Service Status

```bash
systemctl status nginx            # Check if active, failed, or stopped
systemctl list-units --type=service # List all available systemd services
systemctl is-enabled nginx        # Check if set to auto-start on boot

```

---

### Scenario 1: Service Not Starting (`myapp`)

* **Step 1:** `systemctl status myapp`
* **Why:** Checks status, exit code, process state, and recent execution logs.


* **Step 2:** `journalctl -u myapp -n 50 --no-pager`
* **Why:** Fetches the last 50 lines of logs from journald to inspect stack traces or failure causes.


* **Step 3:** `systemctl is-enabled myapp`
* **Why:** Verifies if the service was configured to auto-start upon boot.


* **Step 4:** `journalctl -b -u myapp`
* **Why:** Filters logs specifically from the current boot cycle (`-b`) to analyze startup failure conditions.



---

### Scenario 2: High CPU Usage

* **Step 1:** `top -b -n 1 | head -n 20`
* **Why:** Displays active processes with real-time CPU and memory usage statistics.


* **Step 2:** `ps aux --sort=-%cpu | head -10`
* **Why:** Takes a snapshot of processes sorted by CPU usage in descending order.


* **Step 3:** `pidof <process_name>`
* **Why:** Obtains the exact PID(s) of the high-consumption process.


* **Step 4:** `pidstat -p <PID> 1 5`
* **Why:** Samples CPU usage over time to see if the process is continuously consuming resources or spiking.



---

### Scenario 3: Finding Service Logs (`docker`)

* **Step 1:** `systemctl status docker`
* **Why:** Verifies unit status and exact service identifier name.


* **Step 2:** `journalctl -u docker -n 50`
* **Why:** Displays the 50 most recent output logs from the Docker daemon.


* **Step 3:** `journalctl -u docker -f`
* **Why:** Follows Docker logs in real time (`tail -f` mode).


* **Step 4:** `journalctl -u docker --since "1 hour ago"`
* **Why:** Limits output to logs generated within a specific timeframe.



---

### Scenario 4: File Permissions Issue (`backup.sh`)

* **Step 1:** `ls -l /home/user/backup.sh`
* **Why:** Checks permission flags (`-rw-r--r--` indicates missing execute permissions).


* **Step 2:** `chmod +x /home/user/backup.sh`
* **Why:** Grants execution privileges (`+x`) to the script.


* **Step 3:** `ls -l /home/user/backup.sh`
* **Why:** Confirms updated permissions (`-rwxr-xr-x`).


* **Step 4:** `/home/user/backup.sh`
* **Why:** Executes the script to verify execution succeeds without permission errors.
