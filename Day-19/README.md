# 🚀 Day 19: Shell Scripting Project – Log Rotation, Backups & Cron

Welcome to **Day 19** of the Production-Ready DevOps & SRE Journey! Today's focus is on applying the shell scripting concepts learned over the past few days into **real-world, production-ready mini-projects**.

---

## 🌳 Repository Hierarchy

```text
Day-19/
├── 📖 Documentation
│   ├── 📄 README.md                            # Main Day 19 overview
│   ├── 📄 01-Day-19-project.md                 # Detailed project notes, tasks, & logs
│   └── 📄 02-Day-19-Cheat-Sheet.md             # Cheat sheet for find, tar, and cron
│
└── 📜 Scripts
    ├── 📜 log_rotate.sh                        # Automated log compression and cleanup
    ├── 📜 backup.sh                            # Timestamped directory archiver with retention
    └── 📜 maintenance.sh                       # Wrapper script combining backup & log rotation
```

---

## 📌 Project Modules

### 1️⃣ Log Rotation (`log_rotate.sh`)
A script designed to manage log growth on servers:
* Compresses `.log` files older than 7 days using `gzip`.
* Deletes compressed `.gz` archives older than 30 days to free up disk space.
* Uses `find` to enforce retention policies automatically.

### 2️⃣ Server Backup (`backup.sh`)
A robust backup utility for critical directories:
* Creates timestamped `.tar.gz` archives (e.g., `backup-2026-08-10_14-05-30.tar.gz`).
* Strips absolute paths during compression using `tar -C` to ensure clean extraction.
* Automatically deletes outdated backups older than 14 days.

### 3️⃣ Automated Scheduling (`maintenance.sh` & Cron)
A central wrapper script that coordinates both tasks and logs their outputs to `/var/log/maintenance.log`. Scheduled completely via the Linux `cron` daemon:
* **Daily Log Rotation:** Runs at 2:00 AM (`0 2 * * *`).
* **Weekly/Frequent Backups:** Schedules configured for Sunday 3:00 AM or testing intervals (`*/5 * * * *`).
* **Daily Maintenance Wrapper:** Runs at 1:00 AM (`0 1 * * *`).

---

## ⚡ Execution & Usage

Make the scripts executable and run them with the required directory paths:

```bash
# Grant execution permissions
chmod +x Scripts/*.sh

# Run Log Rotation manually
./Scripts/log_rotate.sh /var/log/myapp

# Run Backup manually
./Scripts/backup.sh /var/www/html /backups/web
```

---

## 💡 Professional Takeaways

* **Safe File Searching:** Leveraging `find ... -exec` is far safer and more robust than writing complex bash loops to handle file retention.
* **Clean Archiving:** Using `tar -C` prevents the "nested absolute paths" issue when extracting backups.
* **Silent Automation:** Creating wrapper scripts that redirect `stdout` and `stderr` (`>> logfile 2>&1`) is crucial for debugging cron jobs that run headlessly in the background.
