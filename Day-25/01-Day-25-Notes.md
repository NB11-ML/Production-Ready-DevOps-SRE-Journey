# Day 25: Git Reset vs Revert & Branching Strategies

**Date:** August 16, 2026  
**Track:** Production-Ready DevOps & SRE Journey  
**Repository:** `devops-git-practice`  

---

## 📌 Executive Summary
Day 25 focuses on the critical DevOps skills of **safely undoing mistakes** and managing code flow at scale. Understanding how to precisely manipulate Git history using `reset` and `revert` is essential for disaster recovery. Furthermore, mastering industry-standard branching strategies (GitFlow, GitHub Flow, Trunk-Based Development) ensures seamless collaboration, continuous delivery, and robust release management in production environments.

---

## 🚀 Task 1: Git Reset — Hands-On & Mechanics

### Hands-On Execution Logs

#### Part A: Setup Practice Environment
```bash
# 1. Create a practice file and initialize commits
echo "Commit A code" > app.js
git add app.js && git commit -m "feat: Commit A"

echo "Commit B code" >> app.js
git add app.js && git commit -m "feat: Commit B"

echo "Commit C code" >> app.js
git add app.js && git commit -m "feat: Commit C"

git log --oneline

```
---

<img width="940" height="80" alt="Screenshot 2026-08-16 at 15 46 56" src="https://github.com/user-attachments/assets/dd61ee89-7b19-4bc0-9a16-f56f0ffd6707" />

---

#### Part B: Testing Reset Flags (`--soft`, `--mixed`, `--hard`)

```bash
# 2. Test --soft (Undo commit, keep changes staged)
git reset --soft HEAD~1
git status
# Re-commit to reset the lab
git commit -m "feat: Commit C (Restored)"

# 3. Test --mixed (Undo commit, keep changes unstaged - DEFAULT)
git reset --mixed HEAD~1
git status
# Re-add and re-commit to reset the lab
git add app.js && git commit -m "feat: Commit C (Restored)"

# 4. Test --hard (Undo commit, DESTROY uncommitted changes)
git reset --hard HEAD~1
git status
cat app.js

```

---

<img width="1533" height="801" alt="Screenshot 2026-08-16 at 15 52 06" src="https://github.com/user-attachments/assets/e9f16d73-1b7e-4c7f-86d9-9cffcc42cd49" />


---
**Observation:**

* **`--soft`**: Moved the `HEAD` pointer back to Commit B, but the changes from Commit C remained completely intact and **staged** in the index.
* **`--mixed`**: Moved the `HEAD` pointer back, but the changes from Commit C were moved to the **working directory** (unstaged).
* **`--hard`**: Moved the `HEAD` pointer back and **completely obliterated** the changes from Commit C. The file reverted exactly to its state at Commit B.

---

### 📝 Technical Q&A

1. **What is the difference between `--soft`, `--mixed`, and `--hard`?**
* `--soft`: Rewinds history; keeps changes staged.
* `--mixed`: Rewinds history; keeps changes unstaged.
* `--hard`: Rewinds history; deletes all uncommitted working directory changes.


2. **Which one is destructive and why?**
* `--hard` is highly destructive. It forcefully overwrites your working directory to match the target commit, permanently deleting any uncommitted work.


3. **When would you use each one?**
* **`--soft`**: When you want to squash several local commits together, or when you committed too early and want to add one more file to the same commit.
* **`--mixed`**: When you want to completely unstage changes and review your work line-by-line before re-staging.
* **`--hard`**: When an experiment went horribly wrong, the code is broken, and you need to force your local environment back to the last known good state.


4. **Should you ever use `git reset` on commits that are already pushed?**
* **No.** `git reset` rewrites history. If you force-push a reset branch, you will overwrite the shared remote history, causing massive conflicts for any teammate who has already pulled those commits.



---

## ⏪ Task 2: Git Revert — Hands-On & Safe Rollbacks

### Hands-On Execution Logs

```bash
# 1. View history to get the commit hash for Commit B
git log --oneline
# (Example output: a1b2c3d feat: Commit B)

# 2. Revert Commit B safely
git revert a1b2c3d

# 3. Save the auto-generated commit message in the terminal editor
# (e.g., Revert "feat: Commit B")

# 4. Check the new history and file state
git log --oneline
cat app.js

```
---

<img width="830" height="83" alt="image" src="https://github.com/user-attachments/assets/51185529-a651-4695-8493-6a062ddd8776" />
<img width="823" height="173" alt="image" src="https://github.com/user-attachments/assets/ed20cf97-522d-469a-ad75-66db378e89e4" />
<img width="812" height="72" alt="Screenshot 2026-08-16 at 15 56 55" src="https://github.com/user-attachments/assets/16f0e636-ee50-4e9d-9b03-6ef1b73c32dd" />


---
**Observation:**

Git did **not** delete Commit B. Instead, it generated a brand-new commit (e.g., `Revert "feat: Commit B"`) that stacked on top of the history. This new commit applied the exact mathematical opposite of the changes introduced in Commit B.

---

### 📝 Technical Q&A

1. **How is `git revert` different from `git reset`?**
* `git reset` moves the timeline *backward*, deleting commits and rewriting history.
* `git revert` moves the timeline *forward*, creating a brand new commit that negates the changes of a previous commit.


2. **Why is revert considered safer than reset for shared branches?**
* It preserves the original historical timeline. Because you are simply adding a new commit, collaborators can run `git pull` and receive the reverted changes normally without experiencing "diverged branch" errors.


3. **When would you use revert vs reset?**
* **Use Revert:** When a bug makes it to a public/shared branch (like `main` or production) and you need to roll it back safely without disrupting the team.
* **Use Reset:** When cleaning up your own local, private branch before opening a Pull Request.



---

## 📊 Task 3: Reset vs Revert — Summary Matrix

| Feature | `git reset` | `git revert` |
| --- | --- | --- |
| **What it does** | Moves the `HEAD` pointer backward to a previous commit. | Creates a new commit that applies the inverse of the target commit. |
| **Removes commit from history?** | **Yes** (Rewrites history) | **No** (Adds to history) |
| **Safe for shared/pushed branches?** | **No** (Causes remote conflicts) | **Yes** (Non-destructive collaboration) |
| **Primary DevOps Use Case** | Local branch cleanup / Squashing | Production bug rollbacks / Hotfixes |

---

## 🌿 Task 4: Branching Strategies in DevOps

### 1. GitFlow

* **How it works:** A strict, complex branching model. `main` only holds production-ready code. Active development happens on `develop`. Features branch off `develop`. Releases are branched off `develop` for final testing, then merged to both `main` and `develop`. Emergency fixes branch off `main` into `hotfix/` branches.
* **Diagram:**
```text
main     -------------------------> (v1.0) -----------------> (v1.1)
             \                        /  \                      /
hotfix        \                      /    ---- (bug fix) -------
               \                    /
release         \           -------/ 
                 \         /       
develop   -------->-------(merged)---------------->
                    \       /
feature              ------/

```


* **Pros & Cons:** Highly structured and great for supporting multiple versions in the wild, but very complex and can lead to "merge hell" for long-running features.

### 2. GitHub Flow

* **How it works:** A lightweight, agile alternative. The `main` branch is *always* deployable. Developers create descriptive feature branches off `main`, push to the remote, open a Pull Request (PR) for review, and merge directly back into `main` once approved.
* **Diagram:**
```text
main     ----o------------o------------o----> (Deployable)
              \          / 
feature        o---o----o (PR + Review)

```


* **Pros & Cons:** Extremely simple, fast feedback loops, and encourages continuous delivery. Not suitable for maintaining multiple historical major versions of software simultaneously.

### 3. Trunk-Based Development

* **How it works:** Developers merge code directly into the central branch (`trunk` or `main`) multiple times a day. If feature branches are used, they are extremely short-lived (hours, not days). It relies heavily on automated testing and "Feature Flags" to hide unfinished code in production.
* **Diagram:**
```text
trunk(main)  --o--o--o--o--o--o--o--o-->
                \ /      \   /
short-lived      o        o-o

```


* **Pros & Cons:** Zero merge conflicts and fastest time-to-market. Requires massive discipline, extremely high test coverage, and robust feature flag management.

---

### 📝 Technical Q&A

1. **Which strategy would you use for a startup shipping fast?**
* **GitHub Flow** (or Trunk-Based Development). It removes bureaucratic overhead, enabling continuous deployment and allowing the team to ship features as soon as they are ready.


2. **Which strategy would you use for a large team with scheduled releases?**
* **GitFlow**. The dedicated `release` branches allow QA teams to freeze code, run extensive manual tests, and prepare deployment artifacts without blocking ongoing work on the `develop` branch.


3. **Which one does your favorite open-source project use?**
* *Example: React (by Meta)* utilizes a hybrid **GitHub Flow / Trunk-based** approach. Development occurs on a central `main` branch via Pull Requests. However, they combine this with release branching when cutting specific stable versions (e.g., releasing React 18).



---

## 🛠️ Updated DevOps Git Command Reference (Days 22–25)

```bash
# --- Setup & Config ---
git config --global user.name "Name"      # Set author name
git config --global user.email "Email"    # Set author email
git clone <url>                           # Clone remote repository

# --- Basic Workflow ---
git status                                # Check working tree state
git add .                                 # Stage all changes
git commit -m "message"                   # Commit staged changes
git log --oneline --graph --all           # Visualize repository history

# --- Branching & Remote ---
git branch <name>                         # Create a new branch
git checkout -b <name>                    # Create and switch to new branch
git push -u origin <branch>               # Push new branch to remote and track
git pull origin <branch>                  # Fetch and merge remote changes
git fetch                                 # Download remote changes without merging

# --- Merging & Rebasing ---
git merge <branch>                        # Join specified branch into current branch
git merge --squash <branch>               # Combine all branch commits into single staged change
git rebase <target>                       # Reapply current branch commits on top of target

# --- Context Switching & Extraction ---
git stash push -m "description"           # Save uncommitted changes temporarily
git stash pop                             # Apply latest stashed state and drop from stack
git cherry-pick <commit-hash>             # Apply changes from a specific commit onto current branch

# --- Disaster Recovery (Reset & Revert) ---
git reset --soft HEAD~1                   # Undo last commit, keep files staged
git reset --mixed HEAD~1                  # Undo last commit, unstage files (default)
git reset --hard HEAD~1                   # Undo last commit, DESTROY all uncommitted changes
git revert <commit-hash>                  # Create a new commit that undoes the target commit
git reflog                                # View all local HEAD movements (The ultimate safety net)

```
