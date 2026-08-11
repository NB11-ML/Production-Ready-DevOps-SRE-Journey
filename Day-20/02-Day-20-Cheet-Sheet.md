# 🚀 Day 20 Cheat Sheet: Log Analysis & Text Processing

---

## 1. 🛡️ Script Input & Validation
Always ensure your script has the required data before running to prevent unexpected crashes.

### Argument Checking
Check if the user provided an argument (like a file path).
```bash
if [ -z "$1" ]; then
    echo "Error: Missing file path."
    exit 1
fi

```

* **`-z`**: True if the string length is **zero** (empty).

### File Verification

Check if the provided file actually exists on the disk.

```bash
if [ ! -f "$1" ]; then
    echo "Error: File does not exist."
    exit 1
fi

```

* **`-f`**: True if the target is a regular **file**.
* **`!`**: The NOT operator (reverses the condition).

---

## 2. 🔍 Advanced Searching (`grep`)

`grep` is the ultimate tool for finding specific events inside massive log files.

| Command | Action | Example Output |
| --- | --- | --- |
| **`grep "ERROR"`** | Basic exact match search. | `10:15 ERROR Timeout` |
| **`grep -i`** | **I**gnore case (matches `Error`, `ERROR`, `error`). | `10:15 error Timeout` |
| **`grep -n`** | Show line **n**umbers alongside the match. | `42: 10:15 ERROR Timeout` |
| **`grep -c`** | **C**ount the total number of matching lines. | `150` |
| **`grep -E "A | B"`** | **E**xtended regex (Search for A **OR** B). |

**Combined Example:**

```bash
# Count lines with "ERROR" or "Failed", ignoring case
grep -iE "ERROR|Failed" /var/log/syslog | wc -l

```

---

## 3. ✂️ Text Manipulation (`awk` & `sed`)

When logs have too much information (like timestamps), use these to strip away the noise.

### `awk` (Column Manipulation)

`awk` splits text by spaces. You can mute specific columns by setting them to empty `""`.

```bash
# Removes the 1st, 2nd, and 3rd columns, printing the rest of the line
awk '{$1=$2=$3=""; print}' logfile.log

```

### `sed` (Stream Editor - Search & Replace)

Use `sed` to dynamically rewrite text using the `s/find/replace/` syntax.

```bash
# Replaces a leading line number (e.g., "45:") with "Line 45: "
sed 's/^\([0-9]*\):/Line \1: /'

```

---

## 4. 📊 The Data Pipeline (Counting & Sorting)

To find the "Top 5" of anything in Linux, you string commands together using pipes `|`.

**The "Top 5 Errors" Pipeline:**

```bash
grep "ERROR" log.log | awk '{$1=$2=$3=""; print}' | sort | uniq -c | sort -rn | head -5

```

**How the pipeline flows:**

1. **`grep`**: Grabs only the lines with errors.
2. **`awk`**: Deletes the timestamps so identical errors look exactly the same.
3. **`sort`**: Alphabetizes the list (required before using `uniq`).
4. **`uniq -c`**: Collapses duplicates and adds a **c**ount prefix (e.g., `5 Connection lost`).
5. **`sort -rn`**: Sorts **r**everse **n**umerically (highest numbers at the top).
6. **`head -5`**: Outputs only the top 5 results.

---

## 5. 📂 Clean Report Generation (Command Grouping)

Instead of appending `>>` to your report file on every single line, wrap your entire output block in curly braces `{ }` and redirect it once.

```bash
{
    echo "=== DAILY REPORT ==="
    echo "Date: $(date +%Y-%m-%d)"
    echo "Total Errors: $ERROR_COUNT"
    echo "===================="
} > report.txt

```

* **`{ ... }`**: Groups all commands executed inside.
* **`>`**: Redirects the entire grouped standard output into the file (overwriting it cleanly).
* **`$(basename "$PATH")`**: Use this inside your block to strip folders from a path (turns `/var/log/syslog` into `syslog`).

```

```
