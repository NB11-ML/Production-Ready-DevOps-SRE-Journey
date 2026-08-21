# 🐳 Docker Images & Container Lifecycle — Cheat Sheet

### 📦 Image Operations

| Command | Description |
| --- | --- |
| `docker pull <image>:<tag>` | Download an image from Docker Hub |
| `docker image ls` | List locally stored images |
| `docker image history <image>` | View layer creation history and build steps |
| `docker inspect <image>` | Display detailed JSON metadata for an image |
| `docker rmi <image>` | Remove a local image |
| `docker image prune -a -f` | Delete all unused images |

---

### 🔄 Container Lifecycle Commands

| Command | Lifecycle State Transition |
| --- | --- |
| `docker create --name <name> <image>` | **None $\rightarrow$ Created** (allocates filesystem without running) |
| `docker start <container>` | **Created/Stopped $\rightarrow$ Running** |
| `docker run -d --name <name> <image>` | **None $\rightarrow$ Running** (combines `create` + `start` in detached mode) |
| `docker pause <container>` | **Running $\rightarrow$ Paused** (suspends container processes via cgroups) |
| `docker unpause <container>` | **Paused $\rightarrow$ Running** |
| `docker stop <container>` | **Running $\rightarrow$ Stopped** (sends graceful `SIGTERM`, then `SIGKILL`) |
| `docker restart <container>` | **Running/Stopped $\rightarrow$ Running** |
| `docker kill <container>` | **Running $\rightarrow$ Stopped** (sends immediate `SIGKILL`) |
| `docker rm <container>` | **Stopped/Created $\rightarrow$ Removed** |

---

### 🛠️ Working with Running Containers

| Command | Description |
| --- | --- |
| `docker ps` | List active running containers |
| `docker ps -a` | List all containers (including exited/stopped) |
| `docker logs <container>` | Fetch container output logs |
| `docker logs -f <container>` | Tail logs in real-time (`follow` mode) |
| `docker exec -it <container> /bin/bash` | Open an interactive sub-shell inside a container |
| `docker exec <container> <cmd>` | Execute a single command without entering the container |
| `docker inspect <container>` | Display detailed network, port, and volume mounts |

---

### 🧹 Bulk Cleanup & Maintenance

```bash
# Stop all active containers
docker stop $(docker ps -q)

# Remove all stopped containers
docker rm $(docker ps -a -q)

# Check Docker disk usage (Images, Containers, Volumes, Build Cache)
docker system df

# Deep clean everything (stopped containers, unused networks, dangling images)
docker system prune -a --volumes

```

---

### ⚡ Essential `docker inspect` Go-Template Queries

* **Get Container IP Address:**
```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container>

```


* **Get Exposed Port Mappings:**
```bash
docker inspect -f '{{json .NetworkSettings.Ports}}' <container>

```


* **Get Container Exit Code:**
```bash
docker inspect -f '{{.State.ExitCode}}' <container>

```
