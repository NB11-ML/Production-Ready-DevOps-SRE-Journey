# 🐧 Day 17 – Shell Scripting: Loops, Arguments & Error Handling

## Task
Level up your scripting — use loops, handle command-line arguments, and manage errors gracefully.

You will:
- Write `for` and `while` loops
- Use command-line arguments (`$1`, `$2`, `$#`, `$@`, `$0`)
- Write automated package installation scripts
- Add basic error handling (`set -e`, `$EUID` checks, and `||` fallbacks)

---

## Challenge Tasks

### Task 1: For Loop

#### 1. Fruit Loop (`for_loop.sh`)
Loops through a list of 5 fruits and prints each one.

**Script Code (`for_loop.sh`):**
```bash
#!/bin/bash
# Description: Loop through a list of fruits

FRUITS=("Apple" "Banana" "Cherry" "Mango" "Orange")

for FRUIT in "${FRUITS[@]}"; do
    echo "Fruit: $FRUIT"
done

```

**Execution & Output:**

```bash
$ chmod +x for_loop.sh
$ ./for_loop.sh
Fruit: Apple
Fruit: Banana
Fruit: Cherry
Fruit: Mango
Fruit: Orange

```

<img width="779" height="445" alt="image" src="https://github.com/user-attachments/assets/768c96a2-6c55-400e-b7bf-0ae2976a12e8" />


#### 2. Number Counter (`count.sh`)

Prints numbers from 1 to 10 using a `for` loop.

**Script Code (`count.sh`):**

```bash
#!/bin/bash
# Description: Print numbers 1 to 10 using a for loop

for NUM in {1..10}; do
    echo "Number: $NUM"
done

```

**Execution & Output:**

```bash
$ chmod +x count.sh
$ ./count.sh
Number: 1
Number: 2
Number: 3
Number: 4
Number: 5
Number: 6
Number: 7
Number: 8
Number: 9
Number: 10

```

<img width="780" height="471" alt="image" src="https://github.com/user-attachments/assets/d87966c7-87b1-4b06-8ea8-05b6d3c72118" />


---

### Task 2: While Loop

#### Countdown Script (`countdown.sh`)

Takes a number from the user, counts down to 0 using a `while` loop, and prints "Done!" at the end.

**Script Code (`countdown.sh`):**

```bash
#!/bin/bash
# Description: Countdown timer using a while loop

read -p "Enter starting number: " COUNT

while [ "$COUNT" -ge 0 ]; do
    echo "$COUNT"
    COUNT=$((COUNT - 1))
    sleep 0.5
done

echo "Done!"

```

**Execution & Output:**

```bash
$ chmod +x countdown.sh
$ ./countdown.sh
Enter starting number: 3
3
2
1
0
Done!

```

<img width="778" height="528" alt="image" src="https://github.com/user-attachments/assets/c7286cbf-5cbb-41de-82fc-c51a2ce0f1f5" />


---

### Task 3: Command-Line Arguments

#### 1. Personalized Greeting (`greet.sh`)

Accepts a name as `$1`. If no argument is passed, displays usage instructions.

**Script Code (`greet.sh`):**

```bash
#!/bin/bash
# Description: Greet user via command-line positional argument

if [ -z "$1" ]; then
    echo "Usage: ./greet.sh <name>"
    exit 1
fi

echo "Hello, $1!"

```

**Execution & Output:**

```bash
$ chmod +x greet.sh
$ ./greet.sh
Usage: ./greet.sh <name>

$ ./greet.sh NB11ML
Hello, NB11ML

```
<img width="778" height="438" alt="image" src="https://github.com/user-attachments/assets/c94af52c-a69c-49e8-88c9-226806cc06b2" />

#### 2. Arguments Demonstration (`args_demo.sh`)

Displays script metadata including script name (`$0`), argument count (`$#`), and all passed arguments (`$@`).

**Script Code (`args_demo.sh`):**

```bash
#!/bin/bash
# Description: Demonstrate special argument variables

echo "Script Name (\$0): $0"
echo "Total Number of Arguments (\$#): $#"
echo "All Arguments (\$@): $@"

```

**Execution & Output:**

```bash
$ chmod +x args_demo.sh
$ ./args_demo.sh Linux Docker Kubernetes Terraform
Script Name ($0): ./args_demo.sh
Total Number of Arguments ($#): 4
All Arguments ($@): Linux Docker Kubernetes Terraform

```

<img width="776" height="430" alt="image" src="https://github.com/user-attachments/assets/82e60ad7-81bf-4156-9f86-921a0b95446d" />


---

### Task 4 & Task 5 (Combined): Package Installer & Error Handling

#### Package Installation Script (`install_packages.sh`)

Loops through packages (`nginx`, `curl`, `wget`), checks if installed using `dpkg -s`, installs missing packages, and enforces root privileges via `$EUID`.

**Script Code (`install_packages.sh`):**

```bash
#!/bin/bash
# Description: Automated package installer with root check

# Enforce root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (e.g., sudo ./install_packages.sh)"
    exit 1
fi

PACKAGES=("nginx" "curl" "wget")

for PKG in "${PACKAGES[@]}"; do
    if dpkg -s "$PKG" &> /dev/null; then
        echo "[EXISTS] Package '$PKG' is already installed."
    else
        echo "[INSTALLING] Package '$PKG' is missing. Installing..."
        apt-get update -qq && apt-get install -y "$PKG" &> /dev/null
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] Package '$PKG' installed successfully."
        else
            echo "[ERROR] Failed to install '$PKG'."
        fi
    fi
done

```

**Execution & Output (Non-Root User):**

```bash
$ ./install_packages.sh
Error: Please run as root (e.g., sudo ./install_packages.sh)

```

**Execution & Output (Root User):**

```bash
$ sudo ./install_packages.sh
[EXISTS] Package 'nginx' is already installed.
[EXISTS] Package 'curl' is already installed.
[EXISTS] Package 'wget' is already installed.

```

---

### Task 5: Safe Script Execution

#### Safe Script (`safe_script.sh`)

Uses `set -e` to stop execution on unhandled errors, creates directory `/tmp/devops-test`, navigates into it, and creates a file using standard logic and fallback operators (`||`).

**Script Code (`safe_script.sh`):**

```bash
#!/bin/bash
# Description: Safe execution script with set -e and conditional operators

set -e

DIR="/tmp/devops-test"

# Create directory safely
mkdir -p "$DIR" || echo "Directory already exists or failed to create"

# Navigate to target directory
cd "$DIR" || { echo "Failed to change directory"; exit 1; }

# Create test file
touch devops_file.txt || echo "Failed to create file"

echo "Directory created and navigate successfully!"
echo "File created at: $DIR/devops_file.txt"

```

**Execution & Output:**

```bash
$ chmod +x safe_script.sh
$ ./safe_script.sh
Directory created and navigate successfully!
File created at: /tmp/devops-test/devops_file.txt

```

---

## Key Learnings

1. **Loop Construct Efficiency:**
* `for` loops are ideal when iterating over finite arrays, ranges (`{1..10}`), or command outputs.
* `while` loops excel when running tasks until a given condition evaluates to false.


2. **Positional Arguments & Flexiblity:**
* Command-line parameters like `$1`, `$#` (arg count), and `$@` (all args) make scripts dynamic and re-usable without hardcoding values.


3. **Defensive Scripting & Error Handling:**
* `set -e` prevents catastrophic cascading failures by aborting execution immediately when a command returns a non-zero exit code.
* Checking `$EUID` ensures administrative scripts exit early if executed without proper superuser permissions.



---

## Hints Reference

* For loop: `for item in list; do ... done`
* While loop: `while [ condition ]; do ... done`
* Positional Arguments: `$1` first arg, `$#` total count, `$@` all args, `$0` script name
* Check root permissions: `if [ "$EUID" -ne 0 ]; then echo "Run as root"; exit 1; fi`
* Check Debian package: `dpkg -s <pkg> &> /dev/null && echo "installed"`

---

---
