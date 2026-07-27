# 🛠️ Linux Troubleshooting Runbook (Day 05 - 90DaysOfDevOps&SRE)

As a DevOps and SRE Engineer, troubleshooting Linux-based systems efficiently is one of the most critical day-to-day skills. This runbook serves as a structured, quick-reference guide to diagnose and resolve common system performance issues, resource bottlenecks, and application failures.

---

## 📋 Table of Contents

1. [Introduction]
2. [Phase 1: Initial System Triage]
3. [Phase 2: Resource-Specific Troubleshooting]
    * [CPU Bottlenecks]
    * [Memory Issues]
    * [Disk & Storage Issues]
    * [Network & Connectivity Issues]

4. [Phase 3: Log Analysis & Diagnostics]
5. [Phase 4: Process Management & Termination]
6. [Quick Checklist for Incidents]

---

## 1. Introduction

When an alert fires or an application slows down, resist the urge to immediately restart services. Instead, follow a structured **observe $\rightarrow$ isolate $\rightarrow$ mitigate** workflow to find the root cause and document it for post-mortems.

---

## 2. Phase 1: Initial System Triage

Run these quick diagnostic commands first to get an immediate overview of system health and stability.

| Objective | Command | Description |
| --- | --- | --- |
| **Check System Load & Uptime** | `uptime` | Shows how long the system has been running and the 1, 5, and 15-minute load averages. |
| **Check Overall Resource Usage** | `htop` or `top` | Interactive view of CPU, memory, and running processes. (Install `htop` if missing). |
| **Check Kernel & System Logs** | `dmesg -T --level=err,warn` | Displays hardware/kernel error messages with human-readable timestamps. |

---

## 3. Phase 2: Resource-Specific Troubleshooting

### 🔍 CPU Bottlenecks

* **Symptom:** High load average, sluggish responses, high CPU utilization.
* **Commands to run:**
```bash
# Check CPU usage per core and overall statistics
mpstat -P ALL 1

# Identify top CPU-consuming processes
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head -n 10

```


* **Resolution Steps:**
1. Identify the rogue process ID (PID) from the `ps` or `top` output.
2. Check if it's an expected workload or a runaway loop.
3. Gracefully stop or kill the process if necessary (see [Phase 5](https://www.google.com/search?q=%235-phase-4-process-management--termination)).



---

### 🧠 Memory Issues

* **Symptom:** Out Of Memory (OOM) errors, swapping, application crashes.
* **Commands to run:**
```bash
# Check free and used memory (in human-readable format)
free -h

# Check swap usage and activity
swapon --show
vmstat 1 5

# Identify processes consuming the most memory
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%mem | head -n 10

```


* **Checking for OOM Killer actions:**
```bash
# Inspect system logs for OOM killer invocations
grep -i oom /var/log/syslog
# Or via journalctl
journalctl -k -g "Out of memory"

```


* **Resolution Steps:**
1. Clear page cache safely (if necessary): `sync; echo 1 > /proc/sys/vm/drop_caches`
2. Scale up instance memory or optimize application memory flags (e.g., JVM heap sizes).



---

### 💾 Disk & Storage Issues

* **Symptom:** `No space left on device` errors, slow I/O operations.
* **Commands to run:**
```bash
# Check disk space usage on mounted filesystems
df -h

# Find large files/directories consuming space in current directory
du -ah --max-depth=1 | sort -hr | head -n 10

# Check disk I/O performance and bottlenecks
iostat -xz 1 5

```


* **Resolution Steps:**
1. Clean up old logs, temporary files (`/tmp`), or Docker build caches (`docker system prune`).
2. Check for runaway log generation in `/var/log/`.



---

### 🌐 Network & Connectivity Issues

* **Symptom:** Connection timeouts, DNS failures, service unreachable.
* **Commands to run:**
```bash
# Check active network connections and listening ports
ss -tulpn

# Test connectivity to a host/port
nc -zv <hostname_or_ip> <port>
# or
telnet <hostname_or_ip> <port>

# Test DNS resolution
dig <domain_name>
# or
nslookup <domain_name>

# Trace network path
traceroute <destination>

```


* **Resolution Steps:**
1. Verify firewall/security group rules (`ufw status` or `iptables -L`).
2. Check network interface status: `ip a` and route tables: `ip route`.



---

## 4. Phase 3: Log Analysis & Diagnostics

System and service logs are crucial for pinpointing errors.

* **Systemd Service Logs:**
```bash
# View logs for a specific service (e.g., nginx, docker, ssh)
journalctl -u <service_name> -n 100 --no-pager

# Follow logs in real-time
journalctl -u <service_name> -f

```


* **Traditional Log Files (`/var/log/`):**
```bash
# Tail general system logs
tail -f /var/log/syslog

# Search for errors or failures across logs
grep -i "error" /var/log/syslog | tail -n 50

```



---

## 5. Phase 4: Process Management & Termination

When a process hangs or misbehaves, follow this escalation path:

1. **Check process status:** `ps aux | grep <process_name>`
2. **Graceful termination (SIGTERM - Signal 15):** Allows the process to save state and exit safely.
```bash
kill <PID>

```


3. **Force termination (SIGKILL - Signal 9):** Use only if the process does not respond to SIGTERM.
```bash
kill -9 <PID>

```


4. **Kill by name:**
```bash
pkill -f <process_name>

```



---

## 6. Quick Checklist for Incidents

* [ ] What changed recently? (Deployments, config changes, patches)
* [ ] Is the issue infrastructure-wide or isolated to a single host?
* [ ] Are CPU, Memory, Disk, or Network saturated?
* [ ] What do the application and system logs (`journalctl`) say right before the failure?
* [ ] Document findings and mitigation actions for the post-mortem report.

---

*Happy Troubleshooting! 🚀*
