# Day 18 – Shell Scripting: Functions & Intermediate Concepts

## Task
Write cleaner, reusable scripts — learn functions, strict mode, and real-world patterns.

You will:
- Write and call **functions**
- Use `set -euo pipefail` for safer scripts
- Work with **return values** and **local variables**
- Build an intermediate script

---

## Challenge Tasks

### Task 1: Basic Functions
1. Create `functions.sh` with:
   - A function `greet` that takes a name as an argument and prints `Hello, <name>!`
   - A function `add` that takes two numbers and prints their sum
2. Call both functions from the script.

**Script Code (`functions.sh`):**
```bash
#!/bin/bash
# Description: Demonstrate basic Bash functions and argument passing

greet() {
    echo "Hello, $1!"
}

add() {
    local SUM=$(($1 + $2))
    echo "The sum of $1 and $2 is: $SUM"
}

# Main Execution
echo "=== Calling Basic Functions ==="
greet "NB11ML"
greet "DevOps Engineer"

add 15 25
add 100 45

```

**Execution & Output:**

```bash
$ chmod +x functions.sh
$ ./functions.sh
=== Calling Basic Functions ===
Hello, NB11ML!
Hello, DevOps Engineer!
The sum of 15 and 25 is: 40
The sum of 100 and 45 is: 145

```

<img width="963" height="624" alt="image" src="https://github.com/user-attachments/assets/94e80318-f4e7-48e5-9b31-646f56f68067" />


**Detailed Code Explanation:**

* **Function Arguments:** In Bash, functions don't declare parameters in parentheses like Python. Instead, you pass arguments directly after the function call (`greet "NB11ML"`), and inside the function, they are accessed as positional parameters (`$1`, `$2`, etc.).
* **Arithmetic Evaluation:** The syntax `$(( ... ))` is used to perform mathematical addition before assigning the result to the `SUM` variable.

---

### Task 2: Functions with Return Values

1. Create `disk_check.sh` with:
* A function `check_disk` that checks disk usage of `/` using `df -h`
* A function `check_memory` that checks free memory using `free -h`
* A main section that calls both and prints the results



**Script Code (`disk_check.sh`):**

```bash
#!/bin/bash
# Description: Modular system checks using functions

check_disk() {
    echo "--- Root Disk Usage ---"
    df -h /
}

check_memory() {
    echo "--- System Memory ---"
    free -h
}

# Main Execution
echo "=== Running System Checks ==="
check_disk
echo ""
check_memory

```

**Execution & Output:**

```bash
$ chmod +x disk_check.sh
$ ./disk_check.sh
=== Running System Checks ===
--- Root Disk Usage ---
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   15G   33G  32% /

--- System Memory ---
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       2.1Gi       4.5Gi        50Mi       1.2Gi       5.4Gi
Swap:          2.0Gi          0B       2.0Gi

```

<img width="961" height="628" alt="image" src="https://github.com/user-attachments/assets/bfde867c-8f8a-4991-8f71-d097f52a8e48" />


**Detailed Code Explanation:**

* **Standard Output as Return:** In standard programming languages, functions `return` strings. In Bash, functions `return` exit codes (0-255). To "return" data (like the output of `df` or `free`), functions simply execute commands or use `echo`, which sends the text to standard output (`stdout`) where the main script displays it.

---

### Task 3: Strict Mode — `set -euo pipefail`

Create `strict_demo.sh` to test strict mode flags.

**Script Code (`strict_demo.sh`):**

```bash
#!/bin/bash
# Description: Demonstrating strict mode behaviors. 
# Note: Uncomment one test at a time to see how the script fails.

set -euo pipefail

echo "Strict mode is active."

# --- Test 1: Undefined Variable ---
# echo "Trying to use undefined variable: $UNSET_VAR"

# --- Test 2: Failing Command ---
# ls /directory/that/does/not/exist
# echo "This line will never run if the command above fails."

# --- Test 3: Piped Command Failure ---
# ls /fake/dir | grep "txt"
# echo "This line will never run if the pipe fails."

echo "If you see this, no strict mode rules were broken!"

```

<img width="959" height="637" alt="image" src="https://github.com/user-attachments/assets/b95aede9-acc4-4aca-953b-cbbc40962605" />


**Documentation:**

* **`set -e`** $\rightarrow$ **Exit on Error:** Forces the script to exit immediately if *any* command returns a non-zero exit status (meaning it failed). Without this, Bash will blindly continue to the next line even if a critical command fails.
* **`set -u`** $\rightarrow$ **Exit on Undefined Variable:** Treats unset (uninitialized) variables as errors and exits immediately. This prevents accidental destructive commands like `rm -rf /$MISSING_VAR` (which evaluates to `rm -rf /`).
* **`set -o pipefail`** $\rightarrow$ **Catch Pipe Failures:** By default, Bash only looks at the exit code of the *last* command in a pipe. If `command1 | command2` is run and `command1` fails but `command2` succeeds, Bash considers the whole pipe successful. `pipefail` changes this: if *any* command in the pipeline fails, the whole pipeline fails.

---

### Task 4: Local Variables

Create `local_demo.sh` to demonstrate variable scoping.

**Script Code (`local_demo.sh`):**

```bash
#!/bin/bash
# Description: Demonstrate the difference between global and local variables

# Global Variable
USER_ROLE="Admin"

demo_scope() {
    # Local Variable (Only exists inside this function)
    local INTERNAL_VAR="Secret Data"
    
    # Modifying the Global Variable
    USER_ROLE="Guest"
    
    echo "Inside function: INTERNAL_VAR = $INTERNAL_VAR"
    echo "Inside function: USER_ROLE = $USER_ROLE"
}

echo "Before function: USER_ROLE = $USER_ROLE"

demo_scope

echo "After function: USER_ROLE = $USER_ROLE"
echo "After function: INTERNAL_VAR = $INTERNAL_VAR (Notice this is blank!)"

```

**Execution & Output:**

```bash
$ chmod +x local_demo.sh
$ ./local_demo.sh
Before function: USER_ROLE = Admin
Inside function: INTERNAL_VAR = Secret Data
Inside function: USER_ROLE = Guest
After function: USER_ROLE = Guest
After function: INTERNAL_VAR =  (Notice this is blank!)

```

<img width="962" height="667" alt="image" src="https://github.com/user-attachments/assets/6ace42ec-c489-40e7-bb33-f2eef9657fb2" />


**Detailed Code Explanation:**

* **Global by Default:** Variables in Bash are completely global by default, even if declared inside a function. Notice how `USER_ROLE` changed from "Admin" to "Guest" globally after the function ran.
* **`local` Keyword:** Prepending `local` restricts the variable to that function's scope. `INTERNAL_VAR` completely disappears once the function finishes executing.

---

### Task 5: Build a Script — System Info Reporter

Create `system_info.sh` that uses strict mode, functions for everything, and clean formatting.

**Script Code (`system_info.sh`):**

```bash
#!/bin/bash
# Description: Comprehensive System Information Reporter

set -euo pipefail

print_os_info() {
    echo "=== 🖥️  Hostname & OS Info ==="
    echo "Hostname: $(hostname)"
    # Extract PRETTY_NAME from os-release to get a clean OS string
    grep "^PRETTY_NAME=" /etc/os-release | cut -d '"' -f 2
    echo ""
}

print_uptime() {
    echo "=== ⏱️  System Uptime ==="
    uptime -p
    echo ""
}

print_disk_usage() {
    echo "=== 💾 Top 5 Disk Partitions (By Size) ==="
    # Print header, then sort by size (column 2) in reverse human-readable format
    df -h | head -n 1
    df -h | sed '1d' | sort -hr -k 2 | head -n 5
    echo ""
}

print_memory() {
    echo "=== 🧠 Memory Usage ==="
    free -h
    echo ""
}

print_top_cpu() {
    echo "=== 🔥 Top 5 CPU-Consuming Processes ==="
    # Show PID, User, %CPU, %MEM, and Command, sorted by %CPU
    ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6
    echo ""
}

main() {
    echo "========================================="
    echo "       SYSTEM INFORMATION REPORT         "
    echo "       Generated: $(date +'%Y-%m-%d')      "
    echo "========================================="
    echo ""
    
    print_os_info
    print_uptime
    print_disk_usage
    print_memory
    print_top_cpu
    
    echo "========================================="
    echo "          REPORT COMPLETE                "
    echo "========================================="
}

# Execute main block
main

```

**Execution & Output:**

```text
$ chmod +x system_info.sh
$ ./system_info.sh
=========================================
       SYSTEM INFORMATION REPORT         
       Generated: 2026-08-09      
=========================================

=== 🖥️  Hostname & OS Info ===
Hostname: primaryvm
Ubuntu 22.04.3 LTS

=== ⏱️  System Uptime ===
up 3 days, 14 hours, 22 minutes

=== 💾 Top 5 Disk Partitions (By Size) ===
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   15G   33G  32% /
/dev/sdb1        20G  5.0G   15G  25% /mnt/data
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           3.9G  1.2M  3.9G   1% /run
tmpfs           798M     0  798M   0% /run/user/1000

=== 🧠 Memory Usage ===
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       2.1Gi       4.5Gi        50Mi       1.2Gi       5.4Gi
Swap:          2.0Gi          0B       2.0Gi

=== 🔥 Top 5 CPU-Consuming Processes ===
    PID USER     %CPU %MEM COMMAND
   1452 root     12.4  2.1 dockerd
   3891 user      4.2  5.4 node
    901 root      1.5  0.8 containerd
    110 root      0.3  0.1 kworker/0:2
   4420 user      0.1  0.2 bash

=========================================
          REPORT COMPLETE                
=========================================

```

<img width="960" height="1016" alt="image" src="https://github.com/user-attachments/assets/8382fa77-0971-4215-83bb-dde7a21e7a4f" />


**Detailed Code Explanation:**

* **Pipeline sorting (`df -h | sed '1d' | sort -hr -k 2 | head -n 5`)**: We use `sed '1d'` to strip the column headers from `df -h` before sorting so they don't end up at the bottom of the list. `sort -hr -k 2` sorts the output in **h**uman-readable, **r**everse format based on the 2nd column (`Size`).
* **Process filtering (`ps --sort=-%cpu`)**: The `-` sign before `%cpu` tells the `ps` command to sort in descending order natively, making it extremely efficient to pipe into `head -n 6` (which grabs the header + top 5 processes).
* **`main()` Wrapping:** Encapsulating all function calls inside a `main()` function is a professional scripting pattern. It ensures the script logic is parsed completely before execution begins, avoiding top-to-bottom execution order bugs.

```

```
