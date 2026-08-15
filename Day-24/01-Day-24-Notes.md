# Day 24: Advanced Git — Merge, Rebase, Stash & Cherry Pick

**Date:** August 15, 2026  
**Track:** Production-Ready DevOps & SRE Journey  
**Repository:** `devops-git-practice`  

---

## 📌 Executive Summary
Day 24 focuses on advanced Git branch integration patterns, context-switching mechanisms, and selective commit management. Mastering these operations allows SREs and DevOps engineers to maintain clean project histories, handle hotfixes seamlessly, and manage multi-developer workflows without code loss or linear history pollution.

---

## 🚀 Task 1: Git Merge — Hands-On & Mechanics

### Hands-On Execution Logs

#### Part A: Fast-Forward Merge (`feature-login`)
```bash
# 1. Create and switch to feature-login
git checkout -b feature-login

# 2. Make commits on feature-login
echo "function login() { console.log('Login logic'); }" > login.js
git add login.js
git commit -m "feat: add login initial function"

echo "// Add OAuth support" >> login.js
git add login.js
git commit -m "feat: add OAuth support to login"

# 3. Switch back to main and merge
git checkout main
git merge feature-login
```

**Observation:**  
Git performed a **Fast-Forward** merge (`Fast-forward`). Because `main` had no new commits after `feature-login` was created, Git simply moved the `main` branch pointer forward to match the tip of `feature-login`. No merge commit was created.

<img width="1055" height="506" alt="image" src="https://github.com/user-attachments/assets/0296d077-9d3d-42dc-b771-62a98844f499" />


---

#### Part B: 3-Way Merge Commit (`feature-signup`)
```bash
# 1. Create feature-signup branch
git checkout -b feature-signup
echo "function signup() { console.log('Signup logic'); }" > signup.js
git add signup.js
git commit -m "feat: add signup logic"

# 2. Switch to main and introduce a diverging commit
git checkout main
echo "# Project Documentation" > README.md
git add README.md
git commit -m "docs: add project README"

# 3. Merge feature-signup into main
git merge feature-signup
```

**Observation:**  
Because `main` moved ahead while `feature-signup` was being developed, Git performed a **3-Way Merge** (using the common ancestor, `main`, and `feature-signup`) and automatically created a **Merge Commit**: `Merge branch 'feature-signup'`.

<img width="1013" height="484" alt="image" src="https://github.com/user-attachments/assets/e3390217-bb34-4dd0-b078-f47d4d6d3ee3" />


---

### 📝 Technical Q&A

1. **What is a fast-forward merge?**
   * A fast-forward merge occurs when there are no divergent commits on the target branch (`main`) since the feature branch was created. Git simply advances the target branch pointer to the latest commit of the feature branch without creating a extra merge commit.

2. **When does Git create a merge commit instead?**
   * Git creates a merge commit when the target branch and source branch have **diverged** (i.e., new commits have been pushed to `main` after the feature branch was created). Git performs a 3-way merge algorithm and generates a new commit to bind both histories together.

3. **What is a merge conflict?**
   * A merge conflict happens when Git cannot automatically reconcile differences between two commits—typically when the exact same line in a file is modified differently in both branches, or when a file is deleted in one branch but modified in another. Git pauses the merge and inserts conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) for manual resolution.

---

## 🔀 Task 2: Git Rebase — Hands-On & Linear History

### Hands-On Execution Logs

```bash
# 1. Create feature-dashboard branch from main
git checkout -b feature-dashboard
echo "function dashboard() { return 'Dashboard UI'; }" > dashboard.js
git add dashboard.js
git commit -m "feat: add initial dashboard component"

echo "// Add metrics widget" >> dashboard.js
git add dashboard.js
git commit -m "feat: add metrics widget to dashboard"

# 2. Advance main branch with a new commit
git checkout main
echo "v1.0.0 Release" > VERSION
git add VERSION
git commit -m "chore: add release version file"

# 3. Rebase feature-dashboard onto main
git checkout feature-dashboard
git rebase main
```

<img width="935" height="702" alt="image" src="https://github.com/user-attachments/assets/760101fd-88a8-4eb1-900a-03b215d0b383" />

<img width="659" height="393" alt="image" src="https://github.com/user-attachments/assets/017cadfe-38bc-4e1f-aafb-ae056e466300" />


**History Comparison (`git log --oneline --graph --all`):**
* **Merge History:** Shows a non-linear split-and-join pattern with branching lines and merge commits joining back to `main`.
* **Rebase History:** Shows a **completely linear** timeline. The commits from `feature-dashboard` appear *on top* of the latest commit on `main`, as if work began *after* the new `main` commit was made.

---

### 📝 Technical Q&A

1. **What does rebase actually do to your commits?**
   * Rebase rewrites commit history. It unplucks the commits from your current branch, moves the branch base point to the tip of the target branch (`main`), and **re-applies each commit one by one** on top. This generates brand-new commit hashes for your changes.

2. **How is the history different from a merge?**
   * Merge preserves historical truth (when branches were created and merged) at the cost of visual clutter and merge commits. Rebase creates a clean, linear chain of commits, hiding the fact that parallel work ever happened.

3. **Why should you never rebase commits that have been pushed and shared with others?**
   * **The Golden Rule of Rebasing:** Never rebase public/shared branches! Because rebase rewrites commit hashes, rebasing a shared branch forces collaborators to reconcile conflicting histories, leading to duplicated commits, broken histories, and code loss.

4. **When would you use rebase vs merge?**
   * **Use Rebase:** On local, un-pushed feature branches to keep up-to-date with `main` before submitting a PR.
   * **Use Merge:** When merging PRs into public/protected branches (`main`, `production`) to preserve complete, accurate team history and audit trails.

---

## 📦 Task 3: Squash Commit vs Merge Commit

### Hands-On Execution Logs

#### Part A: Squash Merge (`feature-profile`)
```bash
# Create feature-profile with 4 small micro-commits
git checkout -b feature-profile
echo "user profile" > profile.js && git add profile.js && git commit -m "feat: start profile"
echo "// typo fix" >> profile.js && git add profile.js && git commit -m "fix: typo in profile"
echo "// formatting" >> profile.js && git add profile.js && git commit -m "style: format profile"
echo "// add avatar" >> profile.js && git add profile.js && git commit -m "feat: add avatar support"

# Squash merge into main
git checkout main
git merge --squash feature-profile
git commit -m "feat: user profile implementation (squashed)"
```

<img width="1206" height="662" alt="image" src="https://github.com/user-attachments/assets/2764905a-b4e1-48f0-a695-33efe412483d" />

<img width="1125" height="462" alt="image" src="https://github.com/user-attachments/assets/2a67ecce-f693-4d99-8b13-c82ae00146e2" />


**Result:**  
Only **1 single commit** was added to `main` containing the combined changes of all 4 commits from `feature-profile`.

---

#### Part B: Regular Merge (`feature-settings`)
```bash
# Create feature-settings with 2 commits
git checkout -b feature-settings
echo "settings code" > settings.js && git add settings.js && git commit -m "feat: settings init"
echo "// theme toggle" >> settings.js && git add settings.js && git commit -m "feat: theme toggle"

# Regular merge into main
git checkout main
git merge feature-settings --no-ff -m "Merge branch 'feature-settings'"
```
<img width="1197" height="379" alt="image" src="https://github.com/user-attachments/assets/10a627ba-f61e-4e94-ba7b-09ff8b44c188" />

**Result:**  
All individual commits plus the merge commit exist in the `main` history.


<img width="1050" height="249" alt="image" src="https://github.com/user-attachments/assets/7f400803-bc95-4712-a402-2a4e36071284" />

---

### 📝 Technical Q&A

1. **What does squash merging do?**
   * Squash merging condenses all commits from a feature branch into a single set of changes staged on the target branch. You then create one clean commit representing the entire feature.

2. **When would you use squash merge vs regular merge?**
   * **Squash Merge:** Ideal for merging feature/bugfix branches where individual commits represent intermediate work, WIPs, or minor formatting fixes. Keeps `main` history concise.
   * **Regular Merge:** Useful for large release branches or multi-developer epics where individual commit history and authorship attribution are critical.

3. **What is the trade-off of squashing?**
   * The trade-off is the loss of granular history and individual step-by-step context. You lose the exact progression of how a feature was built and cannot easily revert a single sub-commit within that feature.

---

## 📥 Task 4: Git Stash — Hands-On Context Switching

### Hands-On Execution Logs

```bash
# 1. Start editing a file without committing
echo "WIP: experimental analytics logic" >> analytics.js

# 2. Attempt to switch branches (fails if conflicting changes exist)
# Using git stash to save uncommitted work
git stash push -m "WIP: analytics tracker implementation"

# 3. Verify stash list
git stash list
# Output: stash@{0}: On main: WIP: analytics tracker implementation

# 4. Do work on another branch, return, and apply stash
git checkout -b hotfix-patch
# (do critical hotfix work...)
git checkout main

# 5. Apply stashed changes back and remove from stash list
git stash pop
```

---

### 📝 Technical Q&A

1. **What is the difference between `git stash pop` and `git stash apply`?**
   * `git stash pop`: Applies the most recent stashed changes (or a specified `stash@{n}`) to your working directory **and removes it** from the stash stack.
   * `git stash apply`: Applies the stashed changes to your working directory **but keeps** the stash stored in the stash stack for reuse later.

2. **When would you use stash in a real-world workflow?**
   * When an urgent production bug/hotfix requires you to immediately switch branches while you have unfinished, uncommitted work on your current feature branch. Stashing avoids creating dummy "WIP" commits on your feature branch.

---

## 🍒 Task 5: Cherry Picking — Selective Commit Extraction

### Hands-On Execution Logs

```bash
# 1. Create feature-hotfix with 3 distinct commits
git checkout -b feature-hotfix
echo "fix 1" > fix1.txt && git add fix1.txt && git commit -m "fix: critical security patch"
echo "fix 2" > fix2.txt && git add fix2.txt && git commit -m "feat: unreleased feature preview"
echo "fix 3" > fix3.txt && git add fix3.txt && git commit -m "docs: update API spec"

# 2. Get the commit hash of only the critical patch (Commit 1)
git log --oneline
# Example Output:
# a1b2c3d fix: critical security patch

# 3. Switch to main and cherry-pick only that specific commit
git checkout main
git cherry-pick a1b2c3d
```
<img width="1239" height="786" alt="image" src="https://github.com/user-attachments/assets/3508c3ca-3adf-4651-8b2e-0d7ba3e11395" />


---

### 📝 Technical Q&A

1. **What does cherry-pick do?**
   * `git cherry-pick <commit-hash>` applies the exact changes introduced by a specific commit from another branch onto your current checked-out branch, creating a new commit with the same changes.

2. **When would you use cherry-pick in a real project?**
   * When a critical bugfix is committed inside a long-running development branch, and you need to apply *only that fix* immediately to `main` or `production` without merging the entire unfinished feature branch.

3. **What can go wrong with cherry-picking?**
   * **Duplicate Commits:** It creates duplicate commits with different hashes containing the same functional change.
   * **Merge Conflicts:** If the commit depends on prior code context that exists on the source branch but not on the target branch, cherry-picking can trigger complex conflicts.

---

## 🛠️ Updated DevOps Git Command Reference (`git-commands.md`)

```bash
# --- Advanced Integration Commands ---
git merge <branch>                  # Join specified branch into current branch
git merge --no-ff <branch>          # Force creation of a merge commit
git merge --squash <branch>         # Combine all branch commits into single staged change

git rebase <target-branch>          # Reapply current branch commits on top of target branch
git rebase -i HEAD~N                # Interactive rebase of last N commits

# --- Context Switching & Stashing ---
git stash push -m "description"     # Save uncommitted changes to stash stack with note
git stash list                      # View all stashed working directory states
git stash apply stash@{n}           # Apply stashed state 'n' without removing from stack
git stash pop                       # Apply latest stashed state and drop from stack
git stash drop stash@{n}            # Remove specific stash entry

# --- Selective Commit Management ---
git cherry-pick <commit-hash>       # Apply changes from a specific commit onto current branch
git log --oneline --graph --all     # Visualize complete repository graph linear/non-linear
```
