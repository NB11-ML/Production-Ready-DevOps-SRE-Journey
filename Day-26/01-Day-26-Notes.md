# Day 26 – GitHub CLI: Manage GitHub from Your Terminal

**Date:** August 17, 2026  
**Track:** Production-Ready DevOps & SRE Journey  
**Repository:** `devops-git-practice`  

---

## 📌 Executive Summary
Day 26 focuses on eliminating context-switching by leveraging the **GitHub CLI (`gh`)**. Operating directly from the terminal allows DevOps and SRE professionals to streamline code reviews, manage issues, interact with CI/CD pipelines, and script complex GitHub repository administrative tasks directly within automated workflows.

---

## 🚀 Task 1: Install and Authenticate

### Hands-On Execution Logs

```bash
# 1. Install GitHub CLI (Linux / Ubuntu example)
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL [https://cli.github.com/packages/githubcli-archive-keyring.gpg](https://cli.github.com/packages/githubcli-archive-keyring.gpg) | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] [https://cli.github.com/packages](https://cli.github.com/packages) stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y

# 2. Authenticate with GitHub
gh auth login

# 3. Verify authentication status
gh auth status

```

### 📝 Technical Q&A

1. **What authentication methods does `gh` support?**
* **Web Browser Authentication (OAuth):** Opens your browser to authenticate interactively.
* **Personal Access Token (PAT):** Pass a token directly via standard input or environment variables (`GH_TOKEN` / `GITHUB_TOKEN`).
* **SSH Key Integration:** Allows you to upload existing SSH keys or generate new ones during authentication.



---

## 📁 Task 2: Working with Repositories

### Hands-On Execution Logs

```bash
# 1. Create a public test repository with a README
gh repo create gh-cli-test --public --clone --add-readme

# 2. View details of the created repository
gh repo view gh-cli-test

# 3. List all repositories under the active account
gh repo list

# 4. Open the repository in the browser from the terminal
gh repo view gh-cli-test --web

# 5. Delete the test repository safely
gh repo delete gh-cli-test --confirm

```

<img width="733" height="222" alt="image" src="https://github.com/user-attachments/assets/95f0bdf2-6d30-4a4d-87b8-73fd36de0752" />



---

## 🐛 Task 3: Issues

### Hands-On Execution Logs

```bash
# 1. Create an issue with title, body, and label
gh issue create --repo NB11-ML/devops-git-practice \
  --title "bug: database connection timeout in staging" \
  --body "PostgreSQL connection times out after 30 seconds of inactivity." \
  --label "bug"

# 2. List all open issues
gh issue list --repo NB11-ML/devops-git-practice

# 3. View specific issue details (e.g., Issue #1)
gh issue view 1 --repo NB11-ML/devops-git-practice

# 4. Close the issue from the terminal
gh issue close 1 --repo NB11-ML/devops-git-practice --reason "completed"

```

### 📝 Technical Q&A

1. **How could you use `gh issue` in a script or automation?**
* **Automated Incident Alerting:** Trigger scripts during pipeline failures or monitoring alerts to automatically open a tagged GitHub Issue.
* **Bulk Issue Triage:** Combine `gh issue list --json` with `jq` to parse open issues and run automated maintenance scripts across repositories.

---

<img width="729" height="401" alt="image" src="https://github.com/user-attachments/assets/767da789-c74f-46fc-a516-5a0676b97d47" />


---

## 🔀 Task 4: Pull Requests

### Hands-On Execution Logs

```bash
# 1. Create branch, make changes, push, and open PR
git checkout -b feature/cli-automation
echo "// automated script line" >> script.js
git add script.js
git commit -m "feat: add automation script"
git push -u origin feature/cli-automation

# Create PR using auto-fill from commit message
gh pr create --fill

# 2. List open PRs
gh pr list

# 3. View PR status, reviewers, and checks
gh pr status
gh pr view 1

# 4. Merge the PR from the terminal
gh pr merge 1 --squash --delete-branch

```

<img width="1131" height="780" alt="image" src="https://github.com/user-attachments/assets/8951de22-e351-4ed5-9133-90dd817d178a" />

### 📝 Technical Q&A

1. **What merge methods does `gh pr merge` support?**
* `--merge`: Standard 3-way merge commit.
* `--squash`: Squashes all branch commits into a single commit on the target branch.
* `--rebase`: Re-applies individual commits onto the target branch linearly.


2. **How would you review someone else's PR using `gh`?**
* Check out the PR locally to test: `gh pr checkout <pr-number>`
* View line-by-line diffs: `gh pr diff <pr-number>`
* Approve or request changes: `gh pr review <pr-number> --approve -b "LGTM!"`



---

## ⚡ Task 5: GitHub Actions & Workflows (Preview)

### Hands-On Execution Logs

```bash
# 1. List workflow runs on a public repository
gh run list --repo cli/cli

# 2. View details/status of a specific workflow run
gh run view <run-id> --repo cli/cli

```

### 📝 Technical Q&A

1. **How could `gh run` and `gh workflow` be useful in a CI/CD pipeline?**
* **Pipeline Monitoring:** Developers can tail build logs directly in the terminal (`gh run watch`) without waiting on browser UI refreshes.
* **Manual Triggering:** Scripts can invoke manually triggered pipelines using `gh workflow run <workflow-name> -f environment=staging`.



---

## 🛠️ Task 6: Useful `gh` Tricks

### Command Additions for Reference

```bash
# --- GitHub API Access ---
gh api user                                 # Fetch current user payload in JSON
gh api repos/{owner}/{repo}/releases        # List raw release metadata

# --- Gists & Releases ---
gh gist create script.sh --public           # Quickly publish a code snippet/gist
gh release create v1.0.0 --generate-notes   # Cut an official release with auto-changelogs

# --- Custom Aliases ---
gh alias set pv "pr view"                   # Create a custom shortcut 'gh pv'

# --- Search ---
gh search repos "devops" --language=python  # Search GitHub repositories globally

```

---

## 🛠️ Updated DevOps Git Command Reference (Days 22–26)

```bash
# --- GitHub CLI Basics ---
gh auth login                             # Authenticate CLI session
gh auth status                            # Check logged-in user details
gh repo create <name> --public            # Create a remote repository

# --- PR & Issue Automation ---
gh issue create --title "t" --body "b"    # Create a new issue
gh pr create --fill                       # Create PR with title/body from commit
gh pr checkout <number>                   # Checkout a PR locally for review
gh pr merge <number> --squash --delete-branch # Merge and clean up remote branch

# --- CI/CD & Maintenance ---
gh run list                               # View recent pipeline runs
gh run watch <run-id>                     # Stream live pipeline execution logs
gh release create <tag> --generate-notes  # Publish release with auto-generated notes

```
