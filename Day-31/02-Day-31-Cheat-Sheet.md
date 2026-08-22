# 🐳 Day 31 Cheat Sheet: Dockerfile & Image Building

## Core Dockerfile Instructions
| Instruction | Description | Example |
| :--- | :--- | :--- |
| `FROM` | Sets the base image. **Must** be the first instruction. | `FROM python:3.9-slim` |
| `WORKDIR` | Sets the active directory inside the container for subsequent commands. | `WORKDIR /app` |
| `COPY` | Copies files from the host (build context) into the container filesystem. | `COPY . .` |
| `RUN` | Executes shell commands in a new layer during the **build** phase. | `RUN pip install -r reqs.txt` |
| `EXPOSE` | Documents the networking port the container listens on (informational). | `EXPOSE 8080` |
| `CMD` | Defines the default command or arguments when the container **runs**. | `CMD ["python", "app.py"]` |
| `ENTRYPOINT`| Configures the container to run as a fixed, dedicated executable. | `ENTRYPOINT ["nginx"]` |

---

## ⚖️ CMD vs. ENTRYPOINT

| Feature | `CMD` | `ENTRYPOINT` |
| :--- | :--- | :--- |
| **Override Behavior** | Completely replaced if CLI arguments are provided at runtime (`docker run img <override>`). | Preserved; CLI arguments passed at runtime are simply appended to the end. |
| **Primary Use Case** | Sensible defaults that developers might need to swap out (like opening a bash shell). | Fixed-purpose binaries and microservices that should always run the same core app. |
| **Production Pattern** | **Combine them:** Use `ENTRYPOINT` to set the core binary, and `CMD` to provide default arguments/flags! |

---

## ⚡ Build Optimization & Best Practices

*   **Strategic Layer Ordering:** Docker caches layers sequentially. If a layer changes, all layers below it rebuild. Always order instructions from **least frequently changed** (like package installs) to **most frequently changed** (like source code).
*   **`.dockerignore`:** Crucial for security and speed. Explicitly exclude `.git/`, `node_modules/`, and `.env` files to prevent bloated image sizes and leaked secrets in the build context.
*   **Lightweight Base Images:** Whenever possible, use `alpine` or `slim` variants (e.g., `FROM nginx:alpine`) to keep the image secure and under 50MB instead of 500MB+.

---

## 🛠️ Essential Build Commands

| Command | Action |
| :--- | :--- |
| `docker build -t <name>:<tag> .` | Builds an image using the `Dockerfile` in the current directory (`.`) and applies a custom tag. |
| `docker build -f <filename> -t <name> .` | Builds an image using a specifically named file (e.g., `Dockerfile.prod`) instead of the default. |
| `docker image prune` | Cleans up dangling, unnamed, or orphaned build layers to free up disk space. |
