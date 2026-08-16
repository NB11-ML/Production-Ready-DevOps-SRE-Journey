## GitHub CLI (`gh`) DevOps Cheat Sheet 

---

**Authentication & Environment Setup**

| Command | Description |
| --- | --- |
| `gh auth login` | Start interactive login wizard (Browser / PAT / SSH) |
| `gh auth status` | Verify logged-in account, scopes, and active host |
| `echo $PAT | gh auth login --with-token` | Non-interactive login using a Personal Access Token |
| `gh auth logout` | Terminate session and remove saved host credentials |
| `gh config set credential_helper cache` | Pass credentials to OS-native secret management |

---

**Repository Operations**

| Command | Description |
| --- | --- |
| `gh repo create <name> --public --clone --add-readme` | Create, initialize with README, and clone locally |
| `gh repo list <owner> --limit 30` | List repositories for an organization or user account |
| `gh repo view <owner/repo>` | View repository details, README, and status in terminal |
| `gh repo view <owner/repo> --web` | Instantly open the repository in default web browser |
| `gh repo delete <owner/repo> --confirm` | Delete remote repository without interactive prompt |

---

**Issue Triage & Management**

```bash
# Create an issue with title, body, and labels non-interactively
gh issue create --repo owner/repo --title "bug: DB timeout" --body "Details..." --label "bug"

# List open issues assigned to you
gh issue list --assignee "@me"

# View full issue thread by ID
gh issue view <issue-number>

# Close issue with resolution note
gh issue close <issue-number> --reason "completed"

```

---

**Pull Request Workflow**

```bash
# Create PR using auto-filled title/body from branch commits
gh pr create --fill

# Checkout a teammate's PR locally for testing
gh pr checkout <pr-number>

# View diff, status, and status check failures
gh pr status
gh pr diff <pr-number>

# Review and approve a PR
gh pr review <pr-number> --approve -b "LGTM!"

# Merge PR (Squash mode) and delete remote branch
gh pr merge <pr-number> --squash --delete-branch

```

---

**CI/CD Pipeline Monitoring (GitHub Actions)**

| Command | Description |
| --- | --- |
| `gh run list` | View recent pipeline run statuses and branch triggers |
| `gh run view <run-id>` | View summary details of a specific workflow run |
| `gh run watch <run-id>` | Stream live terminal execution logs of an active run |
| `gh workflow run <name.yml> -f env=staging` | Manually dispatch a parameterised workflow |

---

**Advanced DevOps Utilities & Automation**

* **Raw API Queries:**
```bash
# Fetch machine-readable JSON endpoints
gh api user
gh api repos/{owner}/{repo}/releases

```


* **Release Automation:**
```bash
# Cut a release and auto-generate release notes from PR titles
gh release create v1.0.0 --generate-notes

```


* **Gist & Snippet Management:**
```bash
# Publish local config/script as a public Gist
gh gist create deployment-script.sh --public

```


* **Custom Shortcuts (Aliases):**
```bash
# Create shortcut 'gh pv' for 'gh pr view'
gh alias set pv "pr view"
gh alias set clone-all "repo list --limit 100"

```


* **Global Code & Repo Search:**
```bash
gh search repos "kubernetes controller" --language=go

```
