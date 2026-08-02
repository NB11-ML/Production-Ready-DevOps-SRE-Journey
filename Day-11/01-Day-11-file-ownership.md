# 🐧 Day 11 – File Ownership Challenge (chown & chgrp)

## Task Overview
Master file and directory ownership in Linux by learning how user and group permissions work, performing owner/group updates using `chown` and `chgrp`, and applying changes recursively across directories.

---

## Task 1: Understanding Ownership

### Concept Explanation
When running `ls -l`, file permissions and ownership are displayed in the following format:

```text
-rw-r--r-- 1 owner group size date filename

```

* **Owner (User):** The specific Linux user account that owns the file. The owner has dedicated permissions defined in the first permissions triplet (`rw-`).
* **Group:** A collection of Linux users who share common access permissions defined in the second permissions triplet (`r--`).
* **Difference:** An **Owner** is an individual user who typically created the file or was assigned control over it. A **Group** allows multiple users to share a set of read/write/execute rights to a file without granting those rights to everyone else on the system ("Others").

### Verification

```bash
ls -l ~

```

---

## Files & Directories Created

The following resources were created during this challenge:

* `devops-file.txt`
* `team-notes.txt`
* `project-config.yaml`
* `app-logs/` (directory)
* `heist-project/` (directory)
* `heist-project/vault/gold.txt`
* `heist-project/plans/strategy.conf`


* `bank-heist/` (directory)
* `bank-heist/access-codes.txt`
* `bank-heist/blueprints.pdf`
* `bank-heist/escape-plan.txt`



---

## Ownership Changes Summary

| File / Directory | Initial Ownership | Final Ownership | Command Used |
| --- | --- | --- | --- |
| `devops-file.txt` | `ubuntu:ubuntu` | `berlin:ubuntu` | `sudo chown berlin devops-file.txt` |
| `team-notes.txt` | `ubuntu:ubuntu` | `ubuntu:heist-team` | `sudo chgrp heist-team team-notes.txt` |
| `project-config.yaml` | `ubuntu:ubuntu` | `professor:heist-team` | `sudo chown professor:heist-team project-config.yaml` |
| `app-logs/` | `ubuntu:ubuntu` | `berlin:heist-team` | `sudo chown berlin:heist-team app-logs/` |
| `heist-project/` (Recursive) | `ubuntu:ubuntu` | `professor:planners` | `sudo chown -R professor:planners heist-project/` |
| `bank-heist/access-codes.txt` | `ubuntu:ubuntu` | `tokyo:vault-team` | `sudo chown tokyo:vault-team bank-heist/access-codes.txt` |
| `bank-heist/blueprints.pdf` | `ubuntu:ubuntu` | `berlin:tech-team` | `sudo chown berlin:tech-team bank-heist/blueprints.pdf` |
| `bank-heist/escape-plan.txt` | `ubuntu:ubuntu` | `nairobi:vault-team` | `sudo chown nairobi:vault-team bank-heist/escape-plan.txt` |

---

## Challenge Tasks & Execution

### Prerequisites: User & Group Setup

```bash
sudo useradd tokyo
sudo useradd berlin
sudo useradd professor
sudo useradd nairobi
sudo groupadd heist-team
sudo groupadd planners
sudo groupadd vault-team
sudo groupadd tech-team

```
<img width="719" height="224" alt="image" src="https://github.com/user-attachments/assets/94daa5ea-7079-4364-b82a-7622109bcfbe" />

---

### Task 2: Basic chown Operations

```bash
# Create file
touch devops-file.txt
ls -l devops-file.txt

# Change owner to tokyo
sudo chown tokyo devops-file.txt
ls -l devops-file.txt

# Change owner to berlin
sudo chown berlin devops-file.txt
ls -l devops-file.txt

```

<img width="740" height="224" alt="image" src="https://github.com/user-attachments/assets/843ee540-35a4-46b6-a6c4-80faefc88897" />

### Task 3: Basic chgrp Operations

```bash
# Create file
touch team-notes.txt
ls -l team-notes.txt

# Change group to heist-team
sudo chgrp heist-team team-notes.txt
ls -l team-notes.txt

```

<img width="806" height="173" alt="image" src="https://github.com/user-attachments/assets/55661e4d-aae8-4eb6-969e-cda14de6ee94" />


### Task 4: Combined Owner & Group Change

```bash
# File combined ownership
touch project-config.yaml
sudo chown professor:heist-team project-config.yaml

# Directory combined ownership
mkdir app-logs
sudo chown berlin:heist-team app-logs/

```

<img width="863" height="243" alt="image" src="https://github.com/user-attachments/assets/23e90f4a-7266-4bdb-b5de-94559533c8b9" />


### Task 5: Recursive Ownership

```bash
# Create directory tree
mkdir -p heist-project/vault
mkdir -p heist-project/plans
touch heist-project/vault/gold.txt
touch heist-project/plans/strategy.conf

# Recursive update
sudo chown -R professor:planners heist-project/

# Verify recursive changes
ls -lR heist-project/

```

<img width="841" height="376" alt="image" src="https://github.com/user-attachments/assets/d854272b-1b61-48b5-9fcb-80142ff874db" />


### Task 6: Practice Challenge

```bash
# Create directory and target files
mkdir bank-heist
touch bank-heist/access-codes.txt
touch bank-heist/blueprints.pdf
touch bank-heist/escape-plan.txt

# Apply individual ownership requirements
sudo chown tokyo:vault-team bank-heist/access-codes.txt
sudo chown berlin:tech-team bank-heist/blueprints.pdf
sudo chown nairobi:vault-team bank-heist/escape-plan.txt

# Final verification
ls -l bank-heist/

```

<img width="837" height="277" alt="image" src="https://github.com/user-attachments/assets/4ba07a0f-e61c-4dd5-8938-7544494d8dc7" />


---

## Key Commands Reference

```bash
# View file ownership details
ls -l filename

# Change owner only
sudo chown newowner filename

# Change group only
sudo chgrp newgroup filename

# Change both owner and group simultaneously
sudo chown owner:group filename

# Change group only using chown syntax
sudo chown :groupname filename

# Recursively change ownership for a directory and all nested content
sudo chown -R owner:group directory/

```

---

## What I Learned

1. **User vs. Group Scoping:** `chown` dictates user-level control over a file, while `chgrp` assigns collaborative group rights. Combining them with `chown user:group` streamlines access management into a single operation.
2. **Recursive Management (`-R`):** Applying `-R` ensures that nested subdirectories and files automatically inherit permission updates, preventing orphaned or inaccessible files deeper in application trees.
3. **DevOps Security Relevance:** Real-world containerized environments, log managers, and web servers (like Nginx/Apache) rely heavily on correct user/group ownership (`e.g., www-data`) to function safely without requiring risky root privileges.

---
