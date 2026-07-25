# 🐧 Day 03: Linux Administration & Command Line Mastery

> **Objective:** Master the Linux filesystem, user permissions, process management, and text processing—the core pillars of a DevOps Engineer.

---

## 🏗️ Module 1: Navigation & File System Hierarchy (FHS)
*Understanding where things are located is crucial for debugging.*

### Key Concepts:
*   **Root Directory (`/`):** The top-level directory.
*   **`/etc`**: Configuration files (e.g., `/etc/passwd`, `/etc/hosts`).
*   **`/var`**: Variable data (logs, databases).
*   **`/bin` & `/usr/bin`**: Executable binaries.

### 🛠️ Practice Tasks:
1.  **Navigation:** Use `pwd` to find your current location. Move into `/etc`, then move back to home using `cd ~`.
2.  **Directory Tree:** Create a nested structure: `mkdir -p project/data/logs`.
3.  **File Creation:** Create an empty file named `config.txt` in the `project` folder using `touch`.
4.  **Copy & Move:** 
    *   Copy `config.txt` to `project/data/` as `backup_config.txt`.
    *   Move `backup_config.txt` into the `logs` folder.

---

## 🔐 Module 2: Permissions and Ownership
*Security is the most important part of DevOps.*

### Key Concepts:
*   **Permissions:** Read (r=4), Write (w=2), Execute (x=1).
*   **Ownership:** User, Group, Others.
*   **Sticky Bit/SUID:** Special permissions for shared directories.

### 🛠️ Practice Tasks:
1.  **Identify Permissions:** Run `ls -l` on a directory and identify which parts of the string (e.g., `-rwxr-xr--`) represent User, Group, and Others.
2.  **Change Mode:** Create a script called `test_script.sh`. 
    *   Make it executable using `chmod +x test_script.sh`.
    *   Restrict the file so only the owner can read/write it: `chmod 600 test_script.sh`.
3.  **Change Owner:** (Requires sudo) Change the owner of a folder to a specific user using `chown`.

> **💡 Challenge:** "Create a directory called `/opt/shared_data`. Set permissions so that members of the group 'developers' can read and write, but others cannot."

---

## 🔍 Module 3: Text Processing & Filtering
*DevOps is often about parsing logs and extracting data.*

### Key Tools: `grep`, `awk`, `sed`, `find`
1.  **Grep:** Find every line containing the word "ERROR" in a log file:
    ```bash
    grep -i "error" /var/log/syslog
    ```
2.  **Find:** Locate all `.log` files in the `/var/log` directory:
    ```bash
    find /var/log -name "*.log"
    ```
3.  **Awk:** Print only the first and third columns of a file:
    ```bash
    awk '{print $1, $3}' data_file.txt
    ```
4.  **Sed:** Replace all occurrences of "localhost" with "127.0.0.1" in a configuration file:
    ```bash
    sed -i 's/localhost/127.0.0.1/g' config.conf
    ```

### 🛠️ Practice Tasks:
*   Find all files larger than 10MB in `/var`.
*   Count how many times the word "Failed" appears in a log file.
*   Sort a list of IP addresses and remove duplicates (`sort | uniq`).

---

## ⚙️ Module 4: Process & System Monitoring
*If the server is slow, you need to know why.*

### Key Commands: `top`, `htop`, `ps`, `kill`
1.  **Identify Processes:** Use `ps aux | grep python` to find all running Python processes.
2.  **Monitor Resources:** Run `top` (or `htop`) and identify the process consuming the most CPU.
3.  **Terminate:** Find a "zombie" or stuck process and kill it using its PID: `kill -9 <PID>`.
4.  **Load Average:** Check the system load average via `uptime`.

---

## 🌐 Module 5: Networking Basics (Linux Context)
*Understanding how your server talks to the world.*

### Key Commands: `ip`, `netstat`, `curl`, `nslookup`
1.  **IP Address:** Use `ip addr show` to find your local IP.
2.  **Port Checking:** Check if a port (e.g., 80 or 443) is listening: `netstat -tuln`.
3.  **Connectivity:** Use `curl -I http://google.com` to check headers of a website.
4.  **DNS Lookups:** Use `nslookup` or `dig` to find the IP of a domain name.

---

## 🎓 Final "Day 03" Capstone Challenge
**Scenario:** You are a DevOps Engineer. A web server is crashing every hour. You are given access to the terminal.

1.  Log into the server and navigate to `/var/log/nginx/`.
2.  Find all lines in `access.log` that contain "404" or "500" errors using `grep`.
3.  Count how many times each error code appeared using `awk`.
4.  Identify the process ID (PID) of the web server.
5.  If it's taking too much memory, kill the process and restart it.

---

## 📝 Cheat Sheet Summary
| Category | Action | Command Example |
| :--- | :--- | :--- |
| **Navigation** | Find path / Change Dir | `pwd`, `cd` |
| **File Ops** | Create / Copy / Move | `touch`, `cp`, `mv`, `rm -rf` |
| **Permissions** | Update Rights/Owner | `chmod`, `chown` |
| **Search** | Find files / text patterns | `find`, `grep` |
| **Text Processing** | Filter / Replace / Sort | `awk`, `sed`, `sort`, `uniq` |
| **System Info** | CPU / Memory / Disk | `top`, `free -m`, `df -h` |
| **Networking** | IP / Ports / DNS | `ip addr`, `netstat`, `curl`, `dig` |
