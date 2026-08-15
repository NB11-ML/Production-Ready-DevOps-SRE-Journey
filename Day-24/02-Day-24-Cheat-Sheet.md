

# Advanced Git Cheat Sheet (Day 24)

## ➡️ Branch MergingCombine work from different branches using different strategies.

* **Fast-Forward Merge**: Git simply moves the pointer forward if no new commits exist on your target branch.
  ```bash
  git merge <branch-name>
  ```* **3-Way Merge Commit**: Automatically creates a new merge commit if the two branches have diverged.
  ```bash
  git merge --no-ff <branch-name>
  ```* **Squash Merge**: Condenses all individual micro-commits from a feature branch into a single clean commit on the target branch.
  ```bash
  git merge --squash <branch-name>
  ```
---
## 🔀 RebasingRewrite history to maintain a perfectly flat, clean, and linear timeline.
* **Standard Rebase**: Unplucks commits from your current branch and reapplies them one by one on top of the target branch.
  ```bash
  git rebase <target-branch>
  ```
* **Interactive Rebase**: Modify, squash, or edit the last `N` commits before pushing.
  ```bash
  git rebase -i HEAD~N
  ```* **⚠️ The Golden Rule**: Never rebase public or shared branches, as it rewrites hashes and breaks collaborators' history.
---

## 🌟 Context Switching (Stash)Temporarily shelve uncommitted work to fix an urgent bug without making sloppy "WIP" commits.
* **Push to Stash**: Save working modifications safely onto a temporary stack with a descriptive message.
  ```bash
  git stash push -m "your description"
  ```* **List Stashes**: View all your stored, uncommitted states.
  ```bash
  git stash list
  ```* **Pop Stash**: Apply the latest stashed changes and completely remove them from the stash stack.
  ```bash
  git stash pop
  ```* **Apply Stash**: Apply the changes but keep them safely stored in the stack for later reuse.
  ```bash
  git stash apply stash@{n}
  ```
---

## 🔎 Selective Commits & VisualizationExtract precise changes and inspect your entire repository architecture.
* **Cherry-Picking**: Apply the exact functional changes of a single specific commit from another branch onto your current branch.
  ```bash
  git cherry-pick <commit-hash>
  ```* **Visual Graph History**: Render a complete text-based visualization of all local and remote branches simultaneously.
  ```bash
  git log --oneline --graph --all
  ```

Would you like me to add a quick troubleshooting section on how to safely abort a rebase or merge if something goes wrong?

