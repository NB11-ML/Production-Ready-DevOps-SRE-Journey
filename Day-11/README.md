
<div align="center">

# 🐧 Day 11: Master Linux File Ownership (`chown` & `chgrp`)

[![DevOps](https://img.shields.io/badge/DevOps-SRE-blue.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)](#)
[![Linux](https://img.shields.io/badge/Linux-Kernel-FCC624.svg?style=for-the-badge&logo=linux&logoColor=black)](#)
[![Security](https://img.shields.io/badge/Security-Access--Control-red.svg?style=for-the-badge&logo=shield&logoColor=white)](#)

*A comprehensive hands-on lab on user and group permissions, granular access control, and ownership management for enterprise Linux administration.*

---

</div>

## 📌 Executive Summary

In enterprise production environments, proper file ownership and permission management are foundational to security, compliance, and operational stability. Unrestricted access or misplaced ownership can lead to privilege escalation, service downtime, or data corruption.

This module covers the core principles of Linux ownership management using `chown` and `chgrp`. It demonstrates practical techniques for configuring user/group scoping, recursive directory tree management, and multi-user sandbox structures typical of production CI/CD systems, container volumes, and microservices.

---

## 🎯 Learning Objectives

By completing this module, you will master:
1. **Anatomy of Ownership:** Deciphering `ls -l` metadata (User vs. Group vs. Others).
2. **User Ownership (`chown`):** Reassigning individual file and directory ownership.
3. **Group Ownership (`chgrp`):** Managing multi-user collaborative access via group scoping.
4. **Combined Ownership (`chown owner:group`):** Atomically modifying both owner and group attributes in a single command.
5. **Recursive Propagation (`-R`):** Safely cascading ownership changes down deep file directory trees.

---

## 🛠 Directory Structure

```text
Day-11/
├── 01-Day-11-file-ownership.md    # Primary challenge guide & concepts
├── 02-Day-11-Cheat-Sheet.md       # Quick reference guide & syntax breakdown
└── README.md                      # Module documentation

```

---

## 🚀 Lab Overview & Tasks

### Task 1: Deciphering Linux Permissions

Analyze file attributes using standard long-listing format:

```bash
ls -l ~

```

```text
-rw-r--r-- 1 owner group size date filename

```

* **Owner (User):** Individual Linux user controlling dedicated execution/read rights.
* **Group:** Shared security context enabling multi-user team access.

---

### Task 2 & 3: Atomic Owner & Group Management

Creating standalone files and re-assigning individual ownership:

```bash
# User Ownership
sudo chown tokyo devops-file.txt
sudo chown berlin devops-file.txt

# Group Ownership
sudo groupadd heist-team
sudo chgrp heist-team team-notes.txt

```

---

### Task 4 & 5: Combined & Recursive Ownership

Atomically setting owner and group attributes across nested file structures:

```bash
# Combined Owner & Group update
sudo chown professor:heist-team project-config.yaml
sudo chown berlin:heist-team app-logs/

# Recursive directory propagation
mkdir -p heist-project/{vault,plans}
sudo groupadd planners
sudo chown -R professor:planners heist-project/

```

---

### Task 6: Practical Enterprise Scenario

Simulating access control across segregated application resources:

```bash
# Access Control Matrix
sudo chown tokyo:vault-team bank-heist/access-codes.txt
sudo chown berlin:tech-team bank-heist/blueprints.pdf
sudo chown nairobi:vault-team bank-heist/escape-plan.txt

```

---

## 📑 Command Quick Reference

| Command | Action | Example |
| --- | --- | --- |
| `ls -l` | View file permissions & ownership | `ls -l application.log` |
| `chown` | Change file owner | `sudo chown app-user main.py` |
| `chgrp` | Change file group | `sudo chgrp dev-team main.py` |
| `chown user:group` | Change both user and group simultaneously | `sudo chown app-user:dev-team main.py` |
| `chown -R` | Change ownership recursively across directory trees | `sudo chown -R www-data:www-data /var/www/` |

---

## 💡 Why This Matters for DevOps & SRE

* **Container Security:** Non-root execution in Docker/Kubernetes relies on matching host and container UID/GIDs.
* **CI/CD Pipelines:** Artifact directories require specific group permissions to allow build agents write access without granting full root rights.
* **Web Servers & Databases:** Services like Nginx, Apache, or PostgreSQL require tight ownership scoping (`e.g., www-data:www-data` or `postgres:postgres`) to operate securely.

---

**[Production-Ready DevOps & SRE Journey](https://github.com/NB11-ML/Production-Ready-DevOps-SRE-Journey)** • Hands-on Engineering Practice
