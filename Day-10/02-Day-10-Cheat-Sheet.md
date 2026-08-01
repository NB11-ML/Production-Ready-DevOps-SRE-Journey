
# 🐧 📄 $\color{red}\text{\textbf{Day 10 Cheatsheet:}}$ File Permissions & Operations
---

## 1. Basic File Creation & Viewing Commands

| Command | Action / Usage | Example |
| --- | --- | --- |
| **`touch`** | Create an empty file or update timestamps | `touch devops.txt` |
| **`cat`** | View full file content or write interactively | `cat notes.txt` / `cat > notes.txt` |
| **`head`** | Display the first $N$ lines of a file | `head -n 5 /etc/passwd` |
| **`tail`** | Display the last $N$ lines of a file | `tail -n 5 /etc/passwd` |
| **`view`** / **`vim -R`** | Open a file in **read-only** mode inside Vim | `view script.sh` |
| **`ls -l`** | List files with permissions, ownership, and size | `ls -l` |
| **`ls -ld`** | List directory details (permissions & ownership) | `ls -ld project/` |

---

## 2. Permission Calculation Matrix

Standard Linux permissions follow a 9-character triad string: `rwxrwxrwx` (**User - Group - Others**).

### Binary & Octal Conversion Table

| Permission Symbol | Action | Binary Value | Octal Value |
| --- | --- | --- | --- |
| **`r`** | Read | `100` | **`4`** |
| **`w`** | Write | `010` | **`2`** |
| **`x`** | Execute / Traverse Directory | `001` | **`1`** |
| **`-`** | No Access | `000` | **`0`** |

### Common Production Permission Sets

```text
  755  ===> Owner: rwx (4+2+1=7) | Group: r-x (4+0+1=5) | Others: r-x (4+0+1=5)
  640  ===> Owner: rw- (4+2+0=6) | Group: r-- (4+0+0=4) | Others: --- (0+0+0=0)
  444  ===> Owner: r-- (4+0+0=4) | Group: r-- (4+0+0=4) | Others: r-- (4+0+0=4)

```

| Octal | Symbolic Notation | Description / Common Use Case |
| --- | --- | --- |
| **`755`** | `rwxr-xr-x` | Executable scripts (`script.sh`) and public directories (`project/`) |
| **`644`** | `rw-r--r--` | Standard configuration & text files (`notes.txt`) |
| **`640`** | `rw-r-----` | Restricted files (readable by assigned group only) |
| **`600`** | `rw-------` | Private files (SSH private keys `id_rsa`, secret configs) |
| **`444`** | `r--r--r--` | Read-only files (`devops.txt`) |
| **`700`** | `rwx------` | Isolated private directory or user script execution |

---

## 3. Permission & Ownership Modification (`chmod`, `chown`, `chgrp`)

### Symbolic Mode (`chmod`)

| Command | Description |
| --- | --- |
| `chmod +x script.sh` | Grant **execute** permission to user, group, and others |
| `chmod a-w devops.txt` | Remove **write** permission for all (`a` = all) |
| `chmod u+x,g-w script.sh` | Grant owner execute, remove group write |
| `chmod o-rwx notes.txt` | Revoke all permissions from others |

### Octal Mode (`chmod`)

| Command | Description |
| --- | --- |
| `chmod 755 script.sh` | Set owner=`rwx`, group=`r-x`, others=`r-x` |
| `chmod 640 notes.txt` | Set owner=`rw-`, group=`r--`, others=`---` |
| `chmod 444 devops.txt` | Set file to strictly read-only for all categories |
| `chmod -R 755 project/` | Recursively apply `755` to directory and contents |

### Modifying Ownership (`chown` / `chgrp`)

```bash
# Change file user owner
chown deployer notes.txt

# Change user AND group owner simultaneously
chown -R ubuntu:devops project/

# Change group ownership only
chgrp devops script.sh

```

---

## 4. Special Permissions (SUID, SGID, Sticky Bit)

```text
  Special Bits    User (rwx)    Group (rwx)    Others (rwx)
 ┌────────────┐  ┌──────────┐  ┌───────────┐  ┌───────────┐
 │ 4 / 2 / 1  │  │  r w x   │  │   r w x   │  │   r w x   │
 └─────┬──────┘  └──────────┘  └───────────┘  └───────────┘

```

| Special Bit | Octal Value | Symbolic | Target | Effect | Command Example |
| --- | --- | --- | --- | --- | --- |
| **SUID** | `4000` | `s` (in `u`) | File | Runs process with **file owner** privileges | `chmod 4755 binary` |
| **SGID** | `2000` | `s` (in `g`) | Directory | New files inside **inherit directory group** | `chmod 2775 shared_dir/` |
| **Sticky Bit** | `1000` | `t` (in `o`) | Directory | Only **file owner or root** can delete files | `chmod 1777 /tmp` |

---

## 5. Extended Access Control Lists (ACLs)

Use ACLs when a file/directory requires permissions for multiple specific users or groups.

```bash
# View active ACL entries
getfacl notes.txt

# Grant user 'jenkins' read and write access
setfacl -m u:jenkins:rw notes.txt

# Grant group 'auditors' read access
setfacl -m g:auditors:r notes.txt

# Set default ACLs for all NEW files inside a directory
setfacl -d -m g:devops:rwx project/

# Remove specific user ACL entry
setfacl -x u:jenkins notes.txt

# Strip all extended ACL entries
setfacl -b notes.txt

```

---

## 6. Default Creation Mask (`umask`)

The `umask` controls default permissions for newly created files and directories.

$$\text{Effective Permissions} = \text{Base Permission} - \text{umask}$$

* **Base File Default:** `666` (`rw-rw-rw-`) *(Files never get execute bit by default)*
* **Base Directory Default:** `777` (`rwx-rwx-rwx`)

> [!NOTE]
> * **`umask 022`** $\rightarrow$ New Files: **`644`**, New Directories: **`755`** *(Standard default)*
> * **`umask 027`** $\rightarrow$ New Files: **`640`**, New Directories: **`750`** *(Production hardened default)*
> 
> 

---

## 7. Error Troubleshooting Guide

> [!CAUTION]
> ### 🔴 Common Errors & Fixes
> 
> 

1. **`bash: ./script.sh: Permission denied`**
* **Cause:** Missing execute (`x`) permission on the file.
* **Fix:** `chmod +x script.sh`


2. **`bash: devops.txt: Permission denied`**
* **Cause:** Attempting to write (`>`) or append (`>>`) to a file lacking write (`w`) permission.
* **Fix:** `chmod u+w devops.txt` or `chmod 644 devops.txt`


3. **`cat: notes.txt: Permission denied`**
* **Cause:** Missing read (`r`) permission or missing directory traversal (`x`) on parent path.
* **Fix:** `chmod +r notes.txt` and ensure parent directory has `chmod +x`.
