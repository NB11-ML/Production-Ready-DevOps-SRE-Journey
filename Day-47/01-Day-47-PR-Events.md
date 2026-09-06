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
