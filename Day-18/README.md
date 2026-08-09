# 🚀 Day 18: Shell Scripting – Functions & Intermediate Concepts

Welcome to **Day 18** of the Production-Ready DevOps & SRE Journey! Today's focus is on elevating shell scripts from basic sequential commands to modular, reliable, and production-grade tools using functions, strict modes, and variable scoping.

---

## 🌳 Repository Hierarchy

```text
Day-18/
├── 📖 Documentation
│   ├── 📄 README.md                            # Main Day 18 overview
│   ├── 📄 01-Day-18-scripting.md              # Detailed task notes & execution logs
│   └── 📄 02-Day-18-scripting-Cheat-Sheet.md   # Functions, strict mode, & pipeline cheat sheet
│
└── 📜 Scripts
    ├── 📜 functions.sh                        # Basic function arguments and arithmetic
    ├── 📜 disk_check.sh                       # Modular system checks and return values
    ├── 📜 strict_demo.sh                      # Demonstrating 'set -euo pipefail' behaviors
    ├── 📜 local_demo.sh                       # Variable scoping (local vs global)
    └── 📜 system_info.sh                      # Comprehensive, cleanly formatted system reporter

```

---

## 📌 Topics Covered

* **Functions:** Writing reusable blocks of code, passing arguments (`$1`, `$2`), and handling return values via standard output.
* **Strict Mode (`set -euo pipefail`):** Enforcing fail-fast execution to prevent silent errors, uninitialized variables, and hidden pipeline failures.
* **Variable Scoping:** Using the `local` keyword to protect variables from polluting the global script namespace.
* **Data Pipelines:** Combining `df`, `free`, `ps`, `grep`, `awk`, and `sed` to extract specific system metrics cleanly.

---

## ⚡ Execution

Make the scripts executable and run them directly from your terminal:

```bash
# Grant execution permissions to all scripts
chmod +x Scripts/*.sh

# Run the comprehensive System Info Reporter
./Scripts/system_info.sh

```

---

## 💡 Professional Takeaways

* **Fail-Fast by Default:** Always include `set -euo pipefail` at the top of production scripts. It transforms unpredictable bash failures into immediate, traceable exits.
* **Isolate Variables:** Default Bash variables are global. Always use `local` inside functions to prevent accidental overwrites and unpredictable states.
* **The `main()` Wrapper:** Encapsulating script logic inside a `main()` function ensures all definitions are loaded into memory before any execution begins, reducing top-to-bottom parsing bugs.

```

```
