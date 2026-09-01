# Day 41: Triggers & Matrix Builds

## Task 1: Trigger on Pull Request (`pr-check.yml`)
To enforce quality checks before code is merged into the main branch, workflows can be configured to trigger on Pull Request (PR) events rather than direct pushes.

**Implementation Steps:**
1. Inside your `.github/workflows/` directory, create `pr-check.yml`.
2. Add the following YAML configuration:
```yaml
name: PR Verification
on:
  pull_request:
    branches: [ "main" ]

jobs:
  verify-pr:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        
      - name: Print Branch Information
        run: echo "PR check running for branch ➔ ${{ github.head_ref }}"

```

3. Commit and push this file to the `main` branch.
4. Create a new branch (`git checkout -b test-pr-trigger`), make a dummy change, commit, and push it (`git push origin test-pr-trigger`).

<img width="1474" height="702" alt="image" src="https://github.com/user-attachments/assets/e5e387f8-3930-4d41-a6a3-99b10f0ce3f5" />
<img width="1478" height="1036" alt="image" src="https://github.com/user-attachments/assets/01422d7b-8b11-45ef-b9ed-e0a33199d3ab" />


5. Go to GitHub and open a Pull Request against `main`.

<img width="984" height="878" alt="image" src="https://github.com/user-attachments/assets/6fa63938-abaa-4662-a7c0-a83d8102f391" />


6. **Verification:** Scroll to the bottom of the PR page. You will see the `verify-pr` job running automatically as a status check.

<img width="1742" height="1320" alt="image" src="https://github.com/user-attachments/assets/b19baa4e-b980-422c-9f50-2fd365df6619" />
<img width="1692" height="994" alt="image" src="https://github.com/user-attachments/assets/36c9a09b-e619-4a24-82c1-b5af35443696" />
<img width="1480" height="662" alt="image" src="https://github.com/user-attachments/assets/7c5f0001-8d51-477c-9816-482223066eb2" />


---

## Task 2: Scheduled Triggers (Cron Syntax)

GitHub Actions can act like a traditional cron server to run periodic tasks (e.g., nightly backups, daily security scans).

* To run a workflow every day at midnight UTC, add this trigger:
```yaml
on:
  schedule:
    - cron: '0 0 * * *'

```


* **Notes / Challenge Answer:** What is the cron expression for every Monday at 9 AM?
* **Answer:** `0 9 * * 1` *(Minute 0, Hour 9, Any Day of Month, Any Month, Day of Week 1=Monday)*.



---

## Task 3: Manual Trigger (`manual.yml`)

For CD (Continuous Delivery) scenarios where a human must approve a deployment, manual triggers with input variables are essential.

**Implementation Steps:**

1. Create `.github/workflows/manual.yml` with the following configuration:

```yaml
name: Manual Deployment
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target Environment'
        required: true
        type: choice
        options:
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Execute Deployment
        run: echo "Deploying application to ➔ ${{ inputs.environment }} environment"

```

2. Commit and push to the repository.
3. **Verification:** Navigate to the **Actions** tab. Click "Manual Deployment" on the left sidebar. Click the **Run workflow** dropdown on the right, select an environment from your created dropdown list, and click run. View the logs to see the injected input value.

<img width="2936" height="766" alt="image" src="https://github.com/user-attachments/assets/f98e2a93-3cc8-4b66-97bf-7ad1d78381fe" />

<img width="2926" height="840" alt="image" src="https://github.com/user-attachments/assets/dc5bd236-fad9-4830-ab02-b52d38e093c1" />


---

## Task 4 & 5: Matrix Builds & Fail-Fast Behavior (`matrix.yml`)

Matrix builds allow SREs to run the exact same job across multiple environments, dependencies, or OS configurations concurrently.

**Implementation Steps:**

1. Create `.github/workflows/matrix.yml` combining both OS and Python version testing, while excluding one specific combination.

```yaml
name: OS and Python Matrix
on: [push]

jobs:
  test-matrix:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        python-version: ['3.10', '3.11', '3.12']
        os: [ubuntu-latest, windows-latest]
        # Exclude specific combinations (Task 5)
        exclude:
          - os: windows-latest
            python-version: '3.10'
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Print Configuration
        run: python --version

      - name: Intentional Failure Test (Task 5)
        if: ${{ matrix.python-version == '3.12' && matrix.os == 'ubuntu-latest' }}
        run: exit 1

```

**Task 4 Concept Analysis:**

* **Total Jobs Run:** We configured 3 Python versions and 2 Operating Systems (3 x 2 = 6 total jobs). Because we explicitly excluded `windows-latest` running `3.10`, the matrix will spin up exactly **5 jobs** running in parallel.

**Task 5 Concept Analysis (`fail-fast`):**

* **`fail-fast: true` (Default):** If a single job in the matrix fails, GitHub instantly cancels all other running or pending jobs in that matrix to save compute minutes.
* **`fail-fast: false`:** If one job fails (like our intentional exit 1 on Ubuntu/3.12), the rest of the matrix jobs will continue executing until completion. This is critical for SREs to know exactly which systems are stable and which are broken across the entire ecosystem.

<img width="2190" height="774" alt="image" src="https://github.com/user-attachments/assets/461af975-9aa1-4b77-9f0c-d09e39042a14" />


<img width="2940" height="1326" alt="image" src="https://github.com/user-attachments/assets/1f2bb8e6-c9c0-4af6-bce7-a79999854422" />

```

```
