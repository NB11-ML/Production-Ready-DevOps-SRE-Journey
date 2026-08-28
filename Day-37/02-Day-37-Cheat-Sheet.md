# 🐙 SRE Docker & Compose Cheat Sheet
> **Quick-reference operational guide for daily container management, debugging, and cleanup.**

---

## 📦 Container Commands (Lifecycle)
*   **Run detached:** `docker run -d --name <name> -p <host>:<container> <image>`
*   **Run interactive shell:** `docker run -it --name <name> <image> /bin/sh`
*   **List active:** `docker ps` (add `-a` for all stopped/failed)
*   **Stop gracefully:** `docker stop <container_id>`
*   **Force kill:** `docker kill <container_id>`
*   **Remove:** `docker rm <container_id>` (add `-f` to force remove a running container)
*   **Execute command inside:** `docker exec -it <container_id> /bin/sh`
*   **View live logs:** `docker logs -f <container_id>`

## 💿 Image Commands (Artifacts)
*   **Build from Dockerfile:** `docker build -t <username>/<repo>:<tag> .`
*   **List local images:** `docker images` or `docker image ls`
*   **Remove image:** `docker rmi <image_id>`
*   **Tag image:** `docker tag <local-image>:<tag> <username>/<repo>:<tag>`
*   **Push to Hub:** `docker push <username>/<repo>:<tag>`
*   **Pull from Hub:** `docker pull <username>/<repo>:<tag>`

## 💾 Volume Commands (Persistence)
*   **Create volume:** `docker volume create <volume_name>`
*   **List volumes:** `docker volume ls`
*   **Inspect details:** `docker volume inspect <volume_name>`
*   **Remove volume:** `docker volume rm <volume_name>`

## 🖧 Network Commands (Isolation)
*   **Create network:** `docker network create <network_name>`
*   **List networks:** `docker network ls`
*   **Inspect connections:** `docker network inspect <network_name>`
*   **Connect active container:** `docker network connect <network_name> <container_name>`

## ⚙️ Docker Compose (Orchestration)
*   **Start stack detached:** `docker compose up -d`
*   **Stop and remove stack:** `docker compose down`
*   **Stop/Remove AND wipe volumes:** `docker compose down -v`
*   **View stack logs:** `docker compose logs -f`
*   **Force rebuild all images:** `docker compose build --no-cache`
*   **List active compose services:** `docker compose ps`

## 🧹 System Cleanup
*   **Check disk usage:** `docker system df`
*   **Prune unused objects (safe):** `docker system prune`
*   **Prune EVERYTHING (nuke stopped, unused networks/images):** `docker system prune -a --volumes`

## 📄 Dockerfile Instructions
*   `FROM` : Defines the base image (e.g., `FROM python:3.9-slim`).
*   `WORKDIR` : Sets the internal working directory for subsequent commands.
*   `COPY` : Copies files/folders from the host into the image.
*   `ADD` : Like COPY, but can extract tarballs and fetch URLs.
*   `RUN` : Executes shell commands during the *build* phase (e.g., `apt-get install`).
*   `EXPOSE` : Documents which ports the application listens on (informational only).
*   `ENV` : Sets persistent environment variables within the image.
*   `ENTRYPOINT` : Sets the primary executable that cannot easily be overridden.
*   `CMD` : Sets default arguments or commands (easily overridden at runtime).
