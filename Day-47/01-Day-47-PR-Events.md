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

---

## Task 3: Scheduled Workflows (Cron Deep Dive)

**Objective:** Run automated health checks and background tasks on a strict time-based schedule using POSIX cron syntax.

**File Path:** `.github/workflows/scheduled-tasks.yml`

```yaml
name: Scheduled Health Checks

on:
  schedule:
    - cron: '30 2 * * 1'   # Every Monday at 2:30 AM UTC
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:       # Allows manual triggering for testing

jobs:
  health-check:
    name: Uptime Monitor
    runs-on: ubuntu-latest
    steps:
      - name: Print Trigger Source
        run: |
          if [ "${{ github.event_name }}" == "schedule" ]; then
            echo "⏰ Triggered by cron schedule: ${{ github.event.schedule }}"
          else
            echo "👤 Triggered manually via workflow_dispatch"
          fi

      - name: Execute Health Check (cURL)
        run: |
          TARGET_URL="[https://github.com/TrainWithShubham](https://github.com/TrainWithShubham)"
          HTTP_CODE=$(curl -o /dev/null -s -w "\%{http_code}\n" $TARGET_URL)
          
          echo "Target URL: $TARGET_URL"
          echo "HTTP Response Code: $HTTP_CODE"
          
          if [ "$HTTP_CODE" -eq 200 ]; then
            echo "✅ Health check passed. Site is online."
          else
            echo "❌ Health check failed. Site returned $HTTP_CODE."
            exit 1
          fi

```

<img width="1452" height="780" alt="image" src="https://github.com/user-attachments/assets/a199342d-707e-41c4-b17f-e0afd666cc3d" />


**Verification Steps:**

1. Navigate to the **Actions** tab in GitHub.
2. Select **Scheduled Health Checks** from the left sidebar.
3. Click **Run workflow** -> **Run workflow** to test it instantly via `workflow_dispatch`.

**Cron Notes:**

* **Every weekday at 9 AM IST:** `30 3 * * 1-5` (GitHub uses UTC. 9:00 AM IST is 3:30 AM UTC. `1-5` represents Mon-Fri).
* **First day of every month at midnight:** `0 0 1 * *` (Minute 0, Hour 0, Day 1, Every Month, Every Day of Week).
* **Why GitHub delays/skips schedules:** GitHub Actions does not guarantee exact-minute precision; jobs queue based on platform load. Additionally, GitHub automatically disables cron schedules on repositories that have had no push activity for 60 consecutive days to prevent abandoned repos from burning compute resources.

---

## Task 4: Path & Branch Filters

**Objective:** Optimize CI/CD compute minutes by ensuring pipelines only run when relevant code changes.

**File Path 1 (Inclusion):** `.github/workflows/smart-triggers.yml`

```yaml
name: App & Src Build
on:
  push:
    branches:
      - main
      - 'release/*'
    paths:
      - 'src/**'
      - 'app/**'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Triggered because code in src/ or app/ changed on main or a release branch."

```

**File Path 2 (Exclusion):** `.github/workflows/skip-docs.yml`

```yaml
name: Skip on Docs
on:
  push:
    paths-ignore:
      - '*.md'
      - 'docs/**'
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Triggered because the changes were NOT just markdown or docs."

```

**Verification Steps:**
Modify a `.md` file (like your README) and push the commit. Check the Actions tab; neither workflow will trigger because the changes do not match the required paths.

**Paths vs. Paths-Ignore Notes:**

* **`paths`:** Use for targeted component builds (e.g., only build the backend Docker image when `/backend` files change).
* **`paths-ignore`:** Use for broad, repository-wide workflows (like standard CI tests) where you want them to run on almost every push, *except* for harmless updates to documentation or `.gitignore` files.

---

## Task 5: Workflow Chaining (`workflow_run`)

**Objective:** Decouple Continuous Integration (testing) from Continuous Deployment (releasing) by triggering a downstream workflow only when the upstream workflow succeeds.

**File Path 1 (Upstream CI):** `.github/workflows/tests.yml`

```yaml
name: Run Tests
on:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Running unit tests..."
          sleep 5
          echo "✅ Tests passed!"

```

**File Path 2 (Downstream CD):** `.github/workflows/deploy-after-tests.yml`

```yaml
name: Deploy Application
on:
  workflow_run:
    workflows: ["Run Tests"]
    types: [completed]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Check Test Status
        run: |
          if [ "${{ github.event.workflow_run.conclusion }}" == "success" ]; then
            echo "🚀 Upstream tests passed. Deploying to production..."
          else
            echo "❌ Upstream tests failed. Halting deployment."
            exit 1
          fi

```

**Verification Steps:**
Push a commit to the `main` branch. Watch the Actions tab: "Run Tests" will execute first. Upon successful completion, "Deploy Application" will automatically trigger.

---

## Task 6: External Event Triggers (`repository_dispatch`)

**Objective:** Allow third-party tools and external APIs to trigger your GitHub Actions pipelines securely.

**File Path:** `.github/workflows/external-trigger.yml`

```yaml
name: External API Trigger
on:
  repository_dispatch:
    types: [deploy-request]

jobs:
  deploy-env:
    runs-on: ubuntu-latest
    steps:
      - name: Read Payload Data
        run: |
          echo "External system requested deployment to environment: ${{ github.event.client_payload.environment }}"

```

**Verification Steps:**
Using the GitHub CLI (`gh`), authenticate and run the following command in your terminal to simulate an external webhook payload:

```bash
gh api repos/NB11-ML/Production-Ready-DevOps-SRE-Journey/dispatches \
  -f event_type=deploy-request \
  -f client_payload='{"environment":"production"}'

```

**External Trigger Notes:**
Pipelines are typically triggered by external systems in scenarios such as:

* **ChatOps:** A Slack or Microsoft Teams bot allowing engineers to type `/deploy-prod`, sending a webhook to GitHub.
* **Observability/Monitoring:** Tools like Datadog or Prometheus detecting high latency and triggering a GitHub Action to automatically run a rollback or remediation playbook.
* **Pipeline Orchestration:** A primary CI server (like Jenkins or GitLab CI) triggering a specific infrastructure provisioning task hosted in GitHub Actions.

