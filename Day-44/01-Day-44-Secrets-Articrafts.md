# Day 44: Secrets, Artifacts & Real CI Tests 🚀

Modern SRE and CI/CD pipelines must securely handle sensitive credentials, preserve build outputs across ephemeral environments, and enforce rigorous testing standards.

## 🔐 Task 1 & 2: Secrets Management in Actions

GitHub Secrets provide encrypted environment variables for use in workflows, ensuring sensitive data (like API tokens and database passwords) is not hardcoded into public YAML files.

**Step-by-Step Implementation:**
1. Navigate to **Repository Settings ➔ Secrets and Variables ➔ Actions**.
2. Click **New repository secret**.
3. Create `MY_SECRET_MESSAGE`, `DOCKER_USERNAME`, and `DOCKER_TOKEN`.
4. Create `.github/workflows/secrets-test.yml` to securely pass these into the runner environment.

```yaml
name: Secrets Management
on: workflow_dispatch

jobs:
  test-secrets:
    runs-on: ubuntu-latest
    env:
      MY_SECURE_ENV_VAR: ${{ secrets.MY_SECRET_MESSAGE }}
    steps:
      - name: Verify Secret Presence
        run: |
          if [ -n "$MY_SECURE_ENV_VAR" ]; then
            echo "The secret is set: true"
          else
            echo "The secret is set: false"
          fi
          
      - name: Accidental Print Test
        run: echo "Direct print attempt: ${{ secrets.MY_SECRET_MESSAGE }}"

```

<img width="1454" height="1340" alt="image" src="https://github.com/user-attachments/assets/ca90b9ce-755e-4d84-8830-7e0bb8037440" />

<img width="1910" height="992" alt="image" src="https://github.com/user-attachments/assets/31c978c7-3b2d-43f8-96dd-28a825c3d44f" />


### 🧠 SRE Notes: Secrets

* **What happens when you print a secret?** GitHub Actions automatically intercepts and masks registered secrets in the logs, replacing the output with `***`.
* **Why should you never print secrets in CI logs?** Log masking is not foolproof. Base64 encoding or structured data can sometimes bypass masks. Furthermore, build logs are often exported to external observability tools (like Splunk or Datadog) where GitHub's masking no longer applies, exposing credentials to wider internal teams.

---

## 📦 Task 3 & 4: Artifact Uploads & Cross-Job Downloads

Artifacts allow you to persist data after a job finishes and share data between isolated jobs in a multi-stage workflow.

### Workflow Implementation: `.github/workflows/artifacts.yml`

```yaml
name: Artifact Pipeline
on: workflow_dispatch

jobs:
  build-and-upload:
    runs-on: ubuntu-latest
    steps:
      - name: Generate Build Report
        run: echo "Tests passed successfully on $(date)" > test-report.txt

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: ci-test-report
          path: test-report.txt

  download-and-consume:
    runs-on: ubuntu-latest
    needs: build-and-upload
    steps:
      - name: Download Artifact
        uses: actions/download-artifact@v4
        with:
          name: ci-test-report

      - name: Verify Download
        run: cat test-report.txt

```

<img width="1818" height="834" alt="image" src="https://github.com/user-attachments/assets/d2018820-932d-48e6-94ed-7e9a68fc80d8" />

<img width="1468" height="820" alt="image" src="https://github.com/user-attachments/assets/61c8c496-778e-4fc6-8f01-f5e52a17ac17" />


### 🧠 SRE Notes: Artifacts

* **When to use artifacts in production:** Passing compiled binaries (like Go or Java JARs) from a build runner to a deployment runner, storing code coverage reports, preserving crash dumps/logs for failed tests, and creating downloadable release assets.

---

## 🚦 Task 5: Running Real CI Tests

A pipeline's primary job is to enforce quality gates by pulling source code and running validation scripts.

### Workflow Implementation: `.github/workflows/real-tests.yml`

```yaml
name: CI Quality Gate
on: push

jobs:
  execute-tests:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Run Shell Validation Script
        # Assumes a script named 'test.sh' exists in your repo root
        run: |
          chmod +x test.sh
          ./test.sh

```

<img width="1452" height="916" alt="image" src="https://github.com/user-attachments/assets/efbbbed6-be3b-4fb5-9395-fc976c3bca94" />

<img width="1470" height="1104" alt="image" src="https://github.com/user-attachments/assets/e768ba43-4dba-46f3-81e4-e38013f36cd3" />


* **Failure Simulation:** If `test.sh` contains `exit 1`, the runner instantly catches the non-zero exit code and turns the pipeline red. Fixing the script to exit with `0` returns the pipeline to a green state.

---

## ⚡ Task 6: Dependency Caching

Caching significantly reduces CI billable minutes by storing unchanged dependencies (like `node_modules` or `pip` packages) across workflow runs.

### Workflow Implementation: `.github/workflows/caching.yml`

```yaml
name: Caching Example
on: push

jobs:
  cache-dependencies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Generate Dummy Data to Cache
        run: |
          mkdir -p my-test-cache
          echo "This represents heavy downloaded dependencies." > my-test-cache/dummy-data.txt

      - name: Save Custom Cache
        uses: actions/cache@v4
        with:
          path: my-test-cache
          key: ${{ runner.os }}-custom-cache-v1

```

<img width="1464" height="1014" alt="image" src="https://github.com/user-attachments/assets/357d976e-e2dd-4785-8655-618be632afeb" />


### 🧠 SRE Notes: Caching

* **What is being cached?** Heavy dependencies (like Node modules, Python pip libraries, or Docker layers) that rarely change between minor commits.
* **Where is it stored?** It is stored in GitHub's backend blob storage, isolated to your repository and scoped by the cache `key`.

---
