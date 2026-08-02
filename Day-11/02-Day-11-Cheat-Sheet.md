# 🐧 🔐Linux File Ownership Cheat Sheet (`chown` & `chgrp`)

A quick-reference guide for managing Linux file and directory ownership, based on Day 11 of the Production-Ready DevOps/SRE Journey.

---

## 1. Fast Command Syntax Reference

| Task | Syntax / Example |
| --- | --- |
| **Inspect Ownership** | `ls -l <filename>` |
| **Change Owner Only** | `sudo chown <user> <file>` |
| **Change Group Only (chgrp)** | `sudo chgrp <group> <file>` |
| **Change Group Only (chown)** | `sudo chown :<group> <file>` |
| **Change Owner & Group** | `sudo chown <user>:<group> <file>` |
| **Recursive Ownership** | `sudo chown -R <user>:<group> <dir>/` |

---

## 2. Linux `ls -l` File Anatomy

When you list files using `ls -l`, ownership information appears as follows:

```text
-rw-r--r--  1  tokyo  vault-team  1024  Oct 24 10:00  access-codes.txt
▲              ▲      ▲
│              │      └── Group Name
│              └───────── Owner Username
└──────────────────────── Permission Triplets (User / Group / Others)

```

---

## 3. Essential Administrative Commands

### User & Group Management

```bash
# Add new users
sudo useradd tokyo
sudo useradd berlin

# Add new groups
sudo groupadd vault-team
sudo groupadd tech-team

```

### Modifying File Ownership

```bash
# Single file owner change
sudo chown tokyo devops-file.txt

# Single file group change
sudo chgrp heist-team team-notes.txt

# Combined owner and group change
sudo chown professor:heist-team project-config.yaml

# Apply recursively to an entire directory tree
sudo chown -R professor:planners heist-project/

```

---

## 4. Troubleshooting & Pro-Tips

* **Need Admin Privileges?** Non-root users cannot assign files to other users. Always prepend `sudo` to `chown` or `chgrp` commands.
* **Missing User or Group Errors:** Ensure users/groups exist before executing `chown`. Check existing entities via:
* Users: `cat /etc/passwd | cut -d: -f1`
* Groups: `cat /etc/group | cut -d: -f1`


* **DevOps Best Practice:** Avoid running services as `root`. Restrict application log directories and server configs (e.g., Nginx, App builds) to specific dedicated users and groups (e.g., `www-data:www-data`).
