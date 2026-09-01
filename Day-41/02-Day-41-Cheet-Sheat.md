# GitHub Actions Day 41: Triggers & Matrix Strategy Cheat Sheet

## 🔄 Event Triggers

**Push Trigger**
*   **YAML Syntax:**
    ```yaml
    on: [push]
    ```
*   **SRE / DevOps Use Case:** Automated CI execution immediately upon code landing in a branch.

**Pull Request Trigger**
*   **YAML Syntax:**
    ```yaml
    on:
      pull_request:
        branches: [ "main" ]
    ```
*   **SRE / DevOps Use Case:** Mandatory quality gates (linting, tests) blocking unstable code from merging into the main branch.

**Scheduled (Cron) Trigger**
*   **YAML Syntax:**
    ```yaml
    on:
      schedule:
        - cron: '0 9 * * 1'
    ```
*   **SRE / DevOps Use Case:** Recurring operational tasks like nightly database backups, weekly security scans, or stale branch cleanup.

**Manual Trigger**
*   **YAML Syntax:**
    ```yaml
    on:
      workflow_dispatch:
        inputs:
          environment:
            type: choice
    ```
*   **SRE / DevOps Use Case:** Manual deployment approvals to specific environments (staging/prod) passing runtime parameters.

---

## 🏗️ Matrix Builds & Execution Control

**Matrix Strategy**
*   **YAML Syntax:**
    ```yaml
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
    ```
*   **SRE / DevOps Use Case:** Validating infrastructure as code or application compatibility concurrently across diverse environments.

**Matrix Exclude**
*   **YAML Syntax:**
    ```yaml
    strategy:
      matrix:
        exclude:
          - os: windows-latest
            python-version: '3.10'
    ```
*   **SRE / DevOps Use Case:** Optimizing CI pipeline compute costs by stripping out unsupported or redundant environment combinations.

**Fail-Fast (Default: True)**
*   **YAML Syntax:**
    ```yaml
    strategy:
      fail-fast: true
    ```
*   **SRE / DevOps Use Case:** Halts all concurrent jobs instantly if one fails, preserving GitHub compute minutes.

**Fail-Fast (False)**
*   **YAML Syntax:**
    ```yaml
    strategy:
      fail-fast: false
    ```
*   **SRE / DevOps Use Case:** Forces all jobs to complete regardless of individual failures to map the full blast radius of an issue.
