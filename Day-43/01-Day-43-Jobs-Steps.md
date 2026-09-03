# Day 43: Pipeline Flow Control – Jobs, Steps, Env Vars & Conditionals 🚀

Controlling pipeline execution flow is critical in production CI/CD. Rather than running linear scripts on a single virtual machine, modern SRE architectures coordinate multi-job dependencies, scope environment variables, pass artifacts/outputs across isolated runners, and conditionally gate deployments.

---

## ⛓️ Task 1: Multi-Job Dependency Pipelines

By default, jobs defined in a GitHub Actions workflow run in parallel. To enforce a sequential deployment lifecycle (Build ➔ Test ➔ Deploy), we use the `needs:` keyword to construct a Directed Acyclic Graph (DAG).

### Workflow Implementation: `.github/workflows/multi-job.yml`

```yaml
name: Multi-Job Pipeline
on: workflow_dispatch

jobs:
  build:
    name: Build Application
    runs-on: ubuntu-latest
    steps:
      - name: Build step
        run: echo "Building the app"

  test:
    name: Execute Automated Tests
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - name: Test step
        run: echo "Running tests"

  deploy:
    name: Deploy to Target Environment
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - name: Deploy step
        run: echo "Deploying"

```

<img width="2116" height="868" alt="image" src="https://github.com/user-attachments/assets/14c6aba1-a485-499c-83b0-de58ef08601f" />
<img width="1444" height="838" alt="image" src="https://github.com/user-attachments/assets/3f534f20-343e-4ada-94ad-eb15f19222c8" />


### SRE Architectural Breakdown

* **Directed Acyclic Graph (DAG):** `test` waits for `build` to return exit code `0`. If `build` fails, GitHub immediately marks `test` and `deploy` as skipped, preventing bad builds from triggering test infrastructure or rolling out broken code.
* **Actions Visualization:** The Actions visualizer maps these dependencies as linked nodes connected by directional arrows (`build` ➔ `test` ➔ `deploy`).

---

## 🌐 Task 2: Hierarchical Environment Variables & Contexts

Environment variables (`env`) can be scoped at three distinct levels in GitHub Actions. If keys overlap, lower scopes override higher scopes.

### Workflow Implementation: `.github/workflows/env-vars.yml`

```yaml
name: Environment Variable Hierarchy
on: workflow_dispatch

# 1. Workflow Level: Available to every job and step
env:
  APP_NAME: myapp

jobs:
  inspect-scope:
    runs-on: ubuntu-latest
    # 2. Job Level: Available to all steps within this job
    env:
      ENVIRONMENT: staging

    steps:
      - name: Print Scoped Variables & GitHub Context
        # 3. Step Level: Available only to this step
        env:
          VERSION: 1.0.0
        run: |
          echo "=== Scoped Environment Variables ==="
          echo "App Name (Workflow level) : $APP_NAME"
          echo "Environment (Job level)   : $ENVIRONMENT"
          echo "Version (Step level)       : $VERSION"

          echo "=== GitHub Context Metadata ==="
          echo "Triggered By (Actor)       : ${{ github.actor }}"
          echo "Commit SHA                 : ${{ github.sha }}"

```

### Variable Scoping Hierarchy

* **Workflow-level:** Ideal for global configurations (e.g., application identifiers, base container registry URLs).
* **Job-level:** Ideal for target environments (e.g., `ENVIRONMENT: staging`, runner architecture settings).
* **Step-level:** Ideal for isolated tasks (e.g., passing step-specific API endpoints, runtime versions).
* **GitHub Context (`github.*`):** Built-in objects that expose metadata about the webhook payload, runner, and triggering actor without requiring external setup.

---

## 🔄 Task 3: Cross-Job Outputs

Because each job runs on an isolated, ephemeral virtual machine, runner memory and local filesystems are completely discarded when a job finishes. To pass calculated values (such as image tags, build timestamps, or artifact IDs) between jobs, we register outputs via `$GITHUB_OUTPUT`.

### Workflow Implementation: `.github/workflows/job-outputs.yml`

```yaml
name: Cross-Job Data Passing
on: workflow_dispatch

jobs:
  generate-data:
    name: Generate Pipeline Metadata
    runs-on: ubuntu-latest
    outputs:
      build_date: ${{ steps.date-step.outputs.current_date }}
    steps:
      - id: date-step
        name: Fetch and Register Current Date
        run: echo "current_date=$(date +'%Y-%m-%d %H:%M:%S')" >> $GITHUB_OUTPUT

  consume-data:
    name: Consume Upstream Metadata
    runs-on: ubuntu-latest
    needs: [generate-data]
    steps:
      - name: Print Received Upstream Output
        run: echo "The upstream build completed at: ${{ needs.generate-data.outputs.build_date }}"

```

### Why Pass Outputs Between Jobs?

* **Dynamic Tagging:** A build job builds a Docker image and generates a dynamic SHA hash or semver string; the deployment job needs that exact string to deploy the image.
* **Resource IDs:** An infrastructure provisioning job creates a cloud resource (like an AWS S3 bucket or test database) and passes the generated resource ID or endpoint directly to the testing suite.
* **Separation of Concerns:** Heavy builds occur on specialized build runners, while lightweight notifications (Slack/Teams alerts) consume the output on smaller, cheaper runners without sharing filesystems.

---

## 🚦 Task 4: Workflow Conditionals & Fault Tolerance

Conditionals (`if:`) govern step- and job-level execution based on runtime conditions, branch names, or previous job statuses.

### Key Conditionals Evaluated

* **Branch Restriction:**
```yaml
if: github.ref == 'refs/heads/main'

```


Runs exclusively when changes hit the production `main` branch.
* **Negative Failure Traps:**
```yaml
if: failure()

```


Runs only if any prior step in the job fails. Commonly used for incident triage, capturing core dumps, or publishing alert webhooks.
* **Event Type Filtering:**
```yaml
if: github.event_name == 'push'

```


Ensures a job executes solely on direct pushes or merges, ignoring `pull_request` hooks.
* **`continue-on-error: true` Behavior:**
* Tells GitHub Actions to treat step failures as non-fatal warnings.
* The step will show a yellow warning icon if it fails, but the pipeline does not stop; execution continues to subsequent steps without failing the overall job.
* Used for non-critical steps such as experimental linter checks, optional static analysis, or best-effort cache updates.



---

## 🧩 Task 5: Production-Ready Orchestration

This pipeline brings all concepts together: parallel execution, dependencies, branch detection, and metadata printing.

### Workflow Implementation: `.github/workflows/smart-pipeline.yml`

```yaml
name: Smart Pipeline Orchestration
on: push

jobs:
  lint:
    name: Static Code Analysis
    runs-on: ubuntu-latest
    steps:
      - name: Run Linter
        run: echo "Linting code base... PASSED"

  test:
    name: Automated Unit Testing
    runs-on: ubuntu-latest
    steps:
      - name: Run Unit Tests
        run: echo "Running test suites... ALL TESTS GREEN"

  summary:
    name: Build Pipeline Summary
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - name: Print Commit Context
        run: |
          echo "Triggering Actor : ${{ github.actor }}"
          echo "Commit SHA       : ${{ github.sha }}"
          echo "Commit Message   : ${{ github.event.commits[0].message }}"

      - name: Main Branch Evaluation
        if: github.ref == 'refs/heads/main'
        run: echo "Production Pipeline: Execution triggered by a direct push/merge to the main branch."

      - name: Feature Branch Evaluation
        if: github.ref != 'refs/heads/main'
        run: echo "Development Pipeline: Execution triggered on feature branch '${{ github.ref_name }}'."

```

---

## 💡 Core Definitions

* **`needs:`** Declares explicit dependency requirements for a job. It pauses execution until the specified upstream jobs exit with status code `0`, transforming parallel jobs into an ordered CI/CD dependency graph.
* **`outputs:`** An inter-job communication mechanism. It maps step-level outputs (`$GITHUB_OUTPUT`) to job-level variables, allowing isolated, ephemeral runners to transfer lightweight runtime parameters down the DAG.

---
