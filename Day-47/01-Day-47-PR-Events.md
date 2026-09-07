# 🚀  :octocat: Day 47: Pull Request Lifecycle & Event Types 🔀

In enterprise CI/CD architecture, pipelines must react differently depending on the exact state of a pull request. Running unit tests when a PR is opened is standard, but you also need strict conditional logic to trigger production deployments only upon a successful merge, or clean up ephemeral test environments when a PR is abandoned. 

Today's focus is on listening to specific GitHub webhook events to control exactly how and when automated pipeline logic executes.

## Task 1: Intercepting PR Lifecycle Events

**Objective:** 
Create a workflow that tracks a pull request as it moves through its lifecycle (`opened`, `synchronize`, `closed`) and conditionally executes post-merge logic only upon a successful integration.

**Workflow Implementation:**
**File Path:** `.github/workflows/pr-lifecycle.yml`

```yaml
name: PR Lifecycle Events

on:
  pull_request:
    types: [opened, synchronize, reopened, closed]

jobs:
  pr-tracker:
    runs-on: ubuntu-latest
    steps:
      - name: Log PR Event Details
        run: |
          echo "Event Type: ${{ github.event.action }}"
          echo "PR Title: ${{ github.event.pull_request.title }}"
          echo "PR Author: ${{ github.event.pull_request.user.login }}"
          echo "Source Branch (Head): ${{ github.event.pull_request.head.ref }}"
          echo "Target Branch (Base): ${{ github.event.pull_request.base.ref }}"

      - name: Execute Post-Merge Logic
        # This step acts as a strict deployment gate
        if: github.event.action == 'closed' && github.event.pull_request.merged == true
        run: |
          echo "🎉 SUCCESS: PR was successfully merged into ${{ github.event.pull_request.base.ref }}!"
          echo "This is where you would trigger production deployments or clean up temporary environments."

```

**Architecture & Logic Breakdown:**

* **Event Scoping:** The `on: pull_request` block filters webhook triggers strictly to `types: [opened, synchronize, reopened, closed]` so the runner doesn't waste compute minutes on irrelevant actions (like assigning a label).
* **Metadata Extraction:** The workflow dynamically parses the injected JSON payload (`${{ github.event... }}`) to identify the exact action type, author, and branch trajectory (head vs. base).
* **Strict Merge Validation:** Because the `closed` event triggers for both successfully merged PRs and rejected/abandoned PRs, the conditional step requires a dual-validation check: `github.event.action == 'closed' && github.event.pull_request.merged == true`.

**Execution Proof:**
Below are the runner logs demonstrating the workflow dynamically adapting to the PR's state as it moved from creation to final merge.

**PR Opened Event:**

<img width="1448" height="1014" alt="image" src="https://github.com/user-attachments/assets/2f867729-3727-4cde-b47e-67dbc5321587" />



**PR Closed & Merged Event:**

<img width="1458" height="1062" alt="image" src="https://github.com/user-attachments/assets/bcc13496-f607-4344-a548-5ae39c66b0af" />

---

## Task 2: PR Validation Gate (Automated Quality Checks)

**Objective:**
Implement a strict set of automated checks that evaluate Pull Requests against repository conventions before allowing them to be merged into the `main` branch.

**Workflow Implementation:**
**File Path:** `.github/workflows/pr-checks.yml`

```yaml
name: PR Validation Gate

on:
  pull_request:
    branches:
      - main

jobs:
  file-size-check:
    name: File Size Limit (1MB)
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Enforce Size Limits
        run: |
          LARGE_FILES=$(find . -type f -size +1M -not -path "*/\.git/*")
          if [ -n "$LARGE_FILES" ]; then
            echo "❌ Error: The following files exceed the 1MB limit:"
            echo "$LARGE_FILES"
            exit 1
          fi
          echo "✅ All files are within the 1MB limit."

  branch-name-check:
    name: Branch Naming Convention
    runs-on: ubuntu-latest
    steps:
      - name: Validate Branch Prefix
        run: |
          BRANCH="${{ github.head_ref }}"
          if [[ "$BRANCH" != feature/* && "$BRANCH" != fix/* && "$BRANCH" != docs/* ]]; then
            echo "Error: Branch '$BRANCH' violates naming conventions."
            exit 1
          fi
          echo "Branch name '$BRANCH' is valid."

  pr-body-check:
    name: PR Description Check
    runs-on: ubuntu-latest
    steps:
      - name: Validate PR Body
        env:
          PR_BODY: ${{ github.event.pull_request.body }}
        run: |
          if [ -z "$PR_BODY" ]; then
            echo "::warning title=Empty PR Description::Please provide a detailed description of your changes."
          else
            echo "PR description is present."
          fi

```

**Architecture & Logic Breakdown:**

* **File Size Gate:** Uses the native Linux `find` command to scan the working directory for files over 1MB. If found, the job explicitly fails (`exit 1`), preventing bloated binaries from being merged.
* **Naming Convention Gate:** Extracts the source branch name using `${{ github.head_ref }}` and validates it against allowed prefixes (`feature/*`, `fix/*`, `docs/*`) using bash conditional logic.
* **Description Validation:** Injects the PR description into the environment. If it evaluates as empty, it uses GitHub Actions' `::warning::` syntax to surface a yellow annotation on the PR UI without hard-blocking the merge.

**Execution Proof:**
The execution logs below demonstrate the validation gate rejecting a non-compliant Pull Request. The `test-bad-branch` triggered a failure on the branch naming convention check, protecting the `main` branch from non-standardized code integration.

<img width="1448" height="1252" alt="image" src="https://github.com/user-attachments/assets/86badaf6-a680-4b6f-94b0-1de78800ec31" />

<img width="1452" height="846" alt="image" src="https://github.com/user-attachments/assets/0040f2e6-eb63-4c61-ae2e-71486ec174c5" />


```
