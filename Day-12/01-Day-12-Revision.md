# Day 12: Breather & Revision (Days 01–11)

## 🎯 Revision Goal
Take a one-day pause to consolidate everything from Days 01–11 to ensure a rock-solid grasp of Linux administration, process states, file systems, and user permissions before advancing further in the production-ready DevOps roadmap.

---

## 🔍 Part 1: Deep-Dive Review & Practical Observations

### 🧠 1. Mindset & Learning Plan Calibration
* **Context**: Reevaluated the original Day 01 roadmap goals against current retention.
* **Observation**: The pace is solid, but transitioning from simple tool usage to production engineering requires deeper muscle memory regarding edge cases in log parsing and advanced permission masking.
* **Tweak**: Dedicating an extra 10 minutes daily to debugging live failure logs instead of just validating positive cases.

### ⚙️ 2. Processes & System Services Audit
Two diagnostic validation commands from Day 04 and Day 05 were rerun to evaluate active workloads:

1. **Process Inspection**:
   ```bash
   ps aux --sort=-%mem | head -n 5
   ```
   * *Observation*: Validated active resident memory hogs. Identified parent system daemons (`systemd`) running with stable PID allocations and clean memory thresholds.
2. **Systemd Journal Logs**:
   ```bash
   journalctl -u ssh -n 20 --no-pager
   ```
   * *Observation*: Analyzed system logs for the SSH service. Confirmed crisp, successful cryptographic handshakes without authentication failures or transient service interruptions.

### 📂 3. File Operations & Permission Safeguards
Executed three foundational storage commands to practice directory structural manipulation:

```bash
# Setup practice tree
mkdir -p /tmp/devops-revision/infra

# Output system validation data cleanly
echo "System Verification Log: $(date)" >> /tmp/devops-revision/infra/status.log

# Evaluate permissions and ownership structures
ls -la /tmp/devops-revision/infra/status.log
```
* *Key Takeaway*: Append operations (`>>`) seamlessly preserve history, while explicit `mkdir -p` structures completely prevent scripting failures caused by missing parent hierarchies.

### 🚨 4. Production Incident Cheat Sheet
Top 5 triage commands selected from Day 03 to leverage immediately during infrastructure downtime:

* `journalctl -xeu <service>`: Instantly extracts downstream system core crash stack traces.
* `df -h`: Diagnoses severe system locks caused by sudden 100% root storage saturation.
* `top -b -n 1`: Captures a lightweight, low-overhead snapshot of system computation hogs.
* `ss -tulpn`: Maps dynamic application networking bottlenecks and verifies active socket binds.
* `tail -f /var/log/syslog`: Streams system-level kernel hardware interrupts and device logs live.

### 👥 5. User Management & Privilege Integrity
Recreated a privilege delegation lab context from Day 09/11 to track safe workspace sharing:

```bash
# Evaluate active user context
id

# Check directory execution flags
ls -ld /tmp/devops-revision/infra
```
* *Key Takeaway*: Absolute path tracking alongside ID verification guards security layers across local development setups and automated environment runners.

---

## 📝 Part 2: Mini Self-Check

### Q1: Which 3 commands save you the most time right now, and why?
1. `systemctl`: Completely centralizes application lifecycles, configuration reloads, and diagnostic state monitoring into one unified standard interface.
2. `grep -ri`: Speeds up discovery by recursively extracting variable entries, target blocks, and explicit errors directly out of dense application logs.
3. `chmod / chown`: Instantly corrects complex filesystem blocks and unblocks automated tasks facing workspace access issues.

### Q2: How do you check if a service is healthy? List the exact 2–3 commands you’d run first.
```bash
# 1. Quick high-level runtime state validation
systemctl status <service-name>

# 2. Extract explicit functional failure logs and traces
journalctl -u <service-name> -n 50 --no-pager

# 3. Verify target port listener allocation
ss -tulpn | grep <port-or-service>
```

### Q3: How do you safely change ownership and permissions without breaking access? Give one example command.
Always explicitly check existing file state layouts using `ls -l` before running modifications, target specific objects explicitly rather than applying blanket root permission masks, and avoid dangerous loose wildcards like `chmod 777`.
```bash
# Example: Safely assign specific group access onto custom target logs
sudo chown ubuntu:adm /var/log/custom-app.log && sudo chmod 640 /var/log/custom-app.log
```

### Q4: What will you focus on improving in the next 3 days?
* Deep-dive practice mapping out explicit directory masking behavior using custom `umask` defaults.
* Mastering complex, advanced `journalctl` time-window filtering queries (`--since`, `--until`).
* Automating simple, baseline environmental sanity test tasks using robust bash checks.

---
## 🏁 Verification Checkpoint
- [x] Mindset goals reviewed and adjusted.
- [x] Runtime troubleshooting commands executed.
- [x] Filesystem permission trees tested.
- [x] Incident cheat sheet prioritized.
- [x] Core self-check scenarios addressed completely.
