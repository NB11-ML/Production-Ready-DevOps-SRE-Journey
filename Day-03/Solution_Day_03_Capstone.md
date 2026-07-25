
# 🎓 Day 03 Capstone Challenge: Solutions & Walkthrough

> **Scenario:** You are a DevOps Engineer. A web server is crashing every unit of time. You have terminal access and need to diagnose, count errors, and restart the service.

---

## 📋 The Problem Breakdown
1. Navigate to the Nginx logs.
2. Filter for specific HTTP errors (404 & 500).
3. Count the frequency of these errors using `awk`.
4. Identify the Process ID (PID) of the web server.
5. Kill and restart the service if it is malfunctioning.

---

## 🚀 Step-by-Step Execution

### Step 1: Navigate to logs
**Goal:** Access the directory where Nginx stores its activity records.
```bash
cd /var/log/nginx/
```
*   **Note:** If you get a "Permission Denied" error, it means your user doesn't have rights to that folder. In a real scenario, you might need `sudo -i` or specific group permissions.

### Step 2: Filter errors with `grep`
**Goal:** Isolate the lines we care about (404 and 500 errors).
```bash
grep -E "404|500" access.log
```
*   **Explanation:** 
    *   `-E`: Enables Extended Regular Expressions.
    *   `"404|500"`: The `|` (pipe) symbol acts as an **OR** operator, allowing you to find both error types in one command.

### Step 3: Count errors with `awk`
**Goal:** Instead of listing every line, provide a summary count.
```bash
grep -E "404|500" access.log | awk '{
    if ($9 == "404") count404++; 
    else if ($9 == "500") count500++
} 
END { print "Total 404 Errors: " count404; print "Total 500 Errors: " count500 }'
```
*   **How it works:**
    *   The `grep` pipes the filtered list into `awk`.
    *   `$9`: In a standard Nginx log, the 9th column is usually the HTTP status code.
    *   `count404++`: Every time awk sees "404" in that column, it adds 1 to the variable.
    *   `END`: After reading the whole file, it prints the final totals.

### Step 4: Identify the Process ID (PID)
**Goal:** Find the unique identifier for the running Nginx process.
```bash
ps aux | grep nginx
# OR more specifically:
pgrep -o nginx
```
*   **Explanation:** 
    *   `ps aux`: Lists all running processes.
    *   `grep nginx`: Filters that list to only show things related to "nginx".
    *   `pgrep -o nginx`: Specifically finds the **Oldest** (Master) process of Nginx, which is usually what you want to target for a restart.

### Step 5: Kill and Restart
**Goal:** Stop the hanging process and bring the service back up properly.

1.  **Check resource usage first:**
    ```bash
    top
    ```
2.  **Force kill the process (Replace `[PID]` with the number from Step 4):**
    ```bash
    kill -9 [PID]
    ```
    *   **Note:** `-9` is the "SIGKILL" signal, which forces the OS to stop the process immediately regardless of what it's doing.
3.  **Restart via Systemd (The standard way):**
    ```bash
    sudo systemctl restart nginx
    ```

---

## 📝 Command Summary Cheat Sheet

| Task | Command | Key Logic |
| :--- | :--- | :--- |
| **Navigation** | `cd /var/log/nginx/` | Moving to the correct directory. |
| **Filtering** | `grep -E "404\|500" ...` | Using OR logic to find multiple patterns. |
| **Analysis** | `awk '{...}'` | Processing columns and incrementing counters. |
| **Finding PID** | `pgrep -o nginx` | Identifying the specific process ID. |
| **Force Stop** | `kill -9 [PID]` | Sending a signal to kill a stuck process. |
| **Service Restart** | `systemctl restart nginx` | Using systemd to restart the service properly. |

---
*Completed on Day 03 of the DevOps Learning Path.*
```
