
# 🐧 Day 06: Linux File Management, I/O Redirection & Permissions Security

Welcome to **Day 06** of the **Production-Ready DevOps & SRE Journey**! 

In enterprise environments, system reliability and security depend heavily on fine-grained file permissions, proper process ownership, and efficient shell stream management. This module covers core Linux filesystem management, input/output (I/O) redirection, file modes, and access control mechanisms crucial for automated deployments and infrastructure management.

---

## 📌 Module Objectives

By completing today's module, you will be able to:
- Navigate and manipulate Linux file streams (`stdin`, `stdout`, `stderr`).
- Secure system scripts, configuration files, and secrets using absolute (octal) and symbolic permission modes.
- Manage process and file access boundaries using user and group ownership (`chown`).
- Implement hard and symbolic links to manage binaries, dependencies, and dynamic configurations.
- Automate filesystem management and verification using Bash scripts.

---

## 📚 Technical Overview

### 1. File Streams & I/O Redirection
Linux treats hardware and system handles as files. Understanding how standard streams interact with files allows DevOps engineers to write robust automation scripts.

| Stream | Descriptor | Standard File | Usage / Description |
| :--- | :---: | :--- | :--- |
| **`stdin`** | `0` | Keyboard / Input | Standard input stream read by commands |
| **`stdout`** | `1` | Terminal Display | Standard output stream for normal execution |
| **`stderr`** | `2` | Terminal Display | Standard error stream for diagnostics & alerts |

#### Redirection Commands:
```bash
# Overwrite stdout to a file
date > deployment.log

# Append stdout to a file
uptime >> deployment.log

# Capture stderr separately
ls /root 2> error.log

# Discard output completely (silence script execution)
./healthcheck.sh > /dev/null 2>&1

```

---

### 2. Linux File Permissions (`chmod`)

Linux enforces access control through **User (u)**, **Group (g)**, and **Others (o)** permission bits.

$$\text{Total Permission} = \text{User Bit} + \text{Group Bit} + \text{Others Bit}$$

```
  File Type (- or d)
  │
  ▼
  -  r w x  r - x  r - -
    └──┬──┘└──┬──┘└──┬──┘
       │      │      └── Others (Read)            --> 4
       │      └───────── Group  (Read, Execute)   --> 5
       └──────────────── User   (Read/Write/Exec) --> 7

```

#### Numeric (Octal) Reference:

* **`4`**: Read (`r`)
* **`2`**: Write (`w`)
* **`1`**: Execute (`x`)

#### Standard Enterprise Patterns:

* `chmod 755 script.sh` — Standard executable file permissions (User: Full, Group/Others: Read+Exec).
* `chmod 644 config.yaml` — Standard configuration file permissions (User: Read/Write, Group/Others: Read-only).
* `chmod 600 id_rsa` — Secure key file permissions (User: Read/Write, Group/Others: None).

---

### 3. File Ownership (`chown`)

Security compliance requires enforcing the principle of least privilege by running services under restricted users/groups.

```bash
# Change owner only
sudo chown devops_user app.conf

# Change owner and group recursively across directories
sudo chown -R app_user:app_group /var/log/app/

```

---

## 🛠️ Folder Structure & Files

```text
Day-06/
├── README.md               # Day 06 documentation and guide
├── file-io-practice.md     # Hands-on exercises and solutions
├── setup_logs.sh           # Automation script for log dir setup

```

---

## 🚀 Hands-On Practice Checklist

Complete the practical exercises detailed in [`file-io-practice.md`](https://www.google.com/search?q=./file-io-practice.md):

* [x] **Task 1:** Create and edit configuration files using `nano`/`vim` and `cat`.
* [x] **Task 2:** Test `stdout` and `stderr` redirection using `>`, `>>`, and `2>`.
* [x] **Task 3:** Modify file permissions using octal and symbolic `chmod` commands.
* [x] **Task 4:** Change user and group ownership using `chown`.
* [x] **Task 5:** Compare behavior between Hard Links (`ln`) and Soft Links (`ln -s`).
* [x] **Challenge Task:** Run `setup_logs.sh` to generate a secure log architecture.

---

## 💡 Best Practices for SREs & DevOps Engineers

1. **Context Management:** Always run scripts with explicit permission checks (`chmod 755`) before deployment inside CI/CD pipelines.
2. **Never Use `chmod 777`:** Granting full permissions to `others` introduces critical security vulnerabilities.
3. **Mute Noisy Commands in Automation:** Redirect stdout/stderr appropriately (`> /dev/null 2>&1`) to keep automated logs readable.
4. **Enforce Least Privilege:** Service binaries and data directories should be owned by service accounts (e.g., `www-data`, `postgres`), never `root`.

---

## 🤝 Connect & Track Progress

* **Repository:** [Production-Ready DevOps & SRE Journey](https://www.google.com/search?q=https://github.com/NB11-ML/Production-Ready-DevOps-SRE-Journey)
* **Author:** [NB11-ML](https://www.google.com/search?q=https://github.com/NB11-ML)
* **Challenge:** 90 Days of DevOps / SRE Mastery
