## 🐳 Core Docker Concepts

* **Image:** A read-only template containing the application code, runtime, libraries, and dependencies.
* **Container:** A lightweight, isolated, and runnable instance of an image.
* **Daemon (`dockerd`):** The background service on the host that listens for API requests and manages Docker objects.
* **Registry:** A centralized storage system for Docker images (e.g., Docker Hub).

## Container Lifecycle Commands

| Command | Action |
| --- | --- |
| `docker run <image>` | Pulls the image (if not local) and starts a new container. |
| `docker ps` | Lists all currently **running** containers. |
| `docker ps -a` | Lists **all** containers (both running and stopped). |
| `docker stop <id>` | Gracefully stops a running container. |
| `docker rm <id>` | Deletes a stopped container from the host. |

## Execution & Exploration

| Flag/Command | Action |
| --- | --- |
| `-d` | **Detached Mode:** Runs the container in the background, freeing up your terminal. |
| `-it` | **Interactive TTY:** Keeps STDIN open and allocates a pseudo-terminal (e.g., for opening a bash shell). |
| `docker logs <id/name>` | Fetches and displays the console output/logs of a specific container. |
| `docker exec -it <id> bash` | Executes a new command (like opening a shell) inside an already running container. |

## Networking & Naming

* **Custom Naming:** Use `--name <custom-name>` during `run` to assign a memorable identifier instead of a random hash (e.g., `docker run --name web nginx`).
* **Port Mapping:** Use `-p <host_port>:<container_port>` to expose container services to your local machine (e.g., `-p 8080:80` routes local traffic on port 8080 directly to the container's internal port 80).
