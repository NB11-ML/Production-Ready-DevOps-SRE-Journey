# Day-88 Multi-Tool Agents, Model Context Protocol (MCP), and CI/CD Failure Analyzer

## Task 1: Build & Run the Multi-Tool DevOps Agent (Module 3)

In this task, you expand yesterday's 3-tool Docker agent into a 6-tool cross-domain agent that troubleshoots both local Docker containers and a Kubernetes cluster simultaneously.

### Step 1.1: Activate Your Environment & Check Model Alias

Navigate to your `agentic-ai-for-devops` repository and activate your virtual environment:

```bash
cd  Agentic-AI/agentic-ai-for-devops
source .venv/bin/activate

```

### Step 1.2: Create the Kind Cluster and Deploy `broken-pod`

Spin up a lightweight local Kubernetes cluster using Kind and deploy the failing pod manifest:

```bash
# Create local Kind cluster
kind create cluster --name devops-demo

# Deploy the intentionally broken pod
kubectl apply -f module-3/broken_pod.yaml

# Verify the pod is entering CrashLoopBackOff / Error
kubectl get pods -n default

```

### Step 1.3: Start the Broken Docker Container

Create a failing container on your local Docker daemon so both environments have active incidents:

```bash
docker run -d --restart always --name broken-container nginx:alpine sh -c "echo 'container starting...' && sleep 2 && exit 1"

# Verify container state
docker ps -a | grep broken-container

```

### Step 1.4: Review `module-3/agent.py`

Inspect the 6 tools registered in `module-3/agent.py`:

```bash
cat module-3/agent.py

```

Notice how both toolsets coexist in a single list:

* **Docker Domain:** `list_containers`, `get_logs`, `inspect_container`
* **Kubernetes Domain:** `list_pods`, `describe_pod`, `get_events`

### Step 1.5: Run the Multi-Tool Agent & Test Cross-Domain Reasoning

Launch the agent:

```bash
python module-3/agent.py

```

Test it with these four prompts one by one (**take a screenshot of the output for your documentation**):

1. `> What's broken across Docker and Kubernetes?`
* *Watch the ReAct loop:* The LLM calls `list_containers()` for Docker AND `list_pods()` for Kubernetes, spots both `broken-container` and `broken-pod`, and investigates each using its respective domain tools.

<img width="1698" height="1120" alt="image" src="https://github.com/user-attachments/assets/0ac59e8a-0f8e-493b-a73f-669256c84ca5" />



2. `> Why is broken-pod crashing?`
* *Watch the ReAct loop:* Calls `describe_pod(pod_name="broken-pod", namespace="default")` and reads the container command (`exit 1`) and BackOff events.

<img width="1686" height="1142" alt="image" src="https://github.com/user-attachments/assets/0ea81247-f86b-494f-9858-18e929cde7b1" />


3. `> Are there any unhealthy containers on Docker?`
* *Watch the ReAct loop:* Calls `list_containers()`, `get_logs(container_name="broken-container")`, and `inspect_container(container_name="broken-container")`.


4. `> Describe the events in the default namespace`
* *Watch the ReAct loop:* Calls `get_events(namespace="default")` and summarizes the `Pulled`, `Created`, `Started`, and `BackOff` timeline.


<img width="1702" height="1158" alt="image" src="https://github.com/user-attachments/assets/157e8d0c-d2c5-4bf8-a476-8f95ade8ef77" />


Type `quit` to exit the interactive prompt.

---

## Task 2 & Task 3: Build and Use the Model Context Protocol (MCP) Server

Instead of hardcoding `@tool` functions inside every Python agent script, **MCP (Model Context Protocol)** lets you expose tools as a standalone server that any MCP client (LangChain, Claude Desktop, Cursor, VS Code Copilot) can discover dynamically.

### Step 3.1: Inspect the MCP Server (`module-3/mcp_server.py`)

Check how `FastMCP` exposes the Kubernetes tools:

```bash
cat module-3/mcp_server.py

```

Key architectural shifts from standard LangChain tools:

* Uses `mcp = FastMCP("Kubernetes Tools")` to initialize a standard protocol server.
* Decorates functions with `@mcp.tool` instead of `@tool`.
* Starts a `stdio` transport listener via `mcp.run()`.

### Step 3.2: Inspect & Run the MCP Client Agent (`module-3/agent_with_mcp.py`)

Review `module-3/agent_with_mcp.py`:

```bash
cat module-3/agent_with_mcp.py

```

Notice that `agent_with_mcp.py` **contains zero `subprocess` or `kubectl` code**. Instead, it uses `MultiServerMCPClient` to spawn `mcp_server.py` over `stdio`, dynamically fetches the tool schemas via `await client.get_tools()`, and binds them to `ChatOllama`.

Run the MCP client agent:

```bash
cd module-3
python agent_with_mcp.py

```

<img width="2840" height="1060" alt="image" src="https://github.com/user-attachments/assets/fcda1f66-21d8-49c5-959e-30e9c147fefa" />


Ask these prompts at the `> ` prompt:

1. `> List the pods in my cluster`
2. `> Why is broken-pod crashing?`
3. `> What events happened recently?`

<img width="2842" height="1890" alt="image" src="https://github.com/user-attachments/assets/f4168e89-8954-4f96-a4c5-4fd08bcbaf8c" />
<img width="2830" height="480" alt="image" src="https://github.com/user-attachments/assets/a6f363ce-b77c-4ae2-89f7-dda707de6db7" />


Type `quit` and return to the repository root:

```bash
cd ..

```

### Step 3.3: (Optional) Connect Your MCP Server to Claude Desktop on macOS

If you use Claude Desktop on your MacBook, you can expose your local Kubernetes cluster to it by editing `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "kubernetes-tools": {
      "command": "/agentic-ai-for-devops/.venv/bin/python",
      "args": [
        "agentic-ai-for-devops/module-3/mcp_server.py"
      ]
    }
  }
}

```

*(Using the `.venv/bin/python` path ensures `fastmcp` is found by Claude Desktop).*

---

## Task 4: Build & Run the CI/CD Failure Analyzer (Module 6)

Now you apply the ReAct pattern to GitHub Actions pipelines using the `gh` CLI.

### Step 4.1: Verify GitHub CLI Authentication

Ensure your `gh` CLI is logged in and authenticated with your GitHub account (`NB11-ML`):

```bash
gh auth status

```

If not logged in, run `gh auth login`.

### Step 4.2: Inspect `module-6/ci_analyzer.py`

Check the three tools inside `module-6/ci_analyzer.py`:

```bash
cat module-6/ci_analyzer.py

```

* `list_workflow_runs(status="failure")` $\rightarrow$ wraps `gh run list --status <status> --limit 5`
* `get_failed_logs(run_id)` $\rightarrow$ wraps `gh run view <run_id> --log-failed` and **truncates output to 5,000 characters** so massive build logs don't overflow the LLM context window.
* `get_workflow_file(workflow_name)` $\rightarrow$ reads `.github/workflows/<workflow_name>` from disk so the LLM can correlate log errors with the actual YAML syntax.

### Step 4.3: Run the CI Analyzer Inside `AI-BankApp-DevOps`

Switch to your `AI-BankApp-DevOps` repository (while keeping your `.venv` active) and invoke `ci_analyzer.py`:

```bash
python agentic-ai-for-devops/module-6/ci_analyzer.py

```

Test the agent with these prompts (**take a screenshot of this output for your documentation**):

1. `> Show me the recent workflow runs`
2. `> What failed in my last CI run?`
3. `> Read the gitops-ci.yml workflow file and explain what it does`

<img width="3414" height="1226" alt="image" src="https://github.com/user-attachments/assets/b837058d-d707-463b-adde-dd0134fb94b4" />
<img width="3402" height="884" alt="image" src="https://github.com/user-attachments/assets/f294b50c-5e6d-4114-ad2d-23a5df07cd9a" />

*(Optional Test)*: If you don't have a recent failed run in `AI-BankApp-DevOps`, you can trigger a quick failure on a test branch or repo by adding `.github/workflows/broken-ci.yml` with `run: npm test` (where no `package.json` exists), pushing it, and asking:
`> Why did broken-ci fail?`

<img width="3162" height="390" alt="image" src="https://github.com/user-attachments/assets/6fba294c-8b4e-48d4-a007-f1b0c6630e7b" />


---

## Task 5: Build Your Own Custom DevOps Tool (`search_logs`)

Let's implement **Option C (`search_logs`)**—and also include **Option B (`list_ec2_instances`)** as a bonus reference—by adding `search_logs` directly into `module-3/agent.py` so your Multi-Tool DevOps Agent can grep across all pod logs in a Kubernetes namespace at once.

### Step 5.1: Update `module-3/agent.py` with `search_logs`

Navigate back to `agentic-ai-for-devops` and update `module-3/agent.py`:

```bash
cd  Agentic-AI/agentic-ai-for-devops

```

Here is the complete `module-3/agent.py` with `search_logs` added as the 7th tool:

```python
"""
Multi-Tool DevOps Agent — troubleshoots both Docker and Kubernetes with custom log search.
Run: python module-3/agent.py
"""

import subprocess
from langchain_ollama import ChatOllama
from langchain_core.tools import tool
from langchain.agents import create_agent as create_react_agent


# --- Docker Tools ---
@tool
def list_containers() -> str:
    """List all Docker containers (running and stopped)."""
    result = subprocess.run(["docker", "ps", "-a"], capture_output=True, text=True)
    return result.stdout or result.stderr


@tool
def get_logs(container_name: str) -> str:
    """Get the last 50 lines of logs from a Docker container."""
    result = subprocess.run(
        ["docker", "logs", "--tail", "50", container_name],
        capture_output=True,
        text=True,
    )
    return result.stdout + result.stderr


@tool
def inspect_container(container_name: str) -> str:
    """Get detailed info about a Docker container (state, config, network)."""
    result = subprocess.run(
        ["docker", "inspect", container_name],
        capture_output=True,
        text=True,
    )
    return result.stdout or result.stderr


# --- Kubernetes Tools ---
@tool
def list_pods(namespace: str = "default") -> str:
    """List all pods in a Kubernetes namespace with their status."""
    result = subprocess.run(
        ["kubectl", "get", "pods", "-n", namespace],
        capture_output=True,
        text=True,
    )
    return result.stdout or result.stderr


@tool
def describe_pod(pod_name: str, namespace: str = "default") -> str:
    """Get detailed info about a Kubernetes pod including events and conditions."""
    result = subprocess.run(
        ["kubectl", "describe", "pod", pod_name, "-n", namespace],
        capture_output=True,
        text=True,
    )
    return result.stdout or result.stderr


@tool
def get_events(namespace: str = "default") -> str:
    """Get recent Kubernetes events in a namespace (useful for troubleshooting)."""
    result = subprocess.run(
        ["kubectl", "get", "events", "-n", namespace, "--sort-by=.lastTimestamp"],
        capture_output=True,
        text=True,
    )
    return result.stdout or result.stderr


# --- Task 5 Custom Tool: Namespace-Wide Pod Log Searcher ---
@tool
def search_logs(keyword: str, namespace: str = "default") -> str:
    """Search for a specific keyword across the logs of all pods in a Kubernetes namespace."""
    pods = subprocess.run(
        ["kubectl", "get", "pods", "-n", namespace, "-o", "name"],
        capture_output=True,
        text=True,
    )
    results = []
    for pod in pods.stdout.strip().split("\n"):
        if not pod:
            continue
        logs = subprocess.run(
            ["kubectl", "logs", pod, "-n", namespace, "--tail=100"],
            capture_output=True,
            text=True,
        )
        if keyword.lower() in logs.stdout.lower():
            results.append(f"{pod}: found '{keyword}' -> {logs.stdout.strip()}")
    return "\n".join(results) if results else f"No pods contain '{keyword}' in their logs"


llm = ChatOllama(model="gemma4", temperature=0)
tools = [
    list_containers,
    get_logs,
    inspect_container,
    list_pods,
    describe_pod,
    get_events,
    search_logs,
]
agent = create_react_agent(llm, tools)

print("\nMulti-Tool DevOps Agent (Docker + Kubernetes + Log Search)")
print("-" * 58)
print("Ask me about Docker or Kubernetes. Type 'quit' to exit.\n")

while True:
    question = input("> ").strip()
    if question.lower() in ("quit", "exit", "q"):
        break
    if not question:
        continue

    print("\nThinking...\n")
    result = agent.invoke({"messages": [("user", question)]})
    print(result["messages"][-1].content)
    print()

```

### Step 5.2: Test Your Custom Tool

Run `python module-3/agent.py` and ask:

```text
> Search all pod logs in the default namespace for the keyword "starting"

```
<img width="1700" height="492" alt="image" src="https://github.com/user-attachments/assets/c8c3b091-88f3-4a1c-8ac1-6a8880d22a64" />

*How the agent decides to use it:* The LLM parses the intent ("Search all pod logs... for the keyword") and matches it directly against the docstring `"""Search for a specific keyword across the logs of all pods in a Kubernetes namespace."""`, passing `keyword="starting"` and `namespace="default"` to `search_logs()`. It immediately finds `pod/broken-pod: found 'starting' -> app starting...`.

---

## Task 6: Clean Up Your Local Lab Environment

Once you have captured your screenshots, tear down the Kind cluster and broken Docker container so they don't consume background RAM/CPU on your MacBook:

```bash
# Delete the Kind cluster
kind delete cluster --name devops-demo

# Remove the broken Docker container
docker rm -f broken-container 2>/dev/null

# Deactivate virtual environment when finished
deactivate

```

---

