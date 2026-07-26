
# 🚀 Linux DevOps Quick Reference Cheat Sheet

A handy guide for essential Linux commands used daily in DevOps, CI/CD pipelines, system administration, and troubleshooting.

---

## 🛠️ 1. File & Directory Navigation
```bash
pwd                        # Print current working directory path
ls -la                     # List all files (including hidden) with detailed permissions
cd /path/to/dir            # Change directory
cd ..                      # Move up one directory level
cd ~                       # Navigate to user's home directory
mkdir -p devops/project    # Create nested directories in one command
rm -rf folder_name         # Forcefully & recursively delete a directory (Use with caution!)

```

---

## 📄 2. File Inspection & Manipulation

```bash
touch file.txt             # Create an empty file or update timestamp
cat file.txt               # Display complete file content
less file.txt              # View large files page-by-page (Q to exit)
head -n 20 file.txt        # Output first 20 lines
tail -n 20 file.txt        # Output last 20 lines
tail -f /var/log/app.log   # Stream live log output in real-time
cp -r src_dir/ dest_dir/   # Copy directory recursively
mv old_name.txt new_name   # Move or rename file/directory

```

---

## 🔒 3. Permissions & Ownership

```bash
chmod 755 script.sh        # Owner: rwx | Group: r-x | Others: r-x
chmod +x script.sh         # Grant execute permission to everyone
chmod 600 id_rsa           # Secure private key (Read/Write for owner only)
chown user:group file.txt  # Change file ownership and group

```

> **Permission Value Reference:**
> `4 = Read (r)` | `2 = Write (w)` | `1 = Execute (x)`
> *Example:* `7 (4+2+1)` = full access, `5 (4+0+1)` = read + execute, `0` = no access.

---

## 🔍 4. Text Processing & Search

```bash
grep -i "error" app.log    # Case-insensitive search for string "error"
grep -r "API_KEY" ./src    # Recursively search for string across directory files
find /var/log -name "*.log"# Find files by name pattern
awk '{print $1, $4}' log   # Extract specific columns (1st and 4th) from formatted text
sed -i 's/foo/bar/g' file  # Find and replace "foo" with "bar" in-place inside file
wc -l file.txt             # Count total lines in a file

```

---

## ⚡ 5. System Health & Performance

```bash
df -h                      # Display disk space usage in human-readable format
du -sh /var/log/*          # Show total storage size used by files in directory
free -h                    # Check available, used, and free RAM
uptime                     # System uptime and load averages (1, 5, 15 min)
top                        # Live real-time process manager
htop                       # Interactive, colorized process viewer (if installed)

```

---

## ⚙️ 6. Process Management

```bash
ps aux                     # List all running processes on the system
ps aux | grep nginx        # Filter running processes for "nginx"
pgrep node                 # Output process ID (PID) of running service
kill -9 <PID>              # Forcefully terminate process by ID
killall python             # Kill all running processes named "python"

```

---

## 🌐 7. Networking & Connectivity

```bash
ping google.com            # Test connectivity to host
curl -I [https://example.com](https://example.com)# Fetch HTTP headers of URL
netstat -tulpn             # List all open ports and listening services
ss -tulpn                  # Modern alternative to netstat for active socket listening
ip a                       # Show all network interfaces and assigned IP addresses
nc -zv 127.0.0.1 8080      # Test if specific host port is reachable (Netcat)

```

---

## 🔀 8. Redirection & Piping Operators

```bash
cmd > file.txt             # Redirect standard output to file (Overwrites)
cmd >> file.txt            # Append standard output to file
cmd1 | cmd2                # Pipe output of cmd1 as input to cmd2
cmd 2> error.log           # Redirect only errors (stderr) to file
cmd > output.log 2>&1      # Redirect both stdout and stderr to same file

```

---
