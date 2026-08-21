# 🐳 📦 Day 30 – Docker Images & Container Lifecycle

## 🎯 Learning Objectives

* **Image vs. Container Relationship:** Understand images as read-only blueprints and containers as runnable, read-write instances.
* **Image Layers & Storage:** Explore how Docker utilizes read-only union file systems (UnionFS) and layer caching for maximum efficiency.
* **Full Container Lifecycle:** Master states (`Created`, `Running`, `Paused`, `Stopped`, `Exited`) using low-level Docker CLI commands.
* **Process Inspection:** Practice detached executions, real-time log streaming, `exec` sub-shells, and metadata extraction.

---

## 📌 Task 1: Docker Images

### 1. Pulling Images
Pull `nginx`, `ubuntu`, and `alpine` base images from Docker Hub:

```bash
docker pull nginx
docker pull ubuntu
docker pull alpine

```

### 2. Listing Images & Comparing Sizes

List local images and observe resource footprints:

```bash
docker image ls

```

**Output:**

<img width="1094" height="168" alt="image" src="https://github.com/user-attachments/assets/acc9c6e5-66b1-4845-b461-af841701b821" />

**Ubuntu vs. Alpine Comparison:**

* **Ubuntu (~179 MB):** A general-purpose Linux distribution image containing common administrative utilities (`apt`, `bash`, `coreutils`, shared libraries).
* **Alpine (~13.6 MB):** A lightweight security-oriented distribution based on `musl libc` and `busybox`. It strips out non-essential binaries, minimizing the attack surface and download overhead.

### 3. Inspecting & Removing Images

Retrieve detailed JSON metadata for an image:

```bash
docker inspect alpine

```

<img width="1094" height="160" alt="image" src="https://github.com/user-attachments/assets/add5530a-8996-4a5c-9aac-1fa1c9a49d21" />


Delete an unused image locally:

```bash
docker rmi ubuntu

```

<img width="1094" height="359" alt="image" src="https://github.com/user-attachments/assets/e1226528-83e1-4fe3-ad3a-ea67e98d7fe1" />


---

## 📌 Task 2: Image Layers & Storage

### 1. Analyzing Image History

Inspect the build steps and layer composition of `nginx`:

```bash
docker image history nginx

```

**Output:**

<img width="1147" height="399" alt="image" src="https://github.com/user-attachments/assets/e9313532-74ce-46bc-bce2-3e37431f7717" />

### 2. What are Image Layers and Why Does Docker Use Them?

* **Definition:** Docker images consist of stacked, read-only layers. Each instruction in a `Dockerfile` (e.g., `RUN`, `COPY`, `ADD`) creates an immutable layer on top of the previous one.
* **Why Docker Uses Layers:**
1. **Layer Caching:** If multiple images share identical base steps (e.g., `apt-get update`), Docker reuses cached layers instead of re-downloading or re-building them.
2. **Storage Efficiency:** Running 10 containers from the `nginx` image shares the same underlying read-only layers on disk, creating only a thin read-write container layer for each active instance.
3. **Faster Distribution:** Only modified or missing layers are transferred during `docker push` or `docker pull` operations.



---

## 📌 Task 3: Container Lifecycle

### Execution Workflow Matrix

```text
[ Created ] ──start──▶ [ Running ] ──pause──▶ [ Paused ]
     │                      │                      │
     │                      │ stop               unpause
     │                      ▼                      │
     └────────────────▶ [ Exited ] ◄───────────────┘

```

### Step-by-Step Lifecycle Practice

```bash
# 1. Create a container (without starting it)
docker create --name lifecycle-demo alpine sleep 1000
docker ps -a --filter name=lifecycle-demo   # State: Created

# 2. Start the container
docker start lifecycle-demo
docker ps --filter name=lifecycle-demo      # State: Up (Running)

# 3. Pause the container
docker pause lifecycle-demo
docker ps --filter name=lifecycle-demo      # State: Up (Paused)

# 4. Unpause the container
docker unpause lifecycle-demo
docker ps --filter name=lifecycle-demo      # State: Up (Running)

# 5. Stop the container (Graceful SIGTERM -> SIGKILL)
docker stop lifecycle-demo
docker ps -a --filter name=lifecycle-demo   # State: Exited (0)

# 6. Restart the container
docker restart lifecycle-demo
docker ps --filter name=lifecycle-demo      # State: Up (Running)

# 7. Kill the container (Forced SIGKILL)
docker kill lifecycle-demo
docker ps -a --filter name=lifecycle-demo   # State: Exited (137)

# 8. Remove the container
docker rm lifecycle-demo
docker ps -a --filter name=lifecycle-demo   # Output: empty

```

<img width="1094" height="449" alt="image" src="https://github.com/user-attachments/assets/e4afaee4-3f2b-480b-a8e0-8f3c5edfa529" />
<img width="1095" height="557" alt="image" src="https://github.com/user-attachments/assets/a22adde4-2b58-4cc0-863b-ffb94eb70ad0" />

---

## 📌 Task 4: Working with Running Containers

### 1. Launch in Detached Mode

Launch an Nginx web server operating in the background detached mode:

```bash
docker run -d -p 8080:80 --name web-server nginx

```

### 2. Inspecting Logs

View accumulated stdout/stderr logs:

```bash
docker logs web-server

```

Stream logs continuously in real-time (`follow` mode):

```bash
docker logs -f web-server

```

### 3. Shell Execution & One-off Commands

Open an interactive sub-shell inside the running container:

```bash
docker exec -it web-server /bin/bash
# Inside container:
exit

```

<img width="1094" height="399" alt="image" src="https://github.com/user-attachments/assets/fcbfb050-2674-4407-b72c-5a6d4726a1bf" />


Execute a single command inside the container from the host system without attaching:

```bash
docker exec web-server nginx -v

```

<img width="1093" height="99" alt="image" src="https://github.com/user-attachments/assets/807fd483-774f-4d7f-a4e0-c720ed6facbe" />

### 4. Container Deep-Dive Metadata Extraction

Extract target values using specific JSON queries:

```bash
# Extract Internal IP Address
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web-server

# Extract Port Mappings
docker inspect -f '{{json .NetworkSettings.Ports}}' web-server

# Extract Mounts/Volumes
docker inspect -f '{{json .Mounts}}' web-server

```

<img width="1094" height="186" alt="image" src="https://github.com/user-attachments/assets/ceb842cf-d139-4189-b8b8-183519a31460" />


---

## 📌 Task 5: Cleanup & Disk Maintenance

```bash
# 1. Stop all running containers in one command
docker stop $(docker ps -q)

# 2. Remove all stopped containers in one command
docker rm $(docker ps -a -q)

# 3. Remove unused images
docker image prune -a -f

# 4. Check disk usage allocation
docker system df

```

**Disk Space Inspection Output (`docker system df`):**

```text
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          0         0         0B        0B
Containers      0         0         0B        0B
Local Volumes   0         0         0B        0B
Build Cache     0         0         0B        0B

```
---

<img width="1094" height="780" alt="image" src="https://github.com/user-attachments/assets/d9bde39c-4cbb-463c-9a10-a5523b2f4d4d" />

---

## 💡 Summary Checklist

* [x] Pulled base images and analyzed architectural differences between general-purpose (`Ubuntu`) and minimal (`Alpine`) Linux distributions.
* [x] Inspected layered storage drivers (`docker image history`).
* [x] Practiced container process states (`Created` $\rightarrow$ `Running` $\rightarrow$ `Paused` $\rightarrow$ `Stopped` $\rightarrow$ `Exited`).
* [x] Configured background services, log streams, and executed internal commands via `exec`.
* [x] Executed cleanups using `docker system df` and `docker prune`.
