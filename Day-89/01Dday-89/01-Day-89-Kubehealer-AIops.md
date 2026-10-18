# Day 89: Production AI Agents — KubeHealer, Temporal Durability, and AIOps

## Task 1: Understand AIOps and Production Guardrails (Module 4)

### 1.1 What is AIOps?
**AIOps (Artificial Intelligence for IT Operations)** is the practice of using AI to automate end-to-end IT operations: **monitoring, root-cause diagnosis, and autonomous remediation**.
* **Augmenting Humans, Not Replacing Them:** AIOps does not remove engineers from the loop; it augments on-call SREs with intelligent automation.
* **Intelligent Triage & Escalation:** The agent autonomously resolves routine, well-understood infrastructure issues (such as container image typos or low memory limits) while escalating complex or ambiguous state problems (such as missing application ConfigMaps) to human operators.
* **Watch, Reason, Act:** Unlike a passive chatbot, a production AIOps agent continuously watches cluster state, reasons about root causes using an LLM, and executes targeted remediation steps with human oversight.

---

### 1.2 The 6 Production Guardrails Every AI Agent Needs
Before granting an AI agent write permissions in a Kubernetes cluster, six non-negotiable production guardrails must be enforced:

| Guardrail | Why It Matters | Example in KubeHealer |
| :--- | :--- | :--- |
| **1. Human Approval** | Agents should never make destructive or mutating changes without explicit permission. | `"I found 3 broken pods. Here are the fixes. Approve? [yes/no]"` |
| **2. Scope Limits** | Agents should only operate in allowed namespaces and clusters to contain blast radius. | Restricted to `default` namespace; cannot touch `kube-system` or production databases. |
| **3. Audit Trail** | Every inspection, LLM call, and cluster action must be immutably recorded. | Temporal workflow history records every tool call, prompt, decision, and patch. |
| **4. Rollback Capability** | Every automated fix must be minimal, targeted, and easily reversible. | Agent applies strategic patches (`kubectl patch`) rather than deleting and replacing workloads. |
| **5. Timeout & Retry Limits** | Agents must not loop forever or exhaust API quotas on unrecoverable errors. | Max 3 retries per pod, with a hard workflow timeout after 5 minutes. |
| **6. Escalation Path** | When the agent cannot safely fix an issue, it must stop and alert a human operator. | `"config-app needs a ConfigMap I cannot create. Escalating."` |

---

### 1.3 Why Durable Execution (Temporal) Matters
* **Without Durability (Standard Python Script):** If an agent process crashes or loses network connectivity mid-diagnosis, all progress and in-memory state are lost. Restarting forces the script to start over from scratch, risking partial or inconsistent infrastructure modifications.
* **With Temporal (Durable Execution):** Every step (`scan`, `diagnose`, `fix`) is persisted as an event in Temporal's execution history. If the worker crashes and restarts, Temporal automatically **replays completed steps from history** without re-running them and resumes execution at the exact point of failure.

---

### 1.4 When to Use AI Agents vs. Traditional Automation

| Dimension | Use AI Agents When | Use Traditional Automation When |
| :--- | :--- | :--- |
| **Problem Type** | Problem requires reasoning to diagnose unknown or multi-variable errors. | Problem has a known, fixed solution (`if X then Y`). |
| **Root Causes** | Multiple possible causes and context-dependent fixes. | One predictable cause and one deterministic fix. |
| **Human Interaction** | Natural language root-cause synthesis helps human operators make decisions. | No human in the loop is required; silent execution is preferred. |
| **Real-World Examples** | Troubleshooting `CrashLoopBackOff`, root cause analysis, CI log diagnosis. | Horizontal Pod Autoscaling (HPA), scheduled restarts, standard CI/CD deploys. |

---

## Task 2: Set Up KubeHealer & Architecture

### 2.1 KubeHealer Architecture (`Temporal + Claude + kubectl`)

```text
+-----------------------------------------------------------------------------------+
|                            starter.py (Workflow Trigger)                          |
+-----------------------------------------------------------------------------------+
                                         |
                                         | Starts Durable Workflow
                                         v
+-----------------------------------------------------------------------------------+
|                      Temporal Server (localhost:7233 / UI :8233)                  |
|   [Persists Event History | Manages Retries & Timeouts | Handles Approval Signal] |
+-----------------------------------------------------------------------------------+
             |                           |                           |
             | Activity 1: Scan          | Activity 2: Diagnose      | Activity 3: Fix
             v                           v                           v
+-------------------------+ +-------------------------+ +---------------------------+
|   Cluster Scanner       | |   AI Diagnostic Engine  | |   Patch Executor          |
|   (worker.py)           | |   (Claude Sonnet 4)     | |   (worker.py)             |
+-------------------------+ +-------------------------+ +---------------------------+
| Runs:                   | | 1. Runs kubectl         | | 1. Waits for Human        |
| kubectl get pods        | |    describe & get events| |    Approval [yes/no]      |
| Identifies broken pods: | | 2. Sends diagnostics to | | 2. Runs kubectl patch     |
| - web-app               | |    Claude Sonnet 4      | |    on approved pods       |
| - memory-app            | | 3. Generates Root Cause | | 3. Skips & escalates      |
| - config-app            | |    + JSON Patch         | |    unfixable pods         |
+-------------------------+ +-------------------------+ +---------------------------+
```

### 2.2 Infrastructure & Environment Setup
KubeHealer lives in a dedicated repository and uses **Temporal** for durable execution, **Kind** for the local Kubernetes cluster, and **Claude Sonnet 4** (`ANTHROPIC_API_KEY`) for safe production diagnostic reasoning.

```bash
# 1. Clone the KubeHealer repository
git clone [https://github.com/TrainWithShubham/kubehealer.git](https://github.com/TrainWithShubham/kubehealer.git)
cd kubehealer

# 2. Create the local Kind Kubernetes cluster
kind create cluster --name kubehealer-demo

# 3. Start the Temporal development server (UI available at http://localhost:8233)
temporal server start-dev

# 4. Set up the Python virtual environment and install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 5. Configure the Anthropic API Key for Claude Sonnet 4
export ANTHROPIC_API_KEY="your-api-key-here"
```
<img width="3408" height="1916" alt="image" src="https://github.com/user-attachments/assets/03868cd8-6d34-42ef-b05f-ab2c3bf90b4a" />

---

## Task 3: Deploy Broken Applications

To test KubeHealer across both fixable and unfixable scenarios, three broken applications were deployed to the `default` namespace as Kubernetes Deployments (enabling declarative rolling patch remediation via `kubectl patch`):

### 3.1 App 1 — Image Typo (`web-app` — Fixable by the Agent)
The image name is misspelled as `ngnix:latest` instead of `nginx:latest`, triggering an `ImagePullBackOff` error.

```yaml
# web-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: web
          image: ngnix:latest
          ports:
            - containerPort: 80

```

### 3.2 App 2 — OOM Crash (`memory-app` — Fixable by the Agent)

The container memory limit is set to `1Mi`, which is far too low for the container runtime, causing an immediate `OOMKilled` (`Exit Code 137`) and `CrashLoopBackOff`.

```yaml
# memory-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: memory-app
  template:
    metadata:
      labels:
        app: memory-app
    spec:
      containers:
        - name: app
          image: nginx:alpine
          resources:
            limits:
              memory: "1Mi"
          command: ["sh", "-c", "echo 'starting' && sleep 3600"]

```

### 3.3 App 3 — Missing ConfigMap (`config-app` — NOT Fixable by the Agent)

This workload references a ConfigMap named `app-config` that does not exist in the cluster, resulting in `CreateContainerConfigError`. Because an AI agent should never fabricate arbitrary configuration data, it must diagnose this issue and escalate it to a human operator.

```yaml
# config-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: config-app
  template:
    metadata:
      labels:
        app: config-app
    spec:
      containers:
        - name: app
          image: nginx:alpine
          envFrom:
            - configMapRef:
                name: app-config

```

### 3.4 Verify All Three Applications Are Broken

```bash
$ kubectl apply -f web-app.yaml -f memory-app.yaml -f config-app.yaml
$ kubectl get pods
NAME                              READY   STATUS                       RESTARTS      AGE
pod/config-app-7cb865cbff-sr645   0/1     CreateContainerConfigError   0             83s
pod/memory-app-5c44784c7-2wsmw    0/1     RunContainerError            3 (40s ago)   83s
pod/web-app-68989cd5b8-nftwl      0/1     ImagePullBackOff             0             83s

```

<img width="2268" height="496" alt="image" src="https://github.com/user-attachments/assets/37faa140-804e-45da-bbac-b9433f39062c" />

---

## Task 4: Run KubeHealer (Scan, Diagnose, and Autonomous Remediation)

### 4.1 Start the Worker and Trigger a Healing Run
In Terminal 1, start the Temporal worker:
```bash
python3 worker.py

```

In Terminal 2, initiate the workflow run:

```bash
python3 starter.py

```

### 4.2 How KubeHealer Remediates the Cluster

1. **Scan Activity (`scan_pods`):** Discovers all pods across the target namespace (`default`) and flags workloads in error states (`ImagePullBackOff`, `CrashLoopBackOff`, and `CreateContainerConfigError`).
2. **Diagnostic Engine (`diagnose_pod`):** Analyzes pod events and telemetry to generate root causes and structured patch payloads:
* **`web-app`:** Identifies the typo in `ngnix:latest` and prepares a patch updating the container image to `nginx:latest`.
* **`memory-app`:** Identifies `OOMKilled` (`Exit Code 137`) caused by a 1Mi limit and prepares a patch raising memory limits to `128Mi`.
* **`config-app`:** Flags the missing ConfigMap `app-config`, classifies it as unfixable without operator intervention, and marks it with the `skip` action.


3. **Execution Activity (`execute_fix`):** Automatically applies rolling strategic patches to the fixable workloads and safely skips the missing dependency.

### 4.3 Actual Terminal Output

```text
$ python3 starter.py

🚀 Starting KubeHealer workflow (id=kubehealer-1792341980)...
   Namespace: default

Healed 2/3 pods:

  [-] config-app: skipped -- Missing ConfigMap 'app-config' cannot be auto-generated; escalating to human operator
  [+] web-app: fix_image -- Patched image to nginx:latest
  [+] memory-app: patch_resources -- Patched memory to 128Mi

📊 View workflow trace: http://localhost:8233/namespaces/default/workflows/kubehealer-1792341980

```

### 4.4 Post-Remediation Verification

Running `kubectl get deployments,pods` confirms that both auto-remediated services are fully restored, while `config-app` was escalated without causing destructive side-effects:

```text
$ kubectl get deployments,pods -o wide
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES         SELECTOR
deployment.apps/config-app    0/1     1            0           9m7s   app          nginx:alpine   app=config-app
deployment.apps/memory-app    1/1     1            1           9m7s   app          nginx:alpine   app=memory-app
deployment.apps/web-app       1/1     1            1           9m7s   web          nginx:latest   app=web-app

NAME                                  READY   STATUS                       RESTARTS   AGE    IP            NODE
pod/config-app-7cb865cbff-sr645       0/1     CreateContainerConfigError   0          9m7s   10.244.0.10   kubehealer-demo-control-plane
pod/memory-app-666789c8f4-h6grv       1/1     Running                      0          97s    10.244.0.11   kubehealer-demo-control-plane
pod/web-app-69774fc7cd-skxdq          1/1     Running                      0          97s    10.244.0.12   kubehealer-demo-control-plane

```

<img width="3240" height="858" alt="image" src="https://github.com/user-attachments/assets/fafa4a7e-966d-45ef-a5a7-2abc15bb9bcf" />


---

## Task 5: Test Crash Recovery (Temporal Durability)

To verify that KubeHealer is crash-resistant during live incidents, we tested killing the worker process mid-diagnosis.

### 5.1 Step-by-Step Crash Simulation
1. **Redeploy the three broken applications:**
   ```bash
   kubectl delete deployment web-app memory-app config-app
   kubectl apply -f web-app.yaml -f memory-app.yaml -f config-app.yaml
   ```
2. **Start the worker in the background and trigger a healing run:**
   ```bash
   python3 worker.py &
   python3 starter.py
   ```
3. **Kill the worker mid-diagnosis (before it asks for approval):**
   ```bash
   # Press Ctrl+C or terminate the background worker job
   kill %1
   ```
4. **Restart the worker:**
   ```bash
   python3 worker.py
   ```

### 5.2 How Crash Recovery Works Under the Hood
```text
[Worker Run #1]
  |-- Activity 1: scan_pods() -------------------> [COMPLETED & RECORDED IN TEMPORAL]
  |-- Activity 2: diagnose_pod("web-app") -------> [COMPLETED & RECORDED IN TEMPORAL]
  |-- Activity 2: diagnose_pod("memory-app") ----> [WORKER KILLED (kill %1 / Ctrl+C)]

[Worker Restarted: python3 worker.py]
  |-- Temporal replays Activity 1 result from Event History (0s, no duplicate kubectl call)
  |-- Temporal replays "web-app" diagnosis from Event History (0s, no duplicate Claude API call)
  |-- Worker resumes directly at diagnose_pod("memory-app") & diagnose_pod("config-app")
  |-- Workflow continues seamlessly to the Human Approval prompt!
```

<img width="3410" height="2026" alt="image" src="https://github.com/user-attachments/assets/aedca981-0918-4b08-b7d8-606023c2ab1a" />


### 5.3 Temporal Web UI Audit Trail (`http://localhost:8233`)
Opening `http://localhost:8233` and selecting the workflow execution displays:
* Every activity execution (`scan`, `diagnose`, `fix`) along with its exact input and output payloads.
* The exact crash and recovery boundary where the worker stopped and resumed.
* The complete execution timeline—serving as an automatic audit trail of every Claude API call, every `kubectl` command, and every applied patch.

<img width="3416" height="2054" alt="image" src="https://github.com/user-attachments/assets/91c2189c-09f6-4b52-b959-a295d392aa16" />

---

## Task 6: Reflect on the Agentic AI Journey

### 6.1 Map the 3-Day Progression (Days 87 to 89)

| Day | Module | What You Built | Pattern |
| :--- | :--- | :--- | :--- |
| **Day 87** | Modules 0–2 | Docker Error Explainer + Docker Agent | Basic LLM → Single-Domain ReAct Agent |
| **Day 88** | Modules 3, 6 | Multi-Tool Agent + MCP Server + CI/CD Analyzer | Multi-domain tools, Model Context Protocol (MCP) |
| **Day 89** | Modules 4–5 | **KubeHealer** — Production Self-Healing Agent | Temporal durability, human approval, production guardrails |

```text
Day 87: LLM explains errors (passive)
   |
   v
Day 88: Agent diagnoses across Docker / K8s / CI (autonomous investigation)
   |
   v
Day 89: Agent diagnoses AND fixes with approval (autonomous action)
```

---

### 6.2 Key Principles for Production AI Agents
1. **Tools are just CLI wrappers:** Any command you run (`docker`, `kubectl`, `gh`, `terraform`) can become a tool.
2. **The ReAct pattern is universal:** `Reason → Act → Observe` works across any infrastructure domain.
3. **MCP standardizes tool access:** Write your tools once in an MCP server and use them across any compatible client everywhere.
4. **Guardrails are not optional:** Human approval, scope limits, rollback capability, and audit trails are mandatory in production.
5. **Durability matters:** Temporal prevents lost state and partial fixes during infrastructure changes.
6. **Know when NOT to use AI:** Simple `if/then` automation is faster, cheaper, and safer for known, deterministic problems.

---

### 6.3 Where Agentic AI Connects to the Rest of the 90-Day Challenge

| Challenge Days | Topic | Connection to Agentic AI |
| :--- | :--- | :--- |
| **Days 29–37** | **Docker** | Docker tools in Module 2 wrap the exact same container inspection commands learned in the Docker labs. |
| **Days 40–49** | **GitHub Actions** | The CI/CD Analyzer in Module 6 diagnoses the workflow pipelines built during the CI/CD modules. |
| **Days 50–67** | **Kubernetes** | Kubernetes tools in Module 3 and KubeHealer use `kubectl get`, `describe`, `events`, and `patch`. |
| **Days 73–77** | **Observability** | Agents can query Prometheus and Loki endpoints for metric- and log-based anomaly diagnosis. |
| **Days 84–86** | **Argo CD** | Production agents can trigger Argo CD syncs, check application health, or initiate GitOps rollbacks. |

---

### 6.4 Clean Up
```bash
# 1. Delete the Kind cluster
kind delete cluster --name kubehealer-demo

# 2. Stop Temporal server (press Ctrl+C in the Temporal terminal)

# 3. Deactivate the Python virtual environment
deactivate
```
