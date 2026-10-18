# Day 88: Multi-Tool Agents, Model Context Protocol (MCP), and CI/CD Failure Analyzer

## 1. Multi-Tool Agent Architecture (6 Tools Across 2 Domains)

In Day 87, the agent was restricted to a single domain (Docker). In Day 88, the ReAct agent is expanded to reason across **two distinct infrastructure domains—Docker and Kubernetes**—using a single LLM brain (`gemma4:12b` via Ollama).

### Architecture Diagram
```text
+-----------------------------------------------------------------------------+
|                                User Prompt                                  |
|              ("What's broken across Docker and Kubernetes?")                |
+-----------------------------------------------------------------------------+
                                      |
                                      v
+-----------------------------------------------------------------------------+
|                        LLM Brain (Gemma 4 via Ollama)                       |
|                   [LangGraph ReAct Loop | temperature=0]                    |
+-----------------------------------------------------------------------------+
                                      |
            +-------------------------+-------------------------+
            |      Reads @tool docstrings to route domain       |
            v                                                   v
+-----------------------------------+       +-----------------------------------+
|        Docker Domain Tools        |       |      Kubernetes Domain Tools      |
+-----------------------------------+       +-----------------------------------+
| 1. list_containers()              |       | 4. list_pods(namespace)           |
|    -> `docker ps -a`              |       |    -> `kubectl get pods -n <ns>`  |
|                                   |       |                                   |
| 2. get_logs(container_name)       |       | 5. describe_pod(pod_name, ns)     |
|    -> `docker logs --tail 50`     |       |    -> `kubectl describe pod`      |
|                                   |       |                                   |
| 3. inspect_container(name)        |       | 6. get_events(namespace)          |
|    -> `docker inspect`            |       |    -> `kubectl get events`        |
+-----------------------------------+       +-----------------------------------+
            |                                                   |
            +-------------------------+-------------------------+
                                      |
                                      v
+-----------------------------------------------------------------------------+
|                     Observation (stdout / stderr strings)                   |
|        Fed back into LLM context until root cause is confirmed for both     |
+-----------------------------------------------------------------------------+
                                      |
                                      v
+-----------------------------------------------------------------------------+
|                    Unified Cross-Domain Incident Report                     |
+-----------------------------------------------------------------------------+
```

### Why Single-Brain Multi-Tool Routing Works
Separate `if/else` routers for Docker vs. Kubernetes are not required. By providing clear, domain-specific docstrings on each `@tool` function, the LLM dynamically selects:
* **Docker tools** when asked about containers, daemon logs, or local port bindings.
* **Kubernetes tools** when asked about pods, namespaces, replica states, or cluster events.
* **Both toolsets sequentially** when asked an overarching infrastructure health question like *"What's broken across Docker and Kubernetes?"*

---

## 2. Multi-Tool Agent Diagnosing Docker & Kubernetes Issues

### Lab Setup
A local Kind cluster (`devops-demo`) with a crashing pod (`broken-pod`) was provisioned alongside a crashing local Docker container (`broken-container`):
```bash
kind create cluster --name devops-demo
kubectl apply -f module-3/broken_pod.yaml
docker run -d --restart always --name broken-container nginx:alpine sh -c "echo 'container starting...' && sleep 2 && exit 1"
```

### Agent Execution Trace (`module-3/agent.py`)
```text
$ python3 module-3/agent.py

Multi-Tool DevOps Agent (Docker + Kubernetes)
---------------------------------------------
Ask me about Docker or Kubernetes. Type 'quit' to exit.

> What's broken across Docker and Kubernetes?

Thinking...

[Tool Call] list_containers()
[Tool Call] list_pods(namespace='default')
[Tool Call] get_logs(container_name='broken-container')
[Tool Call] inspect_container(container_name='broken-container')
[Tool Call] describe_pod(pod_name='broken-pod', namespace='default')

Here is the diagnosis of broken resources across both environments:

1. Docker Environment (`broken-container`):
   - Status: Restarting (1) continuously.
   - Logs: Outputs "container starting..." and terminates.
   - Root Cause: The container entrypoint command (`sh -c "echo 'container starting...' && sleep 2 && exit 1"`) forces an explicit exit code 1 after 2 seconds.

2. Kubernetes Environment (`broken-pod` in `default` namespace):
   - Status: CrashLoopBackOff (Restarts: 4).
   - Events: `Back-off restarting failed container app in pod broken-pod_default`.
   - Root Cause: The pod spec overrides the `nginx:alpine` command with `["sh", "-c", "echo 'app starting...' && sleep 2 && exit 1"]`, causing the container to exit with code 1 immediately after startup.
```

![Multi-Tool Agent Diagnosing Docker and K8s](./screenshots/multi-tool-agent-docker-k8s.png)

---

## 3. Model Context Protocol (MCP) Explained

**Model Context Protocol (MCP)** is an open standard (introduced by Anthropic) that standardizes how AI applications connect to external tools, CLIs, and data sources.

### Core Components of MCP
1. **MCP Server (`mcp_server.py`):** A lightweight process built with frameworks like `FastMCP` that wraps CLI commands or APIs (`kubectl`, `docker`, `gh`) and exposes them over a standard transport protocol.
2. **MCP Client (`agent_with_mcp.py`, Claude Desktop, Cursor, VS Code Copilot):** Any AI application or agent runtime that connects to the MCP Server, dynamically queries available tools (`client.get_tools()`), and invokes them during reasoning.
3. **MCP Protocol & Transport (`stdio` / `SSE` / `HTTP`):** A JSON-RPC 2.0 wire protocol. Local tools run seamlessly over standard input/output (`stdio`), while remote enterprise tools run over HTTP/SSE.

```text
+-----------------------------------+            +-----------------------------------+
|            MCP Server             |            |            MCP Clients            |
|     (FastMCP: mcp_server.py)      |            +-----------------------------------+
+-----------------------------------+            | - LangChain (agent_with_mcp.py)   |
| @mcp.tool: list_pods()            |   stdio    | - Claude Desktop / Claude Code    |
| @mcp.tool: describe_pod()         | <========> | - Cursor IDE                      |
| @mcp.tool: get_events()           |  JSON-RPC  | - VS Code (GitHub Copilot)        |
+-----------------------------------+            +-----------------------------------+
```

### Why MCP Matters for DevOps & SRE Tooling
* **Write Once, Run Anywhere:** Instead of rewriting `kubectl` and `terraform` Python wrappers separately for LangChain, Claude Desktop, and IDE copilots, a platform engineering team writes **one** MCP server and shares it across every AI interface.
* **Decoupled Architecture:** Upgrading or fixing a tool inside the MCP server immediately updates capabilities for all connected agents without touching agent orchestration code.

---

## 4. How MCP Server Tools Differ from Hardcoded LangChain Tools

| Feature | Hardcoded LangChain Tools (`module-3/agent.py`) | MCP Server Tools (`module-3/mcp_server.py` + `agent_with_mcp.py`) |
| :--- | :--- | :--- |
| **Decorator** | `@tool` (from `langchain_core.tools`) | `@mcp.tool` (from `fastmcp`) |
| **Where Tools Live** | Coupled directly inside the agent Python script. | Hosted in an independent server process (`mcp_server.py`). |
| **Tool Discovery** | Static Python list: `tools = [list_pods, describe_pod]` | Dynamic runtime discovery: `tools = await client.get_tools()` |
| **Portability** | Locked to LangChain / LangGraph scripts only. | Reusable in Claude Desktop, VS Code, Cursor, and LangChain via `MultiServerMCPClient`. |
| **Execution Model** | Direct in-process Python function call. | Asynchronous client-server RPC over `stdio` or HTTP. |

---

## 5. Module 6: CI/CD Failure Analyzer in Action

The CI/CD Failure Analyzer wraps the GitHub CLI (`gh`) into three tools (`list_workflow_runs`, `get_failed_logs`, `get_workflow_file`) to autonomously inspect failed GitHub Actions pipelines.

### Why Log Truncation Is Critical
CI/CD build logs frequently exceed 50,000–100,000 characters. Sending raw, unbounded logs overflows the LLM's context window or degrades reasoning accuracy. In `get_failed_logs()`, truncating `gh run view <run_id> --log-failed` to `5000` characters (`output[:5000]`) keeps only the critical failed step output within token limits.

### Terminal Output (`AI-BankApp-DevOps`)
```text
$cd AI-BankApp-DevOps$ python3 ../agentic-ai-for-devops/module-6/ci_analyzer.py

CI/CD Failure Analyzer Agent
----------------------------
> What failed in my last CI run and how is gitops-ci.yml configured?

Thinking...

[Tool Call] list_workflow_runs(status='failure')
[Tool Call] get_failed_logs(run_id='18492031842')
[Tool Call] get_workflow_file(workflow_name='gitops-ci.yml')

Diagnosis of Failed CI Run:
1. Failed Workflow: `GitOps CI/CD Pipeline` (Run ID: 18492031842) on branch `feat/gitops`.
2. Root Cause from Failed Step Logs:
   The `Update Kubernetes Manifest & Push` step failed during `git push origin feat/gitops` with:
   `! [rejected] feat/gitops -> feat/gitops (fetch first)`
   `error: failed to push some refs`
   This occurred because another commit landed on `origin/feat/gitops` while the Docker build was still running.
3. Workflow Analysis (`gitops-ci.yml`):
   The workflow builds the Maven Spring Boot artifact, builds and pushes `nb1991/ai-bankapp-eks:<sha>` to DockerHub, updates `k8s/bankapp-deployment.yml` using `sed`, and commits the image tag back to the repository with a `git fetch` and `git rebase` retry loop to prevent race conditions.
```

![CI/CD Analyzer Diagnosing GitHub Actions](./screenshots/cicd-failure-analyzer.png)

---

## 6. Custom Tool Built: Namespace-Wide Pod Log Searcher (`search_logs`)

For Task 5, we built the **`search_logs`** tool (Option C) and integrated it into `module-3/agent.py`.

### Custom Tool Implementation
```python
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
```

### How the Agent Decided to Use `search_logs`
* **User Prompt:** `> Search all pod logs in the default namespace for the keyword "starting"`
* **Tool Selection Reasoning:** Instead of calling `list_pods` and then looping over `kubectl logs` manually across multiple turns, the LLM matched the phrase *"Search all pod logs... for the keyword"* directly to the docstring `"""Search for a specific keyword across the logs of all pods in a Kubernetes namespace."""`.
* **Execution & Output:** The agent invoked `search_logs(keyword="starting", namespace="default")` in a single step and returned:
  `pod/broken-pod: found 'starting' -> app starting...`

---

## 7. Universal CLI-to-Agent Tool Pattern Template

Any DevOps CLI (`docker`, `kubectl`, `terraform`, `aws`, `gh`, `ansible`, `helm`) can be converted into an autonomous agent capability using this standardized template:

```python
import subprocess
from langchain_core.tools import tool

@tool
def <tool_name>(<arg_name>: str = "<default_value>") -> str:
    """
    <Clear, LLM WHAT WHEN and choose description does it natural-language of other over should specific the tool tools.>
    """
    result = subprocess.run(
        ["<cli-binary>", "<subcommand>", "--flag", <arg_name>],
        capture_output=True,
        text=True,
    )
    output = result.stdout + result.stderr

    # Guardrail: Truncate large outputs to protect LLM context window
    if len(output) > 5000:
        output = output[:5000] + "\n\n[...truncated to 5000 chars]"

    return output or "Command executed successfully with no output."
```

### Key Engineering Rules for Reliable DevOps Tools
1. **Docstrings Are Routing Rules:** Write docstrings for the LLM, not just human developers. State the domain, resource type, and exact diagnostic purpose.
2. **Always Capture Both `stdout` and `stderr`:** CLI failures write to `stderr`. Returning `result.stdout + result.stderr` ensures the agent actually sees error messages instead of an empty string.
3. **Truncate Verbose Outputs:** Always cap log/plan outputs (`[:5000]`) so `kubectl logs`, `terraform plan`, or `gh run view` never blow up token limits.

```
