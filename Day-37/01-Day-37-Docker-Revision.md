# 🔄 Day 37: Docker Revision & Self-Assessment
> **Part of the Production-Ready DevOps & SRE Journey**  
> *Consolidating containerization fundamentals, networking, and multi-tier orchestration.*

---

## ✅ Self-Assessment Checklist
*Honest evaluation of Docker capabilities to identify areas for deep-dive review.*

- [x] **Run a container from Docker Hub (interactive + detached)** *(Mastered)*
- [x] **List, stop, remove containers and images** *(Mastered)*
- [x] **Explain image layers and how caching works** *(Mastered - verified during multi-stage build optimizations)*
- [x] **Write a Dockerfile from scratch with FROM, RUN, COPY, WORKDIR, CMD** *(Mastered)*
- [x] **Explain CMD vs ENTRYPOINT** *(Solid, but good to review edge cases for overriding parameters)*
- [x] **Build and tag a custom image** *(Mastered - semantic versioning enforced)*
- [x] **Create and use named volumes** *(Mastered - critical for stateful DB persistence)*
- [ ] **Use bind mounts** *(Shaky - need to review host-to-container permission mapping issues)*
- [x] **Create custom networks and connect containers** *(Mastered - implemented zero-trust bridge networks)*
- [x] **Write a docker-compose.yml for a multi-container app** *(Mastered)*
- [x] **Use environment variables and .env files in Compose** *(Mastered)*
- [x] **Write a multi-stage Dockerfile** *(Mastered - achieved 86% size reduction on Day 35)*
- [x] **Push an image to Docker Hub** *(Mastered)*
- [x] **Use healthchecks and depends_on** *(Mastered - successfully engineered automated self-healing)*

---

## ⚡ Quick-Fire Questions (SRE Edition)

**1. What is the difference between an image and a container?**
An image is a read-only, immutable template containing the application and its dependencies (the blueprint). A container is a live, running instance of that image with a writable ephemeral layer attached (the house).

**2. What happens to data inside a container when you remove it?**
Any data written to the container's ephemeral layer is permanently deleted. To persist data (like a database), an SRE must map a Docker Volume or Bind Mount to the container.

**3. How do two containers on the same custom network communicate?**
They communicate using Docker's internal DNS resolver. You do not need to hardcode IP addresses; containers can simply ping each other using their service names or container names as hostnames (e.g., the `web` container can connect to `redis:6379`).

**4. What does `docker compose down -v` do differently from `docker compose down`?**
While `docker compose down` stops and removes containers and networks, appending the `-v` flag is highly destructive—it also deletes all named volumes attached to the stack, completely wiping persistent data.

**5. Why are multi-stage builds useful?**
They drastically reduce the final image size and attack surface by separating the heavy compilation tools from the lightweight production runtime. They ensure only the final compiled binaries or dependencies are shipped.

**6. What is the difference between COPY and ADD?**
`COPY` explicitly copies local files and directories into the container and is highly predictable. `ADD` does the same but has extra features: it can automatically extract `.tar` files and fetch files from remote URLs. SRE best practice dictates using `COPY` unless the specific extraction features of `ADD` are explicitly needed.

**7. What does `-p 8080:80` mean?**
It maps port 8080 on the Docker host machine to port 80 inside the container. External traffic hitting `localhost:8080` is routed into the container's web server.

**8. How do you check how much disk space Docker is using?**
Run `docker system df` to see a breakdown of space consumed by images, active/stopped containers, local volumes, and the build cache.

---

## 🔄 Revisit Weak Spots: Action Plan
*   **Focus 1:** Revisit **Bind Mounts**. Going to run a quick Nginx container and bind mount a local `index.html` to understand real-time file syncing and test Linux file permission (UID/GID) behaviors between host and container.
*   **Focus 2:** Revisit **CMD vs ENTRYPOINT**. Will write a quick dummy script to test how passing arguments at the end of `docker run` behaves when using `ENTRYPOINT` (arguments append) vs `CMD` (arguments overwrite).
