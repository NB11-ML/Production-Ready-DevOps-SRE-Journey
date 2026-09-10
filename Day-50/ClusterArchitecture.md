# Kubernetes Cluster Workflow
The primary workflow of a Kubernetes (K8s) cluster revolves around a **reconciliation loop**. This loop continuously matches the **current state** of the cluster with your **desired state**. 

When you deploy an application, Kubernetes components interact in a specific sequence to spin up and manage your containers.
---
## 1. Step-by-Step Deployment Workflow
The diagram below maps how a request moves from an administrative command to a running application container across the Control Plane and Worker Nodes:

# Kubernetes Cluster Architecture Workflow

The deployment workflow of a Kubernetes cluster handles declarative configurations through structural stages across the Control Plane and Worker Nodes.

## Component Interaction Diagram

```text
[ User / CI-CD ] 
       │  (1) kubectl apply -f manifest.yaml
       ▼
┌─────────────────────────────────────────────────────────────┐
│ CONTROL PLANE                                               │
│                                                             │
│  ┌─────────────────┐   (2) Validate & Store   ┌──────────┐  │
│  │ kube-apiserver  │─────────────────────────>│   etcd   │  │
│  └─────────────────┘                          └──────────┘  │
│         │         ▲                                         │
│         │         │ (3) Watch / Notify                      │
│         ▼         │                                         │
│  ┌─────────────────┐                                        │
│  │ kube-scheduler  │ (4) Assign Node                        │
│  └─────────────────┘                                        │
└─────────┬───────────────────────────────────────────────────┘
          │ (5) Send Pod Spec
          ▼
┌─────────────────────────────────────────────────────────────┐
│ WORKER NODE                                                 │
│                                                             │
│  ┌─────────────────┐   (6) Pull & Start   ┌──────────────┐  │
│  │    kubelet      │─────────────────────>│  Container   │  │
│  └─────────────────┘                      │   Runtime    │  │
│         ▲                                 └──────────────┘  │
│         │ (7) Monitor Health Status                         │
└─────────┴───────────────────────────────────────────────────┘
```

## Workflow Execution Steps

* **1. Application Submission:** The user or pipeline pushes a declarative YAML configuration file using the command-line utility interface.
* **2. Validation and Write:** The central API server authorizes the incoming request schema and commits the state into high-availability persistent storage.
* **3. State Tracking:** Internal orchestration components register resource tracking requests to listen for unassigned processing workloads.
* **4. Placement Strategy:** The scheduling component evaluates target destination resource budgets, affinity criteria, and active node constraints.
* **5. Workload Delegation:** Target execution parameters pass downward from the orchestration layer straight to local host daemons.
* **6. Lifecycle Instantiation:** The destination node agent instructs lower-level low-level runtimes to fetch required package bundles and execute code.
* **7. Active Reconciliation:** Continuous health monitoring interfaces regularly pipe local runtime statuses back up to maintain system parity.

---
### Step 1: Defining the Desired State
* **Action:** A DevOps engineer or CI/CD pipeline sends a declarative YAML manifest file to the cluster.
* **Tool:** Typically executed via the `kubectl apply` command.
* **Content:** Specifies container images, resource limits, and replica counts.

### Step 2: Request Authentication and Storage
* **Action:** The `kube-apiserver` intercepts the request.
* **Validation:** It authenticates the user and checks the YAML schema.
* **Storage:** The authorized configuration is securely written to `etcd` (the cluster's key-value store).

### Step 3: Pod Scheduling
* **Action:** The `kube-scheduler` watches the API server for unassigned Pods.
* **Evaluation:** It filters and ranks available worker nodes based on resource capacity, constraints, and affinity rules.
* **Assignment:** It binds the Pod to the optimal node and updates the API server.

### Step 4: Local Node Execution
* **Action:** The `kubelet` agent on the target worker node monitors the API server.
* **Detection:** It detects that a new Pod has been assigned to its local node.
* **Download:** It fetches the full Pod specification from the control plane.

### Step 5: Container Deployment
* **Action:** The `kubelet` talks to the local Container Runtime Interface (CRI) like `containerd` or `CRI-O`.
* **Execution:** The runtime pulls the necessary images from a registry and spins up the live containers.

---

## 2. Ongoing Maintenance & Operations Workflow

Once an application is active, Kubernetes transitions into a continuous background management phase:

* **State Synchronization:** The `kube-controller-manager` runs background loops that compare actual cluster health against `etcd` records. If a node fails, it triggers rescheduling to restore the desired replica count.
* **Network Routing:** The `kube-proxy` agent runs on every node to handle local networking. It dynamically updates IP tables or IPVS routing rules so that incoming traffic always finds its way to live pods.
* **Health Probes:** The `kubelet` continuously executes liveness and readiness probes. If a container stops responding or fails its health check, the agent automatically destroys and restarts it.

---

## 3. Native Automation: Workflow Engines

While the standard workflow handles microservices, specialized tools like Argo Workflows extend Kubernetes to orchestrate sequential pipelines (such as ETL, machine learning, or CI/CD pipelines). 

* **CRDs:** The entire pipeline structure is written as a Kubernetes Custom Resource Definition (CRD).
* **Isolation:** An external controller interprets the sequence and launches each step as a short-lived, isolated Pod inside the cluster.

------------------------------

