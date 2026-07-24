# Day 02: Linux Architecture, Processes, and systemd

## 🏗️ 1. Core Components of Linux (Under the Hood)
Linux utilizes a strict layered architecture to guarantee isolation, secure execution rings, and rock-solid system stability.

```text
 +-----------------------------------------------------------------+

 |                           USER SPACE                            |
 |        (Unprivileged Ring 3 | Applications, Shells, Utils)      |
 +-----------------------------------------------------------------+
                                  │
                  System Calls (API Gateway Interface)
                                  ▼
 +-----------------------------------------------------------------+

 |                          KERNEL SPACE                           |
 |  (Fully Privileged Ring 0 | Core Subsystems & Resource Mgmt)   |
 +-----------------------------------------------------------------+
                                  │
                 Hardware Abstraction Layer (HAL) Drivers
                                  ▼
 +-----------------------------------------------------------------+

 |                         HARDWARE LAYER                          |
 |            (Physical Layer | CPU, RAM, Storage, NICs)           |
 +-----------------------------------------------------------------+
```

### The Architectural Blueprint
* **Hardware Layer:** The physical machine substrate containing components like the Central Processing Unit (CPU), Main Volatile Memory (RAM), persistent storage, and Network Interface Cards (NICs).
* **Kernel Space (The Heart of the OS):** The fully privileged execution zone (**Ring 0**). It directly brokers access to the physical hardware and runs critical subsystems:
  * *Process Scheduler:* Allocates finite CPU execution time slices across queued tasks.
  * *Memory Manager:* Orchestrates virtual-to-physical address mappings, memory pages, and swap domains.
  * *Virtual File System (VFS):* Standardizes input/output interaction pathways across different file systems.
  * *Network Interface:* Manages TCP/IP network protocol stack packets and sockets.
* **User Space (The Safe Sandbox):** The unprivileged zone (**Ring 3**) where user land files, background daemons, Command Line Interpreters (**Shells** like `bash`/`zsh`), and tools run. This sandboxed architecture protects the kernel; an application crash here cannot directly corrupt system-level memory spaces.
* **System Calls (Syscalls):** The secure API interface bridge. Unprivileged user space applications cannot touch the hardware directly. They must switch CPU context into Ring 0 by executing an explicit syscall (e.g., `open()`, `read()`, `fork()`, `write()`).
* **Hardware Abstraction Layer (HAL):** An internal programmatic driver ecosystem that presents generic, unified interfaces to the Kernel, masking vendor-specific hardware quirks.

---

## 🔄 2. Process Lifecycle & Management
A **program** is a passive executable file resting on your storage disk. A **process** is that program in active execution—a dynamic entity allocated CPU time, tracking addresses, and writing data.

### Process Generation: `fork()` vs. `exec()`
Processes are spawned down a hierarchy using cloned parent-child inheritances:
1. **`fork()` System Call:** An existing process duplicates its execution context entirely. This produces an exact child process possessing identical environment settings, variable states, and open file descriptors.
2. **`exec()` System Call:** Right after the fork, the child process triggers `exec()`. This replaces its cloned parent memory canvas with the entirely fresh executable binary file meant to run.

### The 5 Core Process States
Linux processes transition dynamically across these standard state flags depending on resource accessibility and CPU scheduling:
* **Running / Runnable (`R`):** The process is either executing code on a hardware core or sitting inside the kernel scheduler's run-queue waiting for its immediate slot.
* **Interruptible Sleep (`S`):** The process is paused, resting while it waits for a specific system signal, event, or hardware resource allocation (e.g., waiting on user key inputs). It wakes up instantly upon signal delivery.
* **Uninterruptible Sleep (`D`):** The process is deeply suspended and completely deaf to software-level interrupts or exit codes. It typically occurs when a process is waiting for deterministic, blocking physical storage or network file path actions.
* **Stopped (`T`):** The process has been frozen by an explicit administrative or job control utility signal (such as striking `Ctrl + Z`, or issuing a `SIGSTOP`). It rests dormant until told to resume via a `SIGCONT` signal.
* **Zombie (`Z`):** A dead process that has finished execution but still consumes an entry slot inside the kernel's tracking tables. This occurs because its parent process has failed to issue a `wait()` system call to clean up and harvest the child's final exit code.

---

## ⚙️ 3. systemd: The Root Init Engine
When the Linux kernel completes its initial boot sequences and mounts the root storage layout, it spawns exactly one user-space daemon to boot up the rest of the OS: **systemd** (assigned **`PID 1`**).

```text
              [ Linux Kernel Boot Complete ]
                            │
                            ▼
              ┌───────────────────────────┐
              │    systemd (Init PID 1)   │
              └─────────────┬─────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                  ▼
┌─────────────────┐┌─────────────────┐┌─────────────────┐
│ Target Units    ││ Service Units   ││ Socket Units    │
│ (Boot Targets)  ││ (Daemons/Apps)  ││ (On-Demand)     │
└─────────────────┘└─────────────────┘└─────────────────┘
```

### Why systemd Matters in Production DevOps
* **The Ancestral Root:** As the first user-mode process created, systemd acts as the ultimate supervisor and root parent to every service running on the server.
* **Declarative Units Configuration:** Tasks, networks, targets, and mount parameters are managed using declarative `.service`, `.target`, or `.socket` unit files rather than raw procedural scripts.
* **Concurrent Dependency Parallelization:** Older legacy designs (like SysVinit) booted systems sequentially one-by-one. systemd leverages Unix sockets to initialize unrelated background services concurrently, cutting infrastructure boot-up timelines down to seconds.
* **Automated Daemon Crash Resiliency:** systemd uses process control groups (`cgroups`) to trace service processes. If a mission-critical production tool crashes unexpectedly, systemd spots the failure and can automatically spin the service back up instantly using your custom unit file parameters.

---

## 🛠️ 4. The Top 5 Daily DevOps Commands (Deep-Dive)

### 1. `systemctl` — System & Service Manager
Used to introspect, change, and control the underlying configurations and statuses of systemd unit services.
* **Command Example:**
  ```bash
  systemctl status nginx
  ```
* **Why it matters:** Instantly tells a DevOps engineer whether a production service is running, inactive, or failed. It also outputs recent standard errors and dependency tracking paths directly from the system supervisor.

### 2. `top` — Real-Time Process Dashboard
Launches a dynamic, real-time interactive terminal environment displaying resource usage statistics.
* **Command Example:**
  ```bash
  top
  ```
* **Why it matters:** Used during performance-degradation incidents to instantly pinpoint CPU spikes, memory leaks, high system load averages, and resource-hogging Process IDs (PIDs).

### 3. `ps` — Snapshot of Active Processes
Captures a comprehensive, static listing of all currently active processes running in user space or kernel threads.
* **Command Example:**
  ```bash
  ps aux | grep docker
  ```
* **Why it matters:** Isolates the exact details of target applications. The flags specify: `a` (show all users' processes), `u` (display detailed user/owner layout), and `x` (include daemons without a control terminal).

### 4. `journalctl` — Centralized Log Querying
Interrogates the systemd unified logging system (`journald`) to extract historical and real-time logs.
* **Command Example:**
  ```bash
  journalctl -u sshd -f
  ```
* **Why it matters:** Critical for tracking active errors. The `-u` flag isolates entries from a specific service file, while the `-f` (follow) flag appends new entries in real time as they trigger.

### 5. `kill` — Sending Kernel Execution Signals
Transmits a direct software signal to a target process ID to change its state or stop its execution.
* **Command Example:**
  ```bash
  kill -9 1234
  ```
* **Why it matters:** Used to clear stuck processes. While a normal `kill` sends a safe termination request (`SIGTERM`), appending `-9` transmits an un-catchable hardware-level `SIGKILL` that forcefully terminates the target process immediately.

---
