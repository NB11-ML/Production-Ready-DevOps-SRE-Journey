# 🚀 Day 17: Shell Scripting – Loops, Arguments & Error Handling

Welcome to **Day 17** of the Production-Ready DevOps & SRE Journey! Today's focus is on automating tasks using shell scripts, command-line arguments, superuser verification, and defensive error handling.

---

## 🌳 Repository Hierarchy

```text
Day-17/
├── 📄 README.md              # Day 17 overview
├── 📄 day-17-scripting.md    # Detailed documentation & output logs
├── 📜 for_loop.sh           # Array iteration example
├── 📜 count.sh              # Range loop (1 to 10)
├── 📜 countdown.sh          # Interactive while-loop timer
├── 📜 greet.sh              # Input validation ($1 check)
├── 📜 args_demo.sh           # Special Bash arguments demo ($0, $#, $@)
├── 📜 install_packages.sh   # Root verification ($EUID) & automated package installer
└── 📜 safe_script.sh        # Defensive scripting with set -e and fallbacks

```

---

## 📌 Topics Covered

* **Loops:** Task automation using `for` and `while` loops.
* **Command-Line Arguments:** Handling inputs via `$1`, `$#`, `$@`, and `$0`.
* **Package Automation:** Automated checking and installation using `dpkg -s` and `apt-get`.
* **Error Handling:** Defensive scripting using `set -e`, `$EUID` root checks, and fallback logic.

---

## ⚡ Execution

Make scripts executable and run them directly:

```bash
# Grant execution permissions
chmod +x *.sh

# Run package installer (requires root)
sudo ./install_packages.sh

```

---

## 💡 Key Takeaways

* Validate arguments (`if [ -z "$1" ]`) before executing logic to avoid crashes.
* Enforce root permissions using `if [ "$EUID" -ne 0 ]` for administrative tasks.
* Add `set -e` to stop script execution immediately if any command fails.

```

```
