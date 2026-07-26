# 🐧 Linux File System & Troubleshooting Cheat Sheet

## 📂 1. Directory Hierarchy at a Glance

| Directory | Purpose | Key Commands & Files |
| --- | --- | --- |
| **`/`** | Root of the entire filesystem tree. | `cd /` |
| **`/etc`** | System & service configuration files. | `/etc/hostname`, `/etc/fstab`, `/etc/nginx/` |
| **`/var/log`** | Application & system log files. | `syslog`, `journal/`, `auth.log` |
| **`/home`** | Personal user home directories. | `/home/username/`, `~/.ssh/` |
| **`/root`** | Home directory for root administrator. | `/root/.bashrc`, `/root/.ssh/` |
| **`/tmp`** | Temporary short-lived system files. | Cleared on reboot or periodically |
| **`/bin`** | Essential command binaries (system-critical). | `ls`, `cp`, `bash`, `cat` |
| **`/usr/bin`** | Non-essential user binaries & packages. | `git`, `curl`, `python3` |
| **`/opt`** | Optional/third-party standalone software. | `/opt/datadog-agent`, `/opt/containerd` |

---

## 🛠️ 2. Scenario-Based Troubleshooting Workflows

### 🔴 Scenario 1: Service Not Starting (`myapp`)

```bash
# 1. Check current status & immediate exit code
systemctl status myapp

# 2. View recent logs specific to the service
journalctl -u myapp -n 50 --no-pager

# 3. Verify if service is set to auto-start on boot
systemctl is-enabled myapp

# 4. Filter logs specifically from current boot cycle
journalctl -b -u myapp

# 5. Enable auto-start on boot (if disabled)
systemctl enable myapp

```

### ⚡ Scenario 2: High CPU Usage

```bash
# 1. Open interactive process viewer (or static batch mode)
top -b -n 1 | head -n 20

# 2. View top 10 processes sorted by CPU usage
ps aux --sort=-%cpu | head -10

# 3. Find Process ID (PID) of target application
pidof <process_name>

# 4. Monitor CPU usage for PID at 1-sec intervals (5 samples)
pidstat -p <PID> 1 5

```

### 📜 Scenario 3: Locating Service Logs (`docker`)

```bash
# 1. Verify service status
systemctl status docker

# 2. Fetch last 50 lines of logs
journalctl -u docker -n 50

# 3. Follow logs in real-time (like tail -f)
journalctl -u docker -f

# 4. Filter logs by time window
journalctl -u docker --since "1 hour ago"

```

### 🔐 Scenario 4: Permission Denied (`backup.sh`)

```bash
# 1. Check current permission modes
ls -l /home/user/backup.sh
# Expected output without execute: -rw-r--r--

# 2. Grant execute permission
chmod +x /home/user/backup.sh

# 3. Verify updated modes
ls -l /home/user/backup.sh
# Expected output with execute: -rwxr-xr-x

# 4. Execute script
./backup.sh

```

---

## ⚡ 3. One-Liner Quick Commands

```bash
# Find 5 largest log files/directories in /var/log
du -sh /var/log/* 2>/dev/null | sort -h | tail -5

# Quick config verification
cat /etc/hostname

# Inspect user home permissions and dotfiles
ls -la ~

```

---

## 🔢 4. Quick Permission Reference (`chmod`)

| Bit / Flag | Numeric | Meaning |
| --- | --- | --- |
| **`r`** | `4` | **Read:** View file contents or list directory. |
| **`w`** | `2` | **Write:** Modify file or create/delete files in directory. |
| **`x`** | `1` | **Execute:** Run file as program or enter (`cd`) directory. |

* **`chmod 755 script.sh`** -> Owner: `rwx` (7), Group: `r-x` (5), Others: `r-x` (5)


* **`chmod 600 id_rsa`** -> Owner: `rw-` (6), Group: `---` (0), Others: `---` (0)
