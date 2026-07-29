# 🐧 Day 07: Linux File System Hierarchy & Production Troubleshooting

Welcome to **Day 07** of the Production-Ready DevOps & SRE Journey! This repository section contains core practical guides, real-world troubleshooting scenarios, reference cheat sheets, and automated shell scripts for managing Linux environments.

---

## 📂 Repository Structure & Files

* 📁 **`Day-07/`**
  * 📄 **`01-day-07-linux-fs-and-scenarios.md`**
    * Detailed walkthrough of the Linux File System Hierarchy Standard (FHS).
    * Step-by-step resolution for 4 production troubleshooting scenarios.
  * 📄 **`02-Day-07-cheatsheet.md`**
    * Quick-reference cheat sheet for core Linux commands and FHS paths.
    * Permission bits (`chmod`) reference and essential troubleshooting one-liners.
  * ⚙️ **`backup.sh`**
    * Production-grade automated Bash script for system configuration backups (`/etc`).
    * Includes archive compression, execution logging, and automated 7-day retention cleanup.
  * 📄 **`backup-script-explanation.md`**
    * Complete line-by-line breakdown of `backup.sh`.
    * In-depth explanation of Bash Strict Mode (`set -euo pipefail`).

---

## 🎯 Key Learning Objectives

* **Linux Filesystem Hierarchy Standard (FHS):** Master purpose-driven directories (`/etc`, `/var/log`, `/tmp`, `/opt`, `/usr/bin`).
* **Production Incident Resolution:** 
  * Service startup failure diagnosis (`systemctl`, `journalctl`).
  * Process and high CPU usage inspection (`top`, `ps`, `pidstat`).
  * Application & Docker container log tracking.
  * File permission and ownership resolution (`chmod`, `chown`).
* **Shell Script Automation:** Write robust, error-tolerant Bash scripts adhering to strict execution safety flags.

---

## ⚡ Quick Execution Guide

To test the automated backup script locally:

```bash
# 1. Grant execution permissions
chmod +x backup.sh

# 2. Run the backup script
./backup.sh

# 3. Verify generated logs
cat /tmp/backup.log
