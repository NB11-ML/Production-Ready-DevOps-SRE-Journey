# GitHub Actions Architecture 🚀 (Day 41)

This repository (`NB11-ML/git-actions`) serves as the active execution environment for advanced GitHub Actions automation, moving beyond basic push workflows into conditional triggering and concurrent environment testing.

## 🛠️ Pipeline Configurations

This repository houses four distinct CI/CD architectures designed for robust operational delivery:

*   **`pr-check.yml` (Quality Gate):** Triggers exclusively on `pull_request` events targeting `main`. Serves as a mandatory verification layer to prevent divergent or broken code from reaching production branches.
*   **`hello.yml` (Continuous Integration):** A foundational workflow triggering on standard branch `[push]` events, utilized for immediate code integration checks.
*   **`manual.yml` (Deployment Control):** Implements `workflow_dispatch` to allow SREs to manually trigger workflows while passing runtime variables (e.g., specifying target environments like `staging` or `production`).
*   **`matrix.yml` (Concurrent Validation):** Leverages `strategy.matrix` to test code across multidimensional environments (combining multiple Operating Systems and Python versions) simultaneously. 

## 🧠 SRE Learnings & Strategy

*   **Cron Job Automation:** Translated standard Linux cron syntax (e.g., `0 9 * * 1` for Monday at 9 AM) into serverless GitHub Actions schedules for zero-maintenance recurring tasks.
*   **Compute Optimization:** Utilized matrix `exclude` blocks to prune unsupported environment combinations, reducing unnecessary runner provisioning and saving CI/CD compute limits.
*   **Blast Radius Analysis:** Tested `fail-fast: false` behaviors in matrix pipelines. In production scenarios, allowing the full matrix to run despite a single failure provides complete visibility into which specific architectures are impacted by a regression.

## 🔗 Documentation
All foundational theory and daily SRE concept breakdowns are documented in the main portfolio repository: [#90DaysProductionReadyDevOpsSREJourney - Day 41](https://github.com/NB11-ML/Production-Ready-DevOps-SRE-Journey/tree/main/Day-41).
