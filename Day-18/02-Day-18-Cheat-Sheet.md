# 🚀 Day 18 Cheat Sheet: Bash Functions & Intermediate Scripting

---

## 1. 🏗️ Bash Functions Syntax & Usage

### Basic Function Declaration

In Bash, you define functions without declaring parameters in parentheses.

```bash
my_function() {
    # Commands go here
    echo "Executing function..."
}

```

### Passing Arguments to Functions

Arguments are passed by listing them after the function call, separated by spaces. Inside the function, they are accessed as positional parameters (`$1`, `$2`, etc.).

```bash
greet() {
    echo "Hello, $1!"
}

# Invocation
greet "NB11ML"

```

### "Returning" Values

Unlike Python or Java, Bash functions **return exit codes** (`0-255`), not strings. To return data, you echo it to standard output (`stdout`).

```bash
add() {
    local SUM=$(($1 + $2)) # $(( ... )) evaluates math
    echo $SUM              # Outputs data to stdout
}

RESULT=$(add 10 20)        # Captures stdout into a variable

```

---

## 2. 🛡️ Strict Mode (`set -euo pipefail`)

Place this at the very top of your production scripts (right under the `#!/bin/bash` shebang) to make them fail safely instead of wreaking havoc.

| Flag | Name | What it does |
| --- | --- | --- |
| **`set -e`** | **Exit on Error** | Stops the script immediately if *any* command fails (returns a non-zero exit code). |
| **`set -u`** | **Exit on Unset** | Stops the script immediately if you try to use an undefined/uninitialized variable. |
| **`set -o pipefail`** | **Pipe Failure Catch** | Forces the whole pipeline to fail if *any* command in it fails. (By default, Bash only checks the last command). |

---

## 3. 📦 Variable Scopes (Global vs. Local)

By default, **all variables in Bash are global**, even if created inside a function.

To restrict a variable's scope to the inside of a function, use the `local` keyword. This prevents accidentally overwriting variables elsewhere in your script.

```bash
GLOBAL_VAR="I exist everywhere"

secure_function() {
    local SECRET_VAR="I only exist inside this function"
    GLOBAL_VAR="I was overwritten!"
}

```

---

## 4. 🧰 Command Pipelines & Text Processing

### Extracting Specific Values (`grep` & `cut`)

```bash
# Get the clean OS name from /etc/os-release
grep "^PRETTY_NAME=" /etc/os-release | cut -d '"' -f 2

```

* **`^`**: Regex anchor meaning "Start of the line".
* **`cut -d '"'`**: Splits the string using double-quotes as the delimiter.
* **`-f 2`**: Grabs the 2nd field/piece after the cut.

### Removing Headers (`sed`)

```bash
# Delete the first line of an output stream
df -h | sed '1d' 

```

### Advanced Sorting (`sort`)

```bash
# Sort disk sizes like 50G and 800M correctly
sort -hr -k 2

```

* **`-h`**: Human-readable (understands G, M, K).
* **`-r`**: Reverse order (descending / largest first).
* **`-k 2`**: Sort based on the 2nd column.

---

## 5. 🖥️ System Information Commands

| Objective | Command | Explanation |
| --- | --- | --- |
| **Uptime** | `uptime -p` | Prints system uptime in a clean, human-readable format. |
| **Disk Usage** | `df -h /` | Shows disk space on the root (`/`) filesystem in GB/MB. |
| **Memory** | `free -h` | Displays total, used, free, and cached RAM. |
| **Processes** | `ps -eo pid,user,%cpu,%mem,comm` | `ps`: Process snapshot.<br>

<br>`-e`: Every process on the system.<br>

<br>`-o`: Custom output format specifying exactly which columns to show. |
| **Sorting ps** | `ps --sort=-%cpu` | Native way to sort processes by CPU usage descending (`-` means reverse). |

---

## 💡 Pro-Tip: The `main` Function Wrapper

A best practice in bash scripting is to wrap your core logic in a `main()` function and call it at the very bottom. This ensures all functions are fully parsed into memory before execution begins!

```bash
#!/bin/bash
set -euo pipefail

# ... define all functions up here ...

main() {
    check_disk
    check_memory
}

main "$@" # Start execution here!

```
