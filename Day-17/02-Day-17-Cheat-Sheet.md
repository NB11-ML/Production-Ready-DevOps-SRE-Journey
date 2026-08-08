# 🚀 Shell Scripting Cheat Sheet: Loops, Arguments & Error Handling

---

## 1. Special Bash Variables

| Variable | Description | Practical Example |
| --- | --- | --- |
| **`$0`** | Name of the executing script | `echo "Running $0"` |
| **`$1` - `$9**` | Positional command-line arguments | `NAME=$1` |
| **`$#`** | Total number of arguments passed | `if [ "$#" -lt 1 ]; then ... fi` |
| **`$@`** | Array of all arguments individually quoted | `for arg in "$@"; do ... done` |
| **`$?`** | Exit status of the last executed command (`0` = Success) | `if [ $? -eq 0 ]; then ... fi` |
| **`$EUID`** | Effective User ID (`0` = root, `1000+` = regular user) | `if [ "$EUID" -ne 0 ]; then ... fi` |
| **`$$`** | Process ID (PID) of the running script | `echo "PID: $$"` |

---

## 2. Loops Reference

### 🔄 `for` Loops

#### Array Iteration

```bash
FRUITS=("Apple" "Banana" "Mango")

for FRUIT in "${FRUITS[@]}"; do
    echo "Fruit: $FRUIT"
done

```

#### Range Iteration

```bash
# Loop numbers 1 through 10
for NUM in {1..10}; do
    echo "Count: $NUM"
done

```

#### Command Output Iteration

```bash
for FILE in $(ls *.sh); do
    echo "Found script: $FILE"
done

```

---

### ⏳ `while` Loops

#### Condition-Based Loop (Countdown Example)

```bash
COUNT=5

while [ "$COUNT" -ge 0 ]; do
    echo "T-minus $COUNT"
    COUNT=$((COUNT - 1))
    sleep 1
done

echo "Lift off!"

```

---

## 3. Test & Condition Operators

### 🔤 String Comparison Operators

| Operator | Condition Evaluated | Example |
| --- | --- | --- |
| **`-z "$1"`** | True if string is **empty** / zero length | `if [ -z "$1" ]; then ... fi` |
| **`-n "$1"`** | True if string is **not empty** | `if [ -n "$1" ]; then ... fi` |
| **`"="`** | True if strings are **equal** | `if [ "$STR" = "yes" ]; then ... fi` |
| **`"!="`** | True if strings are **not equal** | `if [ "$STR" != "yes" ]; then ... fi` |

---

### 📁 File Test Operators

| Operator | Condition Evaluated | Example |
| --- | --- | --- |
| **`-f file`** | True if path exists and is a **regular file** | `if [ -f "/etc/hosts" ]; then ... fi` |
| **`-d dir`** | True if path exists and is a **directory** | `if [ -d "/tmp/devops" ]; then ... fi` |
| **`-s file`** | True if file exists and **is NOT empty** (> 0 bytes) | `if [ -s "log.txt" ]; then ... fi` |

---

### 🔢 Numeric Comparison Operators

| Operator | Description | Example |
| --- | --- | --- |
| **`-eq`** | Equal to | `[ "$A" -eq "$B" ]` |
| **`-ne`** | Not equal to | `[ "$A" -ne "$B" ]` |
| **`-gt`** | Greater than | `[ "$A" -gt 0 ]` |
| **`-lt`** | Less than | `[ "$A" -lt 10 ]` |
| **`-ge`** | Greater than or equal to | `[ "$A" -ge 0 ]` |
| **`-le`** | Less than or equal to | `[ "$A" -le 100 ]` |

---

## 4. Error Handling & Defensive Scripting

### 🛡️ Essential Safety Directives

Put these settings at the top of production scripts:

```bash
#!/bin/bash

# Stop script execution immediately if any command returns a non-zero exit code
set -e

# Treat unset variables as an error and exit immediately
set -u

# Prevent errors in piped commands from being masked
set -o pipefail

```

> **Debugging Tip:** Add `set -x` to print every line as it executes for active debugging.

---

### 🔗 Logical Control Operators (`&&` and `||`)

```bash
# Execute command 2 ONLY if command 1 succeeds (AND)
mkdir /tmp/test && cd /tmp/test

# Execute fallback command ONLY if primary command fails (OR)
mkdir /tmp/test || echo "Directory creation failed or already exists"

```

---

### 🔑 Root Privilege Verification Pattern

```bash
if [ "$EUID" -ne 0 ]; then
    echo "Error: Superuser permissions required." >&2
    echo "Usage: sudo $0" >&2
    exit 1
fi

```

---

## 5. Input / Output & Silence Tricks

### Output Redirection Cheat Sheet

```bash
# Redirect standard output (stdout) to null
command > /dev/null

# Redirect errors (stderr) to null
command 2> /dev/null

# Redirect BOTH stdout and stderr to null (Silent mode)
command &> /dev/null
# OR
command > /dev/null 2>&1

```

---

## 6. Package Verification & Automation Pattern

```bash
PACKAGES=("nginx" "curl" "wget")

# 1. Run update ONCE before looping
apt-get update -qq

# 2. Check and install missing dependencies
for PKG in "${PACKAGES[@]}"; do
    if dpkg -s "$PKG" &> /dev/null; then
        echo "[EXISTS] $PKG"
    else
        echo "[INSTALLING] $PKG..."
        apt-get install -y "$PKG" &> /dev/null && echo "[SUCCESS] $PKG installed" || echo "[ERROR] Failed to install $PKG"
    fi
done

```

---

## 7. Useful Troubleshooting & Recovery Commands

| Problem | Fix Command |
| --- | --- |
| **System clock out of sync (WSL)** | `sudo hwclock -s` |
| **Interrupted `dpkg` / broken installs** | `sudo dpkg --configure -a` |
| **Fix missing dependencies** | `sudo apt-get install -f` |
| **Clear APT background locks** | `sudo killall apt apt-get` |
