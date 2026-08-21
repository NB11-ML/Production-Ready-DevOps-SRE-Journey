# 🐳 Day 30: Docker Images & Container Lifecycle

Welcome to **Day 30** of the **Production-Ready DevOps & SRE Journey**! Today’s module focuses on the core mechanics of Docker—exploring how images and containers function under the hood, how image layers and caching work, and how to master every state in the container execution lifecycle.

---

## 📋 Overview & Objectives

* **Image vs. Container Dynamics:** Deep dive into read-only blueprints (images) versus runnable, read-write instances (containers).
* **Layered Architecture & Storage Drivers:** Understand Docker's immutable read-only image layers, Union File Systems (UnionFS), and layer caching mechanics.
* **Complete Container Lifecycle:** Hands-on practice with process state transitions (`Created`, `Running`, `Paused`, `Stopped`, and `Exited`).
* **Runtime Operations & Debugging:** Practice running background processes, real-time log streaming, sub-shell execution (`exec`), and metadata extraction using `docker inspect`.
* **System Maintenance:** Master disk usage analysis and bulk cleanup commands.

---

## 📁 Repository Structure

```text
Day-30/
├── 01-Day-30-Images.md     # Detailed lab documentation & task executions
|── 02-Day-30-Cheet-Sheet   # Quick refrence for docker commands 
└── README.md               # Module summary & quick-reference guide

```

---

## 🚀 Tasks Summary

### Task 1: Docker Images & Footprint Analysis

* Pulled `nginx`, `ubuntu`, and `alpine` base images from Docker Hub.
* Compared general-purpose distributions (`ubuntu` ~78MB) with minimal distributions (`alpine` ~7.4MB) to analyze binary footprints and security surface reduction.
* Inspected low-level image metadata and practiced explicit image removal (`docker rmi`).

### Task 2: Image Layers & UnionFS

* Ran `docker image history nginx` to inspect build steps and read-only layer compositions.
* **Key Concept:** Docker stacks read-only layers. Each instruction in a `Dockerfile` (`RUN`, `COPY`, `ADD`) creates an immutable layer. Running containers add a thin, read-write layer on top, allowing rapid container instantiation without duplicating underlying disk storage.

### Task 3: Container Lifecycle Operations

Practiced step-by-step state manipulation on a single container using low-level CLI commands:

1. `docker create` $\rightarrow$ **Created** state (filesystem initialized, process unstarted)
2. `docker start` $\rightarrow$ **Running** state
3. `docker pause` / `unpause` $\rightarrow$ Process suspension via Linux cgroups
4. `docker stop` $\rightarrow$ Graceful termination (`SIGTERM` followed by `SIGKILL`)
5. `docker kill` $\rightarrow$ Immediate termination (`SIGKILL`)
6. `docker rm` $\rightarrow$ Container cleanup

### Task 4: Working with Active Workloads

* Launched Nginx web server in detached mode (`-d`) with port mapping (`-p 8080:80`).
* Extracted live log streams using `docker logs -f`.
* Used `docker exec -it` to spawn an interactive shell and run non-interactive sub-commands.
* Extracted network specs, internal IP addresses, and volume mounts using custom `docker inspect` JSON formatting templates.

### Task 5: Maintenance & Disk Cleanup

* Cleaned up running and exited container processes.
* Purged unused dangling images and executed disk usage checks (`docker system df`).

---

## ⚡ Quick Command Reference

```bash
# Pull and Inspect Images
docker pull alpine
docker image ls
docker image history <image_name>

# Container Lifecycle Sequence
docker create --name my-app alpine sleep 1000
docker start my-app
docker pause my-app
docker unpause my-app
docker stop my-app
docker rm my-app

# Workload Operations & Debugging
docker run -d -p 8080:80 --name web nginx
docker logs -f web
docker exec -it web /bin/bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web

# Bulk System Cleanup
docker stop $(docker ps -q)
docker rm $(docker ps -a -q)
docker system df
docker system prune -a --volumes

```

---

## 🔗 Related Resources

* 📄 Detailed Lab Documentation: [day-30-images.md](https://www.google.com/search?q=./day-30-images.md)
* 🌐 Official Documentation: [Docker Storage Drivers & Layers](https://www.google.com/search?q=https://docs.docker.com/storage/storagedriver/)
