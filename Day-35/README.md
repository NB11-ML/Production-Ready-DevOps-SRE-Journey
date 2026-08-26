# 🚀 Day 35: Multi-Stage Builds & Docker Hub

> **Part of the Production-Ready DevOps & SRE Journey**  
> *Engineering minimal, secure, and globally distributable container images.*

---

## 📌 Overview & Objectives
Shipping bloated container images containing raw source code and build tools is a severe security risk and wastes significant network bandwidth. Today's focus is on optimizing a Python Flask microservice using multi-stage builds and distributing the finalized artifact via Docker Hub. This ensures our deployments remain fast, secure, and fully reproducible.

**Key Engineering Milestones:**
*   **Image Optimization:** Stripped heavy compilation dependencies from the final production runtime using multi-stage `Dockerfile` directives.
*   **Security Hardening:** Enforced non-root container execution by establishing dedicated system groups and users.
*   **Artifact Distribution:** Successfully authenticated, tagged, and pushed semantic versions to a remote public registry.
*   **Immutable Deployments:** Validated the remote push by verifying the unique SHA256 image digest, establishing a foundation for tamper-proof rollouts.

---

## 📊 SRE Impact: Size & Security Optimization

| Build Type | Base Image | Final Image Size | SRE Impact |
| :--- | :--- | :--- | :--- |
| Single-Stage (Baseline) | `python:3.9` | ~1.01 GB | Slow deployments, massive attack surface containing OS build tools. |
| Multi-Stage (Optimized) | `python:3.9-slim` | ~130 MB | **85%+ size reduction**. Fast boot times, highly secure. |

---

## 📂 Project Structure

| File / Directory | Description |
| :--- | :--- |
| `app.py` & `requirements.txt`| The core Python Flask application and its dependencies. |
| `Dockerfile.single` | Baseline unoptimized configuration for size comparison metrics. |
| `Dockerfile` | Production-ready multi-stage configuration enforcing a non-root user policy. |
| `01-Day-35-MultiStage-Hub.md`| Detailed step-by-step runbook outlining build optimizations and registry mechanics. |
| `02-Day-35-CheatSheet.md` | Quick-reference operational guide for multi-stage syntax and Docker Hub CLI commands. |

---

## ⚡ Core SRE Operations

*   **Compile Optimized Image:** `docker build -t sre-flask-app:optimized .`
*   **Tag for Registry:** `docker tag sre-flask-app:optimized <username>/sre-flask-app:v1.0.0`
*   **Push Artifact:** `docker push <username>/sre-flask-app:v1.0.0`
*   **Pull Immutable Release:** `docker pull <username>/sre-flask-app@sha256:<digest>`

```
