# 🚀 Day 52: Kubernetes Namespaces & Enterprise Deployments ☸️

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![YAML](https://img.shields.io/badge/YAML-CB171E?style=for-the-badge&logo=yaml&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

Welcome to Day 52 of the **Production-Ready DevOps & SRE Journey**. After mastering bare Pod orchestration on Day 51, today we transition to true enterprise-grade Kubernetes. We are solving the ephemeral nature of standalone Pods by implementing **Deployments** for self-healing and zero-downtime updates, alongside **Namespaces** for logical cluster isolation.

## 🎯 Mission Objectives

* **Logical Isolation:** Provision custom namespaces (`dev`, `staging`) to separate workloads and simulate multi-tenant cluster environments.
* **High Availability:** Author Deployment manifests to maintain a strict desired state of `nginx` replicas.
* **Self-Healing Capabilities:** Intentionally destroy running Pods to validate the controller's instant automated recovery loop.
* **Elastic Scaling:** Execute both imperative and declarative horizontal scaling to adjust compute resources on the fly.
* **Zero-Downtime Rollouts:** Perform a rolling image update (1.24 to 1.25) and instantly execute an SRE-style rollback to mitigate a simulated broken deployment.

## 🏗️ Deployment Architecture Overview

```mermaid
graph TD
    subgraph "Kubernetes Control Plane"
        API[API Server]
        CM[Controller Manager]
        API --- CM
    end

    subgraph "Namespace: dev"
        D[Deployment<br>app: nginx] -->|Defines Desired State| RS[ReplicaSet<br>replicas: 3]
        CM -.->|Monitors & Reconciles| RS
        RS -->|Manages| P1[Pod 1<br>Running]
        RS -->|Manages| P2[Pod 2<br>Running]
        RS -->|Manages| P3[Pod 3<br>Running]
    end
