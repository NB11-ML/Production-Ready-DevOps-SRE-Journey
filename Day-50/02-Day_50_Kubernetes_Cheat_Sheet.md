# Kubernetes Architecture & Cluster Operations Cheat Sheet

## Core Architecture Components

| Component | Node Type | Primary Function | SRE / Operational Context |
| :--- | :--- | :--- | :--- |
| **API Server** | Control Plane | Central communication hub for all REST requests. | Validates and routes all commands; cluster is immutable if down. |
| **etcd** | Control Plane | Highly available key-value data store. | The absolute source of truth. Critical target for cluster state backups. |
| **Scheduler** | Control Plane | Evaluates resource requirements to assign pods to nodes. | Ensures balanced workloads across the underlying infrastructure. |
| **Controller Manager** | Control Plane | Compares actual cluster state against the desired state. | Detects worker node failures and triggers pod rescheduling. |
| **kubelet** | Worker Node | Primary node agent communicating with the API Server. | Commands the container runtime to spin up or destroy containers. |
| **kube-proxy** | Worker Node | Maintains network IP rules on the host node. | Facilitates routing traffic to the correct pods across the cluster. |
| **Container Runtime** | Worker Node | The execution engine (containerd, CRI-O, Docker). | Pulls images and runs the actual isolated application processes. |

## Essential `kubectl` Commands

| Command | Purpose |
| :--- | :--- |
| `kubectl cluster-info` | Displays addresses of the master and services (DNS). |
| `kubectl get nodes -o wide` | Lists all cluster nodes with expanded IP and OS details. |
| `kubectl get namespaces` | Lists all virtual clusters (namespaces) in the environment. |
| `kubectl get pods -A` | Lists every running pod across all namespaces globally. |
| `kubectl get pods -n kube-system` | Lists core infrastructure pods (etcd, API server, coredns). |
| `kubectl describe node <name>` | Outputs exhaustive metrics, capacity, and events for a node. |
| `kubectl config view` | Displays the current `~/.kube/config` mapping and credentials. |
| `kubectl config current-context` | Shows the active cluster target for `kubectl` commands. |

## Local Cluster Management (`kind`)

| Command | Purpose |
| :--- | :--- |
| `kind create cluster --name <name>` | Provisions a new local cluster using Docker containers as nodes. |
| `kind get clusters` | Lists all active local `kind` clusters. |
| `kind delete cluster --name <name>` | Destroys the specified local cluster and associated containers. |

```
