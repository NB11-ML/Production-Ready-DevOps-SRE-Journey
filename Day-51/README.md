# 🚀 Day 51: Kubernetes Manifests & Pod Orchestration ☸️

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![YAML](https://img.shields.io/badge/YAML-CB171E?style=for-the-badge&logo=yaml&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

Welcome to Day 51 of the **Production-Ready DevOps & SRE Journey**. With our `kind` Control Plane actively running, today marks the transition from infrastructure provisioning to workload execution. We are mastering **Pods**—the smallest, most fundamental deployable compute units in Kubernetes—through strictly declarative YAML manifests.

## 🎯 Mission Objectives

* **Declarative Infrastructure:** Write and execute precise YAML manifests utilizing the four mandatory API fields (`apiVersion`, `kind`, `metadata`, `spec`).
* **Workload Deployment:** Spin up a persistent web server (Nginx) and a lightweight utility container (BusyBox).
* **Lifecycle Management:** Override default container entrypoints to prevent `CrashLoopBackOff` in ephemeral tasks.
* **Resource Labeling:** Tag compute resources with key-value pairs (e.g., `team=sre-backend`) for dynamic environment filtering.
* **Pre-Flight Validation:** Utilize `--dry-run=client` and `--dry-run=server` to detect schema violations before committing to `etcd`.

## 🏗️ Pod Architecture Overview

```mermaid
graph TD
    subgraph "Kubernetes Worker Node"
        subgraph "Pod Namespace (Logical Host)"
            NET[Shared Network IP]
            VOL[(Shared Storage Volume)]
            
            C1[Container 1: Nginx<br>Port 80]
            C2[Container 2: Sidecar / BusyBox]
            
            NET --- C1
            NET --- C2
            VOL --- C1
            VOL --- C2
        end
    end
