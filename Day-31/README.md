# 🐳 Day 31: Dockerfile & Custom Image Construction

> **Part of the 90-Day Production-Ready DevOps & SRE Journey**  
> *Transitioning from consuming container images to engineering them.*

---

## 📌 Overview

Day 31 focuses on the core skill that separates Docker users from Docker engineers: writing efficient, secure, and optimized `Dockerfiles`. 

Building on the container lifecycle management learned previously, this module dives deep into defining infrastructure as code for containers. We explore execution commands, build context management, and layer caching optimization—crucial concepts for integrating containers into production CI/CD pipelines.

---

## 🎯 Key Learning Objectives

1. **Dockerfile Fundamentals:** Master essential instructions including `FROM`, `WORKDIR`, `COPY`, `RUN`, and `EXPOSE` to construct custom application environments.
2. **Execution Behaviors (`CMD` vs. `ENTRYPOINT`):** Understand how to design containers as flexible runtime environments versus dedicated, immutable executables.
3. **Build Optimization:** 
   * Leverage `.dockerignore` to secure the build context, exclude sensitive data (like `.env` files), and reduce image bloat.
   * Strategically order Dockerfile instructions to maximize layer caching and minimize rebuild times.

---

## 📂 File Directory

| File | Description |
| :--- | :--- |
| [`01-Day-31-DockerFile.md`](./01-Day-31-DockerFile.md) | Comprehensive task documentation, featuring step-by-step builds, Python web app containerization, and execution experiments. |
| [`02-Day-31-CheatSheet.md`](./02-Day-31-CheatSheet.md) | Quick-reference command guide covering core syntax, override behaviors, and optimization best practices. |

*(Note: Additional app-specific files like `app.py`, `requirements.txt`, and `index.html` are embedded within the respective task documentation).*

---

## ⚡ Quick Start / Core Commands

```bash
# 1. Build a custom image from a Dockerfile in the current directory
docker build -t my-custom-app:v1 .

# 2. Build using a specifically named Dockerfile
docker build -f Dockerfile.prod -t my-production-app:v1 .

# 3. Run a container, overriding a CMD directive (e.g., launching a shell instead)
docker run -it my-custom-app:v1 /bin/bash

# 4. Clean up dangling build layers to recover disk space
docker image prune

```

---

## 🔗 Related Resources & References

* **Official Docs:** [Dockerfile Reference](https://www.google.com/search?q=https://docs.docker.com/engine/reference/builder/)
* **Best Practices:** [Optimizing Docker Builds](https://www.google.com/search?q=https://docs.docker.com/build/building/best-practices/)
* **Parent Repository:** [Production-Ready DevOps & SRE Journey](https://www.google.com/search?q=../)

```

```
