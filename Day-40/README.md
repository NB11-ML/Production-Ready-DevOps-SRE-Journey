# GitHub Actions Practice 🚀

This repository (`NB11-ML/git-actions`) serves as the practical execution environment for **Day 40** of my `#90DaysProductionReadyDevOpsSREJourney`. It marks the transition from CI/CD theory to writing, deploying, and debugging live automated infrastructure code in the cloud.

For the full theoretical breakdown and documentation, refer to the main journey repository: [Day 40 - First Workflow](https://github.com/NB11-ML/Production-Ready-DevOps-SRE-Journey/blob/0f03d60c1e675cfa1cca3cd39f8337682e589efa/Day-4/01-Day-40-First-Workflow.md).

## 🛠️ Pipeline Architecture (`hello.yml`)

The following Mermaid diagram maps the execution sequence of the foundational CI/CD pipeline triggered in this repository.

```mermaid
graph TD
    Trigger(["fa:fa-code-branch Git Push to Repository"]) -->|"Wakes up"| Runner["ubuntu-latest Runner"]
    
    subgraph Job: greet
        Runner --> S1["actions/checkout@v4<br/>Pulls Code"]
        S1 --> S2["echo 'Hello from GitHub Actions!'"]
        S2 --> S3["date<br/>Prints Timestamp"]
        S3 --> S4["echo Branch Name<br/>Uses github.ref_name"]
        S4 --> S5["ls -la<br/>Lists Repo Files"]
        S5 --> S6["echo OS<br/>Uses runner.os"]
    end
    
    S6 --> Success(["Pipeline Green / Success"])
    
    classDef default fill:#f8fafc,stroke:#334155,stroke-width:2px;
    classDef trigger fill:#dbeafe,stroke:#2563eb,stroke-width:2px;
    classDef success fill:#dcfce3,stroke:#16a34a,stroke-width:2px;
    
    class Trigger trigger;
    class Success success;

```

## 🧠 Core CI/CD Concepts Applied

This repository practically demonstrates the following GitHub Actions primitives:

* **`on:` (Triggers):** Automating workflow execution on specific repository events (e.g., `[push]`).
* **`jobs:` & `runs-on:` (Runners):** Provisioning isolated virtual machines (like `ubuntu-latest`) to execute deployment instructions.
* **`uses:` (Marketplace Actions):** Leveraging pre-built community actions (`actions/checkout@v4`) to give the runner access to the repository codebase without writing custom shell scripts.
* **`run:` (Shell Execution):** Executing raw terminal commands (`date`, `ls -la`) directly on the runner's operating system.
* **Context Variables:** Dynamically pulling GitHub metadata into the pipeline using syntax like `${{ github.ref_name }}` and `${{ runner.os }}`.

## 💥 Incident Debugging (Task 5)

As part of understanding failure states in SRE pipelines, this repository was used to test intentional non-zero exit codes (e.g., injecting `run: exit 1`).

**Key takeaways from pipeline failures:**

1. Execution halts immediately at the failed step.
2. Subsequent steps are skipped automatically.
3. Failures generate a red 'X' indicator that can be used to block faulty code from being merged into production branches.
4. Standard error (`stderr`) logs can be read directly by expanding the failed step in the GitHub Actions UI.

```

```
