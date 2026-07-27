# 🚀 Linux Troubleshooting Commands Cheat Sheet

A quick-reference cheat sheet for DevOps engineers containing essential Linux commands for system diagnostics, resource monitoring, network troubleshooting, and log analysis.

---

## 📊 1. System Overview & Triage

| Task | Command | Description |
| :--- | :--- | :--- |
| **System Uptime & Load** | `uptime` | Displays uptime, active user count, and 1, 5, 15-minute load averages. |
| **System Architecture** | `uname -a` | Displays OS name, kernel version, host name, and system architecture. |
| **Live Process Monitor** | `top` / `htop` | Interactive live view of running processes, CPU, and memory utilization. |
| **System Resource Overview** | `vmstat 1 5` | Reports virtual memory, processes, traps, paging, and CPU activity every second. |
| **Hardware / Kernel Errors** | `dmesg -T --level=err,warn` | Shows kernel/hardware warning and error logs with human-readable timestamps. |

---

## ⚡ 2. CPU Diagnostics

| Task | Command | Description |
| :--- | :--- | :--- |
| **Per-Core CPU Stats** | `mpstat -P ALL 1` | Displays processor activity per core (requires `sysstat` package). |
| **Top CPU Processes** | `ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu \| head -n 10` | Lists top 10 CPU-consuming processes. |
| **Process Tree** | `pstree -p` | Displays running processes as a tree showing parent-child relationships. |
| **Real-time Process CPU** | `pidstat -u 1 5` | Monitors CPU statistics for individual tasks over time. |

---

## 🧠 3. Memory & Swap Diagnostics

| Task | Command | Description |
| :--- | :--- | :--- |
| **Memory Summary** | `free -h` | Shows total, used, free, shared, and available memory in human-readable units. |
| **Detailed Memory Breakdown** | `cat /proc/meminfo` | Detailed information about memory usage, buffers, and cached memory. |
| **Active Swap Devices** | `swapon --show` | Lists active swap spaces and their current usage metrics. |
| **Top Memory Processes** | `ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%mem \| head -n 10` | Lists top 10 memory-consuming processes. |
| **Check OOM Killer Events** | `grep -i oom /var/log/syslog` | Searches system log for Out-Of-Memory (OOM) killer events. |
| **Check OOM via Journalctl** | `journalctl -k -g "Out of memory"` | Queries kernel logs specifically for OOM killer invocations. |
| **Clear Page Cache** | `sync; echo 1 > /proc/sys/vm/drop_caches` | Flushes dirty page cache safely to free cached memory. |

---

## 💾 4. Disk & Storage Diagnostics

| Task | Command | Description |
| :--- | :--- | :--- |
| **Disk Space Usage** | `df -h` | Displays disk space utilization for all mounted filesystems. |
| **Inode Usage** | `df -i` | Displays total and available inode usage per filesystem. |
| **Large Files Search** | `du -ah --max-depth=1 \| sort -hr \| head -n 10` | Displays 10 largest files/directories in current path. |
| **Find Top Large Files** | `find /var/log -type f -size +100M` | Locates files larger than 100MB in a specific directory. |
| **Disk I/O Statistics** | `iostat -xz 1 5` | Reports extended I/O statistics per disk device (requires `sysstat`). |
| **Process Disk I/O Usage** | `iotop -o` | Interactive monitor showing processes actively performing disk I/O. |
| **Block Device Overview** | `lsblk` | Lists information about all available block devices. |

---

## 🌐 5. Network & Connectivity Diagnostics

| Task | Command | Description |
| :--- | :--- | :--- |
| **Active Connections/Ports** | `ss -tulpn` | Displays all listening TCP/UDP ports and associated process PIDs. |
| **Legacy Port Check** | `netstat -tulpn` | Legacy command to list listening ports and active sockets. |
| **Network Interfaces** | `ip a` or `ip addr show` | Displays IP addresses and interface configurations. |
| **Routing Table** | `ip route` | Displays kernel routing tables. |
| **Test Host Port Access** | `nc -zv <host> <port>` | Checks if a specific TCP port is open and reachable on remote host. |
| **DNS Name Resolution** | `dig <domain_name>` | Performs detailed DNS lookup for a domain. |
| **Quick DNS Lookup** | `nslookup <domain_name>` | Simple querying tool for domain name servers. |
| **Trace Route Path** | `traceroute <destination>` | Traces route packets take to network host. |
| **Network Traffic Capture** | `tcpdump -i eth0 -n port 80` | Captures and displays HTTP traffic on interface `eth0`. |
| **Firewall Status (UFW)** | `ufw status` | Checks Ubuntu Uncomplicated Firewall rules and status. |
| **Firewall Status (iptables)**| `iptables -L -n -v` | Lists all active iptables firewall rules with packet counters. |

---

## 📜 6. Systemd & Log Diagnostics

| Task | Command | Description |
| :--- | :--- | :--- |
| **Service Log History** | `journalctl -u <service_name> -n 100 --no-pager` | Prints last 100 log lines for a specific systemd service. |
| **Real-time Log Tailing** | `journalctl -u <service_name> -f` | Follows real-time logs for a specified service. |
| **Boot Logs** | `journalctl -b` | Displays all logs generated during current system boot. |
| **Kernel Log Stream** | `dmesg -w` | Streams kernel log messages in real-time. |
| **Tail System Log** | `tail -f /var/log/syslog` | Follows global system log output in real-time. |
| **Search Log Errors** | `grep -i "error" /var/log/syslog \| tail -n 50` | Searches recent log entries for keywords matching 'error'. |

---

## ⚙️ 7. Process & Service Management

| Task | Command | Description |
| :--- | :--- | :--- |
| **Find Process PID** | `pgrep <process_name>` or `ps aux \| grep <process_name>` | Returns process IDs matching process name. |
| **Graceful Stop (SIGTERM)** | `kill <PID>` | Sends SIGTERM (15) signal to process, requesting clean termination. |
| **Force Stop (SIGKILL)** | `kill -9 <PID>` | Sends SIGKILL (9) signal to force immediate termination. |
| **Kill by Process Name** | `pkill -f <process_name>` | Kills all processes matching name string. |
| **Service Management** | `systemctl status/start/stop/restart <service_name>` | Manages lifecycle of systemd services. |
| **Open Files by Process** | `lsof -p <PID>` | Lists all files, sockets, and pipes opened by specified PID. |
| **Find Process using Port** | `lsof -i :<port>` | Identifies process currently bound to specific port number. |
