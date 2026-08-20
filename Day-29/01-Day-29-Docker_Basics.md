# 🐳 Day 29: Introduction to Docker

## 🎯 Task 1: What is Docker?

**What is a container and why do we need them?**

A container is a standard unit of software that packages up code and all its dependencies so the application runs quickly and reliably from one computing environment to another. We need them to eliminate the "it works on my machine" problem, ensuring consistency across development, testing, and production environments.

**📦 Containers vs 💻 Virtual Machines**

*   **Virtual Machines (VMs):** Include a full copy of an operating system, the application, necessary binaries, and libraries. They are heavy, slow to start, and consume significant system resources.
*   **Containers:** Share the host system's OS kernel and only contain the application and its dependencies. They are lightweight, start almost instantly, and use far fewer resources.

## Docker Architecture

```mermaid

flowchart LR
    %% Class Styling Definitions
    classDef clientNode fill:#1d4ed8,stroke:#1e40af,color:#ffffff,font-weight:bold;
    classDef daemonNode fill:#0f172a,stroke:#334155,color:#ffffff,font-weight:bold;
    classDef storageNode fill:#ffffff,stroke:#94a3b8,color:#0f172a,font-weight:bold;
    classDef registryNode fill:#7e22ce,stroke:#6b21a8,color:#ffffff,font-weight:bold;

    subgraph Client [" DOCKER CLIENT (CLI) "]
        C1["docker build"]:::clientNode
        C2["docker pull"]:::clientNode
        C3["docker run"]:::clientNode
    end

    subgraph Host [" DOCKER HOST ENGINE "]
        Daemon["Docker Daemon (dockerd)"]:::daemonNode
        
        subgraph LocalStore [" LOCAL RESOURCES "]
            Images["Docker Images"]:::storageNode
            Containers["Docker Containers"]:::storageNode
        end
    end

    subgraph Registry [" DOCKER REGISTRY "]
        Hub["Docker Hub"]:::registryNode
    end

    %% Workflow Connections
    C1 -->|"REST API"| Daemon
    C2 -->|"REST API"| Daemon
    C3 -->|"REST API"| Daemon

    Daemon <-->|"Pull / Push"| Hub
    Daemon -->|"Builds & Stores"| Images
    Daemon -->|"Executes & Manages"| Containers
    Images -.->|"Instantiated into"| Containers

    %% Subgraph Container Color Adjustments (High Contrast Titles)
    style Client fill:#eff6ff,stroke:#2563eb,stroke-width:2px,color:#1e3a8a
    style Host fill:#f0fdf4,stroke:#16a34a,stroke-width:2px,color:#14532d
    style LocalStore fill:#ffffff,stroke:#4ade80,stroke-width:1.5px,color:#14532d
    style Registry fill:#faf5ff,stroke:#9333ea,stroke-width:2px,color:#581c87

```

### Docker uses a client-server architecture:

**The Docker client talks to the Docker daemon, which does the heavy lifting of building, running, and distributing your Docker containers.**

*   **Docker Daemon (`dockerd`):** The background service running on the host that manages building, running, and distributing containers.
*   **Docker Client (`docker`):** The CLI tool used to interact with the daemon (e.g., running `docker run`).
*   **Docker Images:** Read-only templates with instructions for creating a container.
*   **Docker Containers:** Runnable instances of an image.
*   **Docker Registry:** Stores Docker images (e.g., Docker Hub).

**Architecture Flow (Text Representation):**
`Client (CLI)` ➜ Sends REST API commands ➜ `Docker Host (Daemon)` ➜ Pulls from `Registry` ➜ Creates `Images` ➜ Runs `Containers`

---

## 🛠️ Task 2: Install Docker

**1. Installation (Linux/Ubuntu)**
```bash
sudo apt update
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER # Run Docker without sudo

```

**2. Verify Installation**

```bash
docker --version

```

<img width="1097" height="113" alt="Screenshot 2026-08-20 at 12 48 20" src="https://github.com/user-attachments/assets/c2bb3b84-53ad-4013-a2ea-60d0833bd049" />

**3. Run Hello-World**

```bash
docker run hello-world

```

<img width="1094" height="515" alt="image" src="https://github.com/user-attachments/assets/c85e117f-e47f-4b2d-b5d0-856bdf7fa568" />

*Observation:* Docker checks for the `hello-world` image locally. Not finding it, it pulls the image from Docker Hub, creates a container, runs the executable that prints a welcome message, and exits.

---

## 🚀 Task 3: Run Real Containers

**1. Run an Nginx Container**

```bash
docker run nginx

```

<img width="1094" height="220" alt="image" src="https://github.com/user-attachments/assets/a5c344a3-1ea6-43dd-8bad-4136f9344908" />


*Note: Press `Ctrl+C` to exit. This runs in the foreground, locking the terminal.*

**2. Run an Ubuntu Container Interactively**

```bash
docker run -it ubuntu /bin/bash

```

<img width="1686" height="898" alt="image" src="https://github.com/user-attachments/assets/f07c06ea-8e8e-411c-b77f-7ab2aacf4ed1" />

*Inside the container, run `cat /etc/os-release` to verify you are inside Ubuntu. Type `exit` to leave.*

**3. List Running Containers**

```bash
docker ps

```

**4. List All Containers (Including Stopped)**

```bash
docker ps -a

```

<img width="1094" height="576" alt="image" src="https://github.com/user-attachments/assets/d49084a5-c694-4f88-b2c0-b67270ca196a" />


**5. Stop and Remove a Container**

```bash
docker stop <container_id>
docker rm <container_id>

```

<img width="1094" height="302" alt="image" src="https://github.com/user-attachments/assets/5af43555-4fe1-46ab-baa3-3731f0d6f568" />

<img width="1094" height="188" alt="image" src="https://github.com/user-attachments/assets/c162facd-8d3d-4592-a957-5bcb4d8a584b" />

---

## 🔍 Task 4: Explore

**1. Run a Container in Detached Mode**

```bash
docker run -d nginx

```

*The `-d` flag runs the container in the background and prints the container ID, leaving the terminal usable.*

**2. Give a Container a Custom Name**

```bash
docker run -d --name production-ready-web nginx

```

**3. Map a Port to the Host**

```bash
docker run -d --name production-ready-web-port -p 8080:80 nginx

```

<img width="1094" height="403" alt="image" src="https://github.com/user-attachments/assets/16e5bf99-3095-4fb1-a289-fbf228793df6" />


*Access `http://localhost:8080` in your browser. Port 80 inside the container is mapped to port 8080 on the host.*

**4. Check Logs of a Running Container**

```bash
docker logs production-ready-web-port

```

<img width="1094" height="381" alt="image" src="https://github.com/user-attachments/assets/66a75475-7119-4e2a-a7e4-ac5c3e365b1d" />


**5. Run a Command Inside a Running Container**

```bash
docker exec -it production-ready-web-port /bin/bash

```
<img width="2188" height="522" alt="image" src="https://github.com/user-attachments/assets/41148301-b9cc-477a-9f75-80a2a1740522" />

---
