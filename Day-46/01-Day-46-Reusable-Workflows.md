# Day 46: Reusable Workflows & Composite Actions 🔁

In enterprise CI/CD engineering, duplicating pipeline logic across dozens of repositories leads to configuration drift, security vulnerabilities, and maintenance debt. Today's implementation focuses on modular pipeline architecture using GitHub Actions `workflow_call` and custom composite actions.

---

## Task 1: Core Architecture Concepts

* **What is a reusable workflow?**  
  A centralized YAML workflow that can be triggered by other workflows rather than running solely on git events (such as `push` or `pull_request`). It behaves like a parameterized, modular function for entire CI/CD jobs.
* **What is the `workflow_call` trigger?**  
  The specific GitHub Actions event keyword placed under `on:` that exposes a workflow to external callers. It allows defining typed input parameters, mandatory/optional secrets, and exported outputs.
* **How is calling a reusable workflow different from using a regular action (`uses:`)?**  
  * **Reusable Workflows:** Called at the **job level** (`jobs.<job_id>.uses`). They define their own runners (`runs-on`), spin up separate runner instances, and can run entire multi-job pipelines.
  * **Actions (`uses:`):** Called at the **step level** (`jobs.<job_id>.steps.uses`). They execute individual commands or scripts inside the context of an existing, running job.
* **Where must a reusable workflow file live?**  
  It must strictly reside inside the `.github/workflows/` directory of the host repository.

---

## Task 2 & 4: The Reusable Workflow (`reusable-build.yml`)

This workflow defines input contracts, enforces secret presence, computes build metadata, and exports an output to downstream consumers.

**File Path:** `.github/workflows/reusable-build.yml`

```yaml
name: Reusable Build Engine

on:
  workflow_call:
    inputs:
      app_name:
        description: "Name of the target application"
        required: true
        type: string
      environment:
        description: "Target deployment environment"
        required: false
        type: string
        default: "staging"
    secrets:
      docker_token:
        description: "Authentication token for registry access"
        required: true
    outputs:
      build_version:
        description: "Generated immutable build identifier"
        value: ${{ jobs.build.outputs.version }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.gen-version.outputs.build_version }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Generate Build Version
        id: gen-version
        run: |
          SHORT_SHA=$(git rev-parse --short HEAD)
          echo "build_version=v1.0-${SHORT_SHA}" >> "$GITHUB_OUTPUT"

      - name: Build Application
        run: |
          echo "Building ${{ inputs.app_name }} for target environment:${{ inputs.environment }}"

      - name: Validate Secret Injection
        env:
          DOCKER_TOKEN: ${{ secrets.docker_token }}
        run: |
          if [ -n "$DOCKER_TOKEN" ]; then
            echo "Docker token is set: true"
          else
            echo "Docker token is set: false"
            exit 1
          fi

```

---

## Task 3 & 4: The Caller Workflow (`call-build.yml`)

The caller workflow invokes the reusable workflow at the job level, passes inputs and secrets, and coordinates a downstream job that depends on the generated output.

**File Path:** `.github/workflows/call-build.yml`

```yaml
name: Caller Pipeline

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    name: Call Reusable Build
    uses: ./.github/workflows/reusable-build.yml
    with:
      app_name: "my-web-app"
      environment: "production"
    secrets:
      docker_token: ${{ secrets.DOCKER_TOKEN }}

  deploy:
    name: Consume Workflow Output
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Print Downstream Version
        run: |
          echo "Downstream job received artifact version: ${{ needs.build.outputs.build_version }}"

```

<img width="2920" height="1486" alt="image" src="https://github.com/user-attachments/assets/6fa01799-ae05-4259-8b51-dbd726b79776" />


---

## Task 5: Custom Composite Action (`setup-and-greet`)

Composite actions consolidate multiple sequential shell commands and step-level dependencies into a single reusable action block.

**File Path:** `.github/actions/setup-and-greet/action.yml`

```yaml
name: "Setup and Greet"
description: "Prints localized system greetings and operational environment data"
inputs:
  name:
    description: "Name of the entity to greet"
    required: true
    default: "DevOps Engineer"
  language:
    description: "Target greeting language (en, es, fr)"
    required: false
    default: "en"
outputs:
  greeted:
    description: "Flag confirming successful greeting execution"
    value: ${{ steps.set-output.outputs.greeted }}

runs:
  using: "composite"
  steps:
    - name: Emit Localized Greeting
      shell: bash
      run: |
        case "${{ inputs.language }}" in
          es)
            echo "¡Hola, ${{ inputs.name }}!"
            ;;
          fr)
            echo "Bonjour, ${{ inputs.name }}!"
            ;;
          *)
            echo "Hello, ${{ inputs.name }}!"
            ;;
        esac

    - name: Emit Runtime Diagnostics
      shell: bash
      run: |
        echo "Execution Timestamp: $(date -u)"
        echo "Runner Platform: ${{ runner.os }}"

    - name: Set Status Output
      id: set-output
      shell: bash
      run: echo "greeted=true" >> "$GITHUB_OUTPUT"

```

**Verification Workflow:** `.github/workflows/test-composite.yml`

```yaml
name: Test Composite Action

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  test-action:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Run Custom Composite Action
        id: greet
        uses: ./.github/actions/setup-and-greet
        with:
          name: "SRE Team"
          language: "es"

      - name: Verify Action Output
        run: |
          echo "Was greeting emitted successfully? ${{ steps.greet.outputs.greeted }}"

```

<img width="2930" height="1356" alt="image" src="https://github.com/user-attachments/assets/14734caa-95fb-45a1-8f81-90246c5a75bf" />


---

## Task 6: Architectural Comparison

| Dimension | Reusable Workflow (`workflow_call`) | Composite Action (`using: "composite"`) |
| --- | --- | --- |
| **Execution Scope** | **Job-level**: Instantiates and executes entire job lifecycles. | **Step-level**: Runs sequentially inside an existing job's runner. |
| **Can contain jobs?** | **Yes**: Can define one or multiple independent/dependent jobs. | **No**: Cannot declare jobs; executes only steps. |
| **Can contain steps?** | **Yes**: Enclosed inside its defined jobs. | **Yes**: Chains run commands and nested actions. |
| **Repository Location** | Strictly `.github/workflows/*.yml`. | Any folder containing an `action.yml` (e.g., `.github/actions/<name>/`). |
| **Secrets Management** | Native: Declared in `secrets:` schema and inherited via `secrets: inherit` or explicit mapping. | Indirect: Cannot define `secrets:` schema; must receive them via `inputs:` or step `env:`. |
| **Primary Use Case** | Standardizing entire CI/CD compliance templates across teams and repositories. | Encapsulating reusable scripts, binary installations, or setup steps across jobs. |

---

## Verification & Execution Results

* **Caller Trigger Check:** Pushed to `main` and verified that `call-build.yml` invoked `reusable-build.yml`, displaying parameter values (`my-web-app`, `production`) and logging `Docker token is set: true`.
* **Output Passing Check:** Verified that the dependent job (`deploy`) received the computed version string `${{ needs.build.outputs.build_version }}` matching `v1.0-<short-sha>`.
* **Composite Action Check:** Verified that `test-composite.yml` executed the composite steps, emitted localized logs, and yielded `greeted=true`.

```

```
