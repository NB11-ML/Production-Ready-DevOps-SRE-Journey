# Day 05: Linux Troubleshooting & Diagnostic Runbook
Welcome to **Day 05** of the **Production-Ready DevOps & SRE Journey**! 🚀

Linux is the foundational operating system powering modern cloud infrastructure and containerized workloads. When incident alerts fire or production services experience latency, having a structured, systematic troubleshooting workflow is critical. This module focuses on diagnosing performance bottlenecks, reading system telemetry, and resolving infrastructure issues effectively.

---

## 📌 Objectives & Key Learnings

By completing Day 05, you will be able to:
1. **System Triage:** Quickly evaluate overall system load, uptime, and kernel health.
2. **Resource Isolation:** Pinpoint bottlenecks across CPU, Memory (RAM/Swap), Disk I/O, and Network interfaces.
3. **Log Analysis:** Query systemd unit logs, kernel ring buffers (`dmesg`), and system logs to perform root-cause analysis.
4. **Process Management:** Safely inspect, control, and terminate misbehaving or runaway processes.

---

## 📁 Directory Structure

```text
Day-05/
├── README.md                          # Day 05 Overview & Guide
├── linux-troubleshooting-runbook.md   # Step-by-step incident response runbook
└── cheat-sheet.md                     # Quick reference guide for diagnostic commands
