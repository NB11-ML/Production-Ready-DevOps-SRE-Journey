# 🐙 Day 35 Cheat Sheet: Multi-Stage Builds & Docker Hub

> **Quick-reference guide for optimizing image sizes, enforcing security, and managing remote registries.**

---

## 🏗️ Multi-Stage Build Syntax
Multi-stage builds separate the heavy compilation environment from the final runtime environment, drastically reducing image size and attack surface.

*   **Define the Builder Stage:** Alias the first stage using `AS` to easily reference it later.
    ```dockerfile
    FROM python:3.9 AS builder
    ```
*   **Copy Artifacts to Final Stage:** Use the `--from` flag to selectively copy only the compiled binaries or virtual environments into the final, lightweight base image.
    ```dockerfile
    FROM python:3.9-slim
    COPY --from=builder /opt/venv /opt/venv
    ```

---

## 🛡️ SRE Security & Optimization Best Practices
A production-grade image is small, secure, and predictable.

*   **Enforce Non-Root Execution:** Never run containers as root. Create a dedicated system user and switch to it before defining the `CMD`.
    ```dockerfile
    RUN addgroup --system sre_group && adduser --system --group nonroot_user
    USER nonroot_user
    ```
*   **Combine RUN Commands:** Minimize image layers by linking shell commands with `&&`.
*   **Pin Specific Tags:** Never use `:latest`. Pin specific versions (e.g., `:3.9-slim`) to ensure reproducible builds.
*   **Base Image Selection:** For Python applications, prefer `slim` (Debian-based) over `alpine` to avoid `musl libc` compilation bugs with heavy dependencies like PostgreSQL drivers.

---

## 🌍 Docker Hub CLI Essentials
Commands for versioning and distributing images to a remote registry.

*   **Authenticate:** Log in to your Docker Hub account (use a Personal Access Token instead of a password).
    ```bash
    docker login
    ```
*   **Semantic Tagging:** Format tags as `<username>/<repository>:<version>`.
    ```bash
    docker tag sre-flask-app:optimized <username>/sre-flask-app:v1.0.0
    ```
*   **Push to Registry:** Upload the layers to Docker Hub.
    ```bash
    docker push <username>/sre-flask-app:v1.0.0
    ```

---

## 🔒 Immutable Deployments (The SRE Way)
Tags like `v1.0.0` are mutable (they can be overwritten). To guarantee a deployment runs the exact verified code, SREs deploy using the immutable SHA256 image digest.

*   **Pull by Digest:**
    ```bash
    docker pull <username>/sre-flask-app@sha256:feb639bcfbef72b7d8444e72c6a1aecc60f38c668f48a9f4f3b2006f39e625a9
    ```

```
