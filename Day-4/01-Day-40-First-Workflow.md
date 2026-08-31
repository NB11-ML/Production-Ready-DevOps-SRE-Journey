# Day 40: Your First GitHub Actions Workflow

## Task 1: Set Up
To begin the transition from CI/CD theory to practice, I initialized the environment for GitHub Actions execution:
*   Created a new public repository.
*   Cloned the repository locally.
*   Established the required directory structure: `mkdir -p .github/workflows/`.

---

## Task 2 & 4: The Complete Workflow YAML (`hello.yml`)
This pipeline executes a foundational series of commands on an isolated Ubuntu runner to demonstrate triggers, context variables, and repository access. 

```yaml
name: SRE Hello Workflow
on: [push]

jobs:
  greet:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Print Greeting
        run: echo "Hello from GitHub Actions!"

      - name: Print Date and Time
        run: date

      - name: Print Branch Name
        run: echo "The pipeline was triggered by branch ➔ ${{ github.ref_name }}"

      - name: List Repository Files
        run: |
          echo "Repository contents:"
          ls -la

      - name: Print Runner Operating System
        run: echo "This job is executing on ➔ ${{ runner.os }}"

```

### Pipeline Execution Proof

<img width="1880" height="825" alt="image" src="https://github.com/user-attachments/assets/ee09f497-561d-49ad-ac70-97abb3c60aa7" />

---

## Task 3: Pipeline Anatomy & Key Definitions

Understanding the explicit function of every YAML directive is critical for writing and debugging complex SRE pipelines.

* **`on:`** The trigger mechanism. Defines exactly which GitHub events (e.g., `push`, `pull_request`, `schedule`) will wake up the runner and start the pipeline.
* **`jobs:`** The primary organizational block. A workflow consists of one or more jobs. By default, multiple jobs run in parallel unless explicit dependencies (`needs:`) are defined.
* **`runs-on:`** Specifies the exact virtual machine environment (OS and architecture) provisioned to execute the job (e.g., `ubuntu-latest`, `windows-latest`).
* **`steps:`** The sequential list of individual tasks executed top-to-bottom within a single job. If one step fails, the subsequent steps do not run.
* **`uses:`** Imports and executes a pre-packaged, community-built Action (like `actions/checkout@v4`). This prevents SREs from having to write custom bash scripts for standard tasks. The `checkout` action is essential because it allows the runner to pull down the repository's codebase.
* **`run:`** Executes raw shell commands directly on the runner's operating system (e.g., `date`, `ls -la`).
* **`name:`** Assigns a human-readable label to a job or step. This is entirely for observability, making the GitHub Actions UI logs easy to read during an incident.

---

## Task 5: Intentional Failure Analysis

To test how CI/CD handles errors, I intentionally injected a failure using a bad command (`run: exit 1`).

<img width="1056" height="650" alt="image" src="https://github.com/user-attachments/assets/15cf9a16-9fc4-44d5-803d-b01784de0b42" />

* **What a failed pipeline looks like:** The GitHub Actions tab displays a red 'X' next to the run. Execution immediately stops at the exact step where the non-zero exit code was generated. All subsequent steps are skipped. If branch protections are enabled, this red 'X' blocks code merging.
* **How to read the error:** Navigate to the **Actions** tab, click the failed workflow run, and click into the specific job (`greet`). Expand the step marked with the red 'X' to view the raw terminal logs. The standard error (`stderr`) output will show exactly which command failed and why (e.g., "command not found"), allowing for rapid debugging.

After removing error code:

<img width="1885" height="875" alt="image" src="https://github.com/user-attachments/assets/f7fa8042-6c67-42bc-91c3-21af74d7cfcf" />

---
