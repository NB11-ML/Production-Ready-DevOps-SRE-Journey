# 🐧 Linux File Operations & I/O Cheat Sheet

## 1. File & Directory Creation

| Task | Command | Example |
| --- | --- | --- |
| **Create empty file(s)** | `touch <file>` | `touch app.log config.json` |
| **Create directory tree** | `mkdir -p <path>` | `mkdir -p /tmp/app_logs/archive` |
| **Create multiple files** | `touch {file1,file2}` | `touch /tmp/app_logs/{access,error,system}.log` |
| **View file content** | `cat <file>` | `cat /etc/hosts` |
| **View with line numbers** | `cat -n <file>` | `cat -n server.log` |
| **View page by page** | `less <file>` | `less /var/log/syslog` *(Press `q` to exit)* |

---

## 2. Input/Output (I/O) Redirection

| Operator | Stream | Description | Example |
| --- | --- | --- | --- |
| **`>`** | `stdout` | Overwrite destination with command output | `date > timestamp.txt` |
| **`>>`** | `stdout` | Append command output to destination | `uptime >> timestamp.txt` |
| **`2>`** | `stderr` | Redirect error output only | `ls /fake_dir 2> error.log` |
| **`2>>`** | `stderr` | Append error output only | `command 2>> error.log` |
| **`&>`** | `stdout` + `stderr` | Redirect both standard output & errors | `command &> combined.log` |
| **`2>&1`** | `stderr` to `stdout` | Legacy way to combine streams | `command > log.txt 2>&1` |
| **`|`** | Pipe | Pass output of Command 1 as input to Command 2 | `cat server.log | grep "ERROR"` |

---

## 3. File Permissions (`chmod`)

### Permission Key

* **`r`** = Read (4)
* **`w`** = Write (2)
* **`x`** = Execute (1)
* **`u`** = User/Owner | **`g`** = Group | **`o`** = Others | **`a`** = All

### Numeric (Octal) Mode Calculator

$$7 = 4 + 2 + 1 \quad \text{(Read, Write, Execute)}$$

$$6 = 4 + 2 + 0 \quad \text{(Read, Write)}$$

$$5 = 4 + 0 + 1 \quad \text{(Read, Execute)}$$

$$4 = 4 + 0 + 0 \quad \text{(Read Only)}$$

### Common Permission Patterns

```bash
# 777 - Full permissions to everyone (UNSECURE!)
chmod 777 script.sh

# 755 - Owner: Full | Group & Others: Read + Execute (Standard for scripts)
chmod 755 deploy.sh

# 644 - Owner: Read/Write | Group & Others: Read-only (Standard for files)
chmod 644 config.txt

# 600 - Owner: Read/Write | Group & Others: No access (Standard for SSH keys/secrets)
chmod 600 id_rsa

```

### Symbolic Mode Examples

```bash
chmod u+x script.sh     # Add execute for user
chmod g-w file.txt      # Remove write from group
chmod o-rw file.txt     # Remove read and write from others
chmod a+r file.txt      # Add read for all (user, group, others)

```

---

## 4. File Ownership (`chown`)

```bash
# Change owner only
sudo chown john app.log

# Change group only
sudo chown :devops app.log

# Change owner AND group
sudo chown john:devops app.log

# Change owner & group recursively across a folder
sudo chown -R john:devops /var/www/html

```

---

## 5. Hard Links vs. Soft Links

| Property | Soft Link (Symlink) | Hard Link |
| --- | --- | --- |
| **Command** | `ln -s target link_name` | `ln target link_name` |
| **Pointer** | Points to file **path** | Points to file **inode** |
| **Target Deleted?** | Link breaks (Dangling reference) | Link stays valid with original data |
| **Across Filesystems?** | Yes | No |

```bash
# Create Symbolic Link
ln -s /var/log/syslog ~/current_syslog

# Create Hard Link
ln /var/log/syslog ~/syslog_hardlink

```

---

## 6. Real-World DevOps Snippets

```bash
# 1. Create a secure private log file
touch /var/log/app.log && chmod 600 /var/log/app.log

# 2. Append timestamped deployment log
echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Deployment successful" >> /var/log/app.log

# 3. Mute all output (discard standard output & errors)
./noisy_script.sh > /dev/null 2>&1

# 4. Recursively fix directory vs file permissions
find /var/www/html -type d -exec chmod 755 {} +
find /var/www/html -type f -exec chmod 644 {} +

```
