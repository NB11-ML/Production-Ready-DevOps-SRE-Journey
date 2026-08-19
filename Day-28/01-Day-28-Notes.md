# Day 28: Milestone 1 Revision – DevOps, Linux, Shell, & Git

Today marks a critical milestone: pausing to revise and solidify the foundational concepts covered from Day 1 to Day 27. In the SRE world, deep understanding of these fundamentals is what separates operators from true engineers.

---

## 🎯 Task 1: Self-Assessment Checklist
*(Self-graded based on current comfort levels)*

### Linux
- [x] Navigate the file system, create/move/delete files and directories
- [x] Manage processes — list, kill, background/foreground
- [x] Work with systemd — start, stop, enable, check status of services
- [x] Read and edit text files using vi/vim or nano
- [x] Troubleshoot CPU, memory, and disk issues using top, free, df, du
- [x] Explain the Linux file system hierarchy (/, /etc, /var, /home, /tmp, etc.)
- [x] Create users and groups, manage passwords
- [x] Set file permissions using chmod (numeric and symbolic)
- [x] Change file ownership with chown and chgrp
- [ ] Create and manage LVM volumes *(Marked for Revisit)*
- [x] Check network connectivity — ping, curl, netstat, ss, dig, nslookup
- [x] Explain DNS resolution, IP addressing, subnets, and common ports

### Shell Scripting
- [x] Write a script with variables, arguments, and user input
- [x] Use if/elif/else and case statements
- [x] Write for, while, and until loops
- [x] Define and call functions with arguments and return values
- [ ] Use grep, awk, sed, sort, uniq for text processing *(Marked for Revisit)*
- [x] Handle errors with `set -e`, `set -u`, `set -o pipefail`, trap
- [x] Schedule scripts with crontab

### Git & GitHub
- [x] Initialize a repo, stage, commit, and view history
- [x] Create and switch branches
- [x] Push to and pull from GitHub
- [x] Explain clone vs fork
- [x] Merge branches — understand fast-forward vs merge commit
- [ ] Rebase a branch and explain when to use it vs merge *(Marked for Revisit)*
- [x] Use git stash and git stash pop
- [x] Cherry-pick a commit from another branch
- [x] Explain squash merge vs regular merge
- [x] Use git reset (soft, mixed, hard) and git revert
- [x] Explain GitFlow, GitHub Flow, and Trunk-Based Development
- [x] Use GitHub CLI to create repos, PRs, and issues

---

## 🔄 Task 2: Revisit Weak Spots

1. **LVM (Logical Volume Management):** 
   * **Review:** Revisiting Day 13. LVM is crucial for zero-downtime storage scaling. I practiced creating a Physical Volume (PV), adding it to a Volume Group (VG), and allocating a Logical Volume (LV) to simulate extending a database disk without unmounting.
2. **Advanced Text Processing (`awk` & `sed`):** 
   * **Review:** standard `grep` is easy, but complex log parsing requires `awk`. I re-ran the Day 20 Log Analyzer script, focusing specifically on using `awk` to extract specific columns (like HTTP status codes) from Apache logs.
3. **Git Rebase vs. Merge:** 
   * **Review:** Re-read Day 24. A `merge` preserves the exact history of a feature branch (creating a diamond shape in the logs), while `rebase` rewrites the feature branch commits so they appear linearly right after the main branch's latest commit. Rebase keeps history clean but should *never* be used on public/shared branches.

---

## ⚡ Task 3: Quick-Fire Questions

1. **What does `chmod 755 script.sh` do?**
   Grants the file owner read, write, and execute permissions (7), and grants the group and others read and execute permissions (5).
2. **What is the difference between a process and a service?**
   A process is any running instance of an executing program. A service is a background process (daemon) specifically managed by an init system (like `systemd`) designed to run continuously and start on boot.
3. **How do you find which process is using port 8080?**
   `sudo ss -tulnp | grep 8080` or `sudo lsof -i :8080`.
4. **What does `set -euo pipefail` do in a shell script?**
   It enforces strict error handling: `-e` exits on any command failure, `-u` exits if an unset variable is used, and `-o pipefail` ensures a failure anywhere in a pipeline (not just the last command) triggers the exit.
5. **What is the difference between `git reset --hard` and `git revert`?**
   `reset --hard` moves the HEAD pointer backward and permanently destroys uncommitted changes and subsequent commits. `revert` creates a *new* commit that undoes the changes of a previous commit, preserving the repository's history (safe for shared branches).
6. **What branching strategy would you recommend for a team of 5 developers shipping weekly?**
   **GitHub Flow** or lightweight **Trunk-Based Development**. Short-lived feature branches branching off `main`, merged via Pull Requests after code review and CI checks, with `main` always remaining deployable.
7. **What does `git stash` do and when would you use it?**
   It temporarily shelves uncommitted local changes. Useful when you are midway through a feature but need to urgently switch to another branch (like `main`) to fix a hotbug without committing half-finished work.
8. **How do you schedule a script to run every day at 3 AM?**
   Add this line to the user's crontab (`crontab -e`): `0 3 * * * /path/to/script.sh`
9. **What is the difference between `git fetch` and `git pull`?**
   `fetch` downloads the latest metadata and commits from the remote repository to your local `.git` directory but does *not* modify your working files. `pull` runs a `fetch` and immediately attempts to `merge` those changes into your current branch.
10. **What is LVM and why would you use it instead of regular partitions?**
    Logical Volume Management abstracts physical disks into logical pools. It is used because it allows you to dynamically resize, extend, or span filesystems across multiple hard drives on the fly without system downtime, which standard static partitions cannot do.

---

## 🎓 Task 5: Teach It Back (File Permissions)
*Explaining Linux File Permissions to a Junior Developer:*

"Think of a Linux file like a restricted office building. The **Owner** is the person who holds the lease. The **Group** represents a specific team (like Accounting). **Others** is the general public. 

For each of those three categories, you can hand out specific keys:
*   **Read (`r`)**: You can look through the window and read the documents inside.
*   **Write (`w`)**: You can walk in, edit the documents, or throw them away.
*   **Execute (`x`)**: If the document is an instruction manual (a script), you have the authority to actually run the instructions."

```
