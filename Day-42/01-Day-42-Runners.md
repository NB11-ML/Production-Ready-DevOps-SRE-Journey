# Day 42: Runner Infrastructure – GitHub-Hosted vs. Self-Hosted 🚀

## ☁️ Task 1: GitHub-Hosted Runners Matrix

GitHub-hosted runners are ephemeral virtual machines provisioned on demand by GitHub. They run a single job and are immediately destroyed, ensuring a pristine, secure environment for every pipeline execution. 

**Step-by-Step Implementation:**
1. Navigate to your repository and create `.github/workflows/hosted-runners.yml`.
2. Define a matrix of parallel jobs targeting different operating systems.
3. Use the `runner.os` context variable and native shell commands to print machine details.

```yaml
name: GitHub-Hosted Environments
on: workflow_dispatch

jobs:
  ubuntu-job:
    runs-on: ubuntu-latest
    steps:
      - name: System Info
        run: echo "OS ➔ ${{ runner.os }} | Hostname ➔ $(hostname) \vert{} User ➔ $(whoami)"

  windows-job:
    runs-on: windows-latest
    steps:
      - name: System Info
        run: Write-Host "OS ➔ ${{ runner.os }} | Hostname ➔ $env:COMPUTERNAME \vert{} User ➔ $env:USERNAME"

  macos-job:
    runs-on: macos-latest
    steps:
      - name: System Info
        run: echo "OS ➔ ${{ runner.os }} | Hostname ➔ $(hostname) \vert{} User ➔ $(whoami)"

```

<img width="2820" height="926" alt="image" src="https://github.com/user-attachments/assets/90c42080-c900-434e-a478-73746a528d75" />


## 🛠️ Task 2: Exploring Pre-installed Infrastructure

GitHub pre-installs hundreds of libraries (Docker, Node, Python, AWS CLI) on their `ubuntu-latest` image. This eliminates the need to run `apt-get install` or write complex configuration scripts at the start of every pipeline, drastically reducing execution time and saving compute minutes.

**Step-by-Step Implementation:**

1. Add a new step to the `ubuntu-job` in your workflow.
2. Probe the runner for standard DevOps tool versions.

```yaml
      - name: Verify Pre-installed SRE Tools
        run: |
          docker --version
          python3 --version
          node --version
          git --version

```
<img width="2820" height="1022" alt="image" src="https://github.com/user-attachments/assets/5bd3ad55-ed4d-4e89-89df-a2cbc4e0e9f9" />


---

## 🖥️ Task 3: Provisioning a Self-Hosted Runner

Self-hosted runners are persistent machines (local VMs, AWS EC2 instances, or bare-metal servers) that you fully manage. Much like maintaining dedicated backup target servers, this requires hands-on patching, uptime monitoring, and security hardening, but allows direct access to private network resources.

**Step-by-Step Implementation:**

1. Open your GitHub repository in the browser.
2. Navigate to **Settings** ➔ **Actions** (under Code and automation) ➔ **Runners**.
3. Click the green **New self-hosted runner** button.
4. Select **Linux** as the Runner Image.
5. Open your local Linux terminal or SSH into your cloud VM.
6. Copy and execute the provided `Download` commands to fetch the runner package.
7. Execute the `Configure` commands (`./config.sh --url <repo-url> --token <token>`).
8. When prompted for the name, press Enter to use the default hostname.
9. Start the runner by executing `./run.sh`.
10. **Verification:** Check the GitHub UI. Your runner will now appear with a green **Idle** status indicator.

## ⚙️ Task 4 & 5: Local Execution and Label Routing

In enterprise environments with hundreds of runners, custom labels operate as traffic controllers. They ensure specific workloads (like GPU-heavy processing or internal staging deployments) are routed strictly to the hardware provisioned to handle them.

**Step-by-Step Implementation:**

1. Stop your self-hosted runner in the terminal (`Ctrl + C`).
2. Reconfigure it to add a custom label: `./config.sh remove` then run setup again and type `my-linux-runner` when prompted for labels. Restart it with `./run.sh`.
3. Create `.github/workflows/self-hosted.yml`.
4. Target the specific label in the `runs-on` array.

```yaml
name: Self-Hosted Local Execution
on: workflow_dispatch

jobs:
  local-deployment:
    runs-on: [self-hosted, my-linux-runner]
    steps:
      - name: System Verification
        run: |
          echo "Hostname: $(hostname)"
          echo "Current Directory: $(pwd)"
          
      - name: Hardware File Creation Test
        run: |
          echo "Executing local runner test for Day 42" > runner-proof.txt
          ls -la runner-proof.txt

```

5. Trigger the workflow manually in the Actions tab.
6. **Verification:** Type `cat runner-proof.txt` in your local Linux terminal to prove the GitHub pipeline physically interacted with your private file system.

## ⚖️ Task 6: SRE Architecture Comparison

| Feature | GitHub-Hosted | Self-Hosted |
| --- | --- | --- |
| **Who manages it?** | GitHub (Zero maintenance, automatic patching) | You (Requires OS patching, updates, uptime management) |
| **Cost** | Consumes limited GitHub Action compute minutes | Free from GitHub (You only pay the cloud provider for the VM) |
| **Pre-installed tools** | Hundreds of common libraries and SDKs pre-configured | None (Bare OS, you must manually install all dependencies) |
| **Good for** | Standard CI, open-source projects, generic testing | Accessing private VPCs, interacting with on-prem databases, caching large build files |
| **Security concern** | Highly secure (Ephemeral VMs destroyed instantly after run) | Risky for public repos (Malicious PRs could execute arbitrary code on your persistent hardware) |


```
