# Day 87 -- Introduction to Agentic AI for DevOps

## Task 1: Understand Agentic AI for DevOps

This phase focuses on the architectural shift from passive text generation (chatbots) to autonomous execution loops (agents) in infrastructure management.

### 1. AI Agents vs. Standard Chatbots

| Feature | Standard LLM Chatbot | Agentic AI |
| --- | --- | --- |
| **Core Capability** | Generates text based on training data and prompt context. | Reasons through problems and executes external tools/commands. |
| **System Interaction** | Passive (isolated from your host environment). | Active (runs CLI commands, reads logs, queries APIs). |
| **Workflow** | Single-turn: Prompt $\rightarrow$ Response. | Multi-turn loop: Reason $\rightarrow$ Act $\rightarrow$ Observe $\rightarrow$ Repeat. |
| **DevOps Utility** | Writes boilerplate YAML or explains static errors pasted by a human. | Autonomously inspects live clusters/daemons, pulls logs, and pinpoints root causes. |

### 2. Why Agents Fit DevOps Workflows

DevOps and SRE workflows are fundamentally CLI-driven (`docker`, `kubectl`, `terraform`, `gh`, `ansible`, `aws`). Every diagnostic action follows an investigative loop: run a command, inspect `stdout`/`stderr`, formulate a hypothesis, and run the next command.

An AI agent wraps these exact CLI binaries inside Python functions (`@tool`). Instead of a human copying and pasting terminal outputs into a chat window, the agent executes the CLI directly via `subprocess.run`, parses the standard output, and decides the next diagnostic step autonomously.

### 3. The ReAct (Reason + Act) Pattern

The **ReAct** framework enables an LLM to interleave verbal reasoning traces with tool execution actions:

1. **Thought (Reason):** The LLM analyzes the user's goal and current state, deciding what information is missing.
2. **Action (Act):** The LLM selects a registered `@tool` based on its docstring and passes the required arguments.
3. **Observation (Observe):** The Python runtime executes the underlying CLI command and feeds the raw text output back to the LLM.
4. **Loop / Final Answer:** The LLM evaluates the observation. If the root cause is still unclear, it triggers another **Thought $\rightarrow$ Action $\rightarrow$ Observation** cycle. Once confirmed, it synthesizes the final response.

---

## Task 2: Set Up the Local Environment

Follow these steps in your terminal to set up the workspace, local LLM runtime, and Python virtual environment.

### Step 2.1: Clone the Repository

```bash
git clone https://github.com/TrainWithShubham/agentic-ai-for-devops.git
cd agentic-ai-for-devops

```

### Step 2.2: Install and Start Ollama (macOS)

Install the Ollama binary via Homebrew, start the background service, and pull the `gemma4` model:

```bash
# Install Ollama on macOS
brew install ollama

# Start the Ollama runtime server in the background
ollama serve &

# Pull the Gemma 4 model (~5GB)
ollama pull gemma4

# Verify the model is downloaded and registered
ollama list

```

**Expected `ollama list` Output:**

<img width="1276" height="284" alt="image" src="https://github.com/user-attachments/assets/6a13a2b5-1927-44de-bbb2-541ea1eab34e" />


### Step 2.3: Configure the Python Virtual Environment

Create an isolated `.venv` and install the LangChain, LangGraph, and Ollama bindings:

```bash
# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Upgrade pip and install dependencies
pip install --upgrade pip
pip install -r requirements.txt

```
<img width="1696" height="322" alt="image" src="https://github.com/user-attachments/assets/d8207bf3-2d9c-4c04-b303-8364f1383536" />

### Step 2.4: Run the Pre-Flight Verification Script

Ensure Docker Desktop (or OrbStack) and your Kubernetes tools (`kubectl`, `kind`) are running, then execute the verification script:

```bash
python3 module-0/verify_setup.py

```

**Expected Output:**

```text
  [PASS] Python 3.10+
  [PASS] Docker
  [PASS] kubectl
  [PASS] Kind
  [PASS] Ollama + gemma4

  5/5 -- you're ready for Day 1!

```

<img width="1706" height="628" alt="image" src="https://github.com/user-attachments/assets/9c259d36-d1c3-4e05-bc5a-4d459ee251c6" />

*(Note: If `kind` is missing on your MacBook, install it quickly via `brew install kind` and re-run the check).*

---

## Task 3: Build & Test the Docker Error Explainer (Module 1)

Module 1 demonstrates a direct, zero-tool LLM call using `ollama.chat()`.

### Step 3.1: Inspect `module-1/explainer.py`

Check the contents of the script to see how `SYSTEM_PROMPT` and `temperature` are configured:

```bash
cat module-1/explainer.py

```

```python
import ollama

SYSTEM_PROMPT = """You are a Docker expert. When given a Docker error, explain:
1. What went wrong (plain English)
2. Most likely cause
3. How to fix it (with commands)
Keep it short."""

error = input("Paste your Docker error:\n> ")

response = ollama.chat(
    model="gemma4",
    messages=[
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": error},
    ],
    options={"temperature": 0.3},
)

print("\n--- Explanation ---")
print(response["message"]["content"])

```

### Step 3.2: Run the Explainer Against Common Docker Errors

Execute the script and test all three error scenarios (take a screenshot of this terminal output for your documentation):

**Test 1: Container Name Conflict**

```bash
python3 module-1/explainer.py

```

Paste when prompted:

```text
docker: Error response from daemon: Conflict. The container name "/myapp" is already in use.

```

<img width="2964" height="1312" alt="image" src="https://github.com/user-attachments/assets/5f149c51-ef6b-4cc0-a49a-adf5b3137ae7" />


**Test 2: Host Port Allocation Conflict**

```bash
python3 module-1/explainer.py

```

Paste when prompted:

```text
Error response from daemon: driver failed programming external connectivity on endpoint myapp: Bind for 0.0.0.0:8080 failed: port is already allocated.

```

<img width="2970" height="1642" alt="image" src="https://github.com/user-attachments/assets/3e72d0e2-aefe-4579-89f0-502d3307c1ba" />


**Test 3: Registry Authentication / Pull Denied**

```bash
python3 module-1/explainer.py

```

Paste when prompted:

```text
Error response from daemon: pull access denied for mycompany/private-app, repository does not exist or may require 'docker login'.

```

<img width="3418" height="1190" alt="image" src="https://github.com/user-attachments/assets/37cf1682-2501-4fbd-9a2f-09be96fb5350" />

### Step 3.3: Experiment with System Prompt & Temperature

To document how parameters control LLM behavior, test modifying `module-1/explainer.py`:

1. **System Prompt Impact:** If you change `SYSTEM_PROMPT` to `"You are a senior SRE writing a post-mortem. Provide a deep architectural breakdown and bash remediation script"`, the output shifts from a brief 3-bullet summary to a comprehensive root-cause analysis. Without a system prompt, the LLM tends to be verbose and unstructured.
2. **Temperature Impact (`0.3` vs `0.9`):** Setting `temperature: 0.0` or `0.3` forces greedy/high-probability token selection, making technical commands predictable and repeatable. Raising it to `0.9` increases randomness, which risks hallucinating non-existent CLI flags.

---

## Task 4: Build & Run the Docker Troubleshooter Agent (Module 2)

Now you transition from a static text explainer to an autonomous **ReAct Agent** that interacts directly with your local Docker daemon.

### Step 4.1: Simulate a Crashing Container

Run an Nginx container configured to fail after 2 seconds and automatically restart (`--restart always` or default loop diagnosis):

```bash
docker run -d --restart always --name broken-app nginx:alpine sh -c "echo 'app starting...' && sleep 2 && exit 1"

```

Verify it is failing:

```bash
docker ps -a | grep broken-app

```

<img width="3062" height="828" alt="image" src="https://github.com/user-attachments/assets/78748057-c713-4e8a-a25c-627f1385ddbd" />


### Step 4.2: Inspect `module-2/agent.py`

Review how `@tool` wrappers and `create_react_agent` work together:

```python
import subprocess
from langchain_ollama import ChatOllama
from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent

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
        capture_output=True, text=True,
    )
    return result.stdout + result.stderr

@tool
def inspect_container(container_name: str) -> str:
    """Get detailed info about a Docker container (state, config, network)."""
    result = subprocess.run(
        ["docker", "inspect", container_name],
        capture_output=True, text=True,
    )
    return result.stdout or result.stderr

llm = ChatOllama(model="gemma4", temperature=0)
tools = [list_containers, get_logs, inspect_container]
agent = create_react_agent(llm, tools)

```

### Step 4.3: Run the Agent and Diagnose `broken-app`

Start the interactive agent session:

```bash
python3 module-2/agent.py

```

Enter the following prompts one by one (capture a screenshot of the `broken-app` diagnosis for your markdown deliverable):

1. **Prompt 1:**
```text
> Why is broken-app crashing?

```
<img width="3414" height="1264" alt="image" src="https://github.com/user-attachments/assets/4b95b6e8-96f5-4499-abba-6699440bd145" />


*Watch the execution trace:*
* **Tool Call 1:** `list_containers()` $\rightarrow$ Detects `broken-app` is in `Restarting (1)` state.
* **Tool Call 2:** `get_logs(container_name="broken-app")` $\rightarrow$ Sees repeated `app starting...` output.
* **Tool Call 3:** `inspect_container(container_name="broken-app")` $\rightarrow$ Inspects `.State.ExitCode` (`1`) and `.Config.Cmd` (`sh -c "echo 'app starting...' && sleep 2 && exit 1"`).
* **Final Output:** Explains that the container's custom command explicitly forces an `exit 1` after sleeping for 2 seconds.


2. **Prompt 2:**
```text
> List all my running containers

```


3. **Prompt 3:**
```text
> What image is broken-app using?

```


4. **Prompt 4:**
```text
> Is any container using port 8080?

```

<img width="2984" height="938" alt="image" src="https://github.com/user-attachments/assets/c87c3595-6b0a-4bd1-a211-88aacca337c8" />


*(Keep `broken-app` running for Task 6 before cleaning it up!)*

---

## Task 5: Understand the Agent Architecture

Below is the complete execution flow of the system you just ran:

```text
+-------------------------------------------------------------------+
|                           User Question                           |
|                   ("Why is broken-app crashing?")                 |
+-------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                     LLM Brain (Gemma 4 via Ollama)                |
|                       [temperature=0, ReAct Loop]                 |
+-------------------------------------------------------------------+
                                  |
         +------------------------+------------------------+
         | 1. Reason: Reads @tool docstrings & selects tool|
         v                                                 |
+---------------------------------+                        |
|         Tool Selection          |                        |
+---------------------------------+                        |
  |              |              |                          |
  |              |              +--> inspect_container()   |
  |              |                     (`docker inspect`)  |
  |              +-----------------> get_logs()            |
  |                                    (`docker logs`)     |
  +--------------------------------> list_containers()     |
                                       (`docker ps -a`)    |
                                  |                        |
                                  v                        |
+---------------------------------+                        |
|   Subprocess Execution Output   |                        |
|     (stdout / stderr string)    |------------------------+
+---------------------------------+   2. Observe: Feeds raw CLI text
                                         back to LLM to reason again
                                  |
                                  | (3. Repeat until root cause found)
                                  v
+-------------------------------------------------------------------+
|                        Final Answer to User                       |
|   ("broken-app is crashing because its entrypoint command runs    |
|     'sleep 2 && exit 1', terminating with exit code 1.")          |
+-------------------------------------------------------------------+

```

---

## Task 6: Experiment and Extend (`list_images` & `restart_container`)

Now extend `module-2/agent.py` by adding two custom tools: `list_images` (read-only inspection) and `restart_container` (mutating action).

### Step 6.1: Update `module-2/agent.py`

Open `module-2/agent.py` and add the two new `@tool` definitions right below `inspect_container`:

```python
@tool
def list_images() -> str:
    """List all Docker images on this machine with their repository, tag, and sizes."""
    result = subprocess.run(["docker", "images"], capture_output=True, text=True)
    return result.stdout or result.stderr

@tool
def restart_container(container_name: str) -> str:
    """Restart a specific Docker container by name or ID."""
    result = subprocess.run(["docker", "restart", container_name], capture_output=True, text=True)
    return (result.stdout or result.stderr) or f"Container '{container_name}' restarted successfully."

```

Next, update the `tools` registration list in `module-2/agent.py` so LangGraph exposes them to the LLM:

```python
tools = [
    list_containers,
    get_logs,
    inspect_container,
    list_images,
    restart_container,
]

```

### Step 6.2: Test the Extended Agent

Run `python3 module-2/agent.py` and test both new capabilities:

1. **Test Image Inspection:**
```text
> What images do I have and how much space are they using?

```


*Observation:* The agent matches the question against the `list_images` docstring, executes `docker images`, and summarizes your local image repository and disk usage.
2. **Test Container Remediation:**
```text
> broken-app keeps crashing, can you restart it?

```
<img width="3016" height="1176" alt="image" src="https://github.com/user-attachments/assets/3959b175-0df8-4f8e-91b3-510f1ca68dbf" />


*Observation:* The agent invokes `restart_container(container_name="broken-app")` and confirms the restart (and if it checks status afterward, it will note that the container still crashes due to the hardcoded `exit 1`).

### Step 6.3: Clean Up the Broken Container

Remove the test container:

```bash
docker rm -f broken-app

```

---
