# 🚀 Day 17: Shell Scripting – Loops, Arguments & Error Handling

Welcome to **Day 17** of the Production-Ready DevOps & SRE Journey! Today's focus is on automating tasks using shell scripts, command-line arguments, superuser verification, and defensive error handling.

---

## 🌳 Repository Hierarchy

```text
Day-17/
├── 📖 Documentation
│   ├── 📄 README.md                            # Main Day 17 overview
│   ├── 📄 01-Day-17-scripting.md              # Detailed notes & execution logs
│   └── 📄 02-Day-17-scripting-Cheat-Sheet.md   # Shell scripting cheat sheet
│
└── 📜 Scripts
    ├── 📜 for_loop.sh                         # Array iteration & loop syntax
    ├── 📜 count.sh                            # Range loop demonstration (1 to 10)
    ├── 📜 countdown.sh                        # Interactive while-loop timer
    ├── 📜 greet.sh                            # Positional parameter validation ($1 check)
    ├── 📜 args_demo.sh                        # Special Bash arguments ($0,$#, $@, $?)
    ├── 📜 install_packages.sh                 # Root verification ($EUID) & automated package installer
    └── 📜 safe_script.sh                      # Defensive scripting (set -e, set -u, set -o pipefail)

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
# Grant execution permissions to all scripts
chmod +x *.sh

# Run package installer (requires root privileges)
sudo ./install_packages.sh

```

---

## 💡 Key Takeaways

* **Validate Inputs Early:** Check positional arguments (`if [ -z "$1" ]`) before executing script logic.
* **Enforce Permissions:** Verify root execution (`if [ "$EUID" -ne 0 ]`) for administrative scripts.
* **Fail-Fast Directives:** Use `set -e` and `set -u` at the top of production scripts to halt execution on unexpected failures or uninitialized variables.

```
