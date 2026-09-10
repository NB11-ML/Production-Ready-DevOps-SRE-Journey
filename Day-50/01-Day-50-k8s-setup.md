
# Day 50: Kubernetes Architecture and Cluster Setup

### Task 1: The Kubernetes Story

* Kubernetes was originally created by Google and was heavily inspired by their internal container orchestration system known as Borg. 

* While Docker is excellent for building and running individual containers, it lacks the built-in capability to manage thousands of containers across multiple servers, handle load balancing, or automatically restart failing containers. 

* Kubernetes solves this by providing a robust orchestration layer. The name "Kubernetes" comes from Greek, meaning "helmsman" or "pilot," which perfectly describes its role in steering containerized applications.

### Task 2: Kubernetes Architecture Diagram
**Core Architecture Diagram**
```text
+-------------------------------------------------------------+
|                   CONTROL PLANE (Master Node)               |
|                                                             |
|  [ API Server ] <--- (Central Hub for all REST API traffic) |
|       |                                                     |
|       +--> [ etcd ] (Highly available Key-Value Data Store) |
|       +--> [ Scheduler ] (Assigns Pods to Worker Nodes)     |
|       +--> [ Controller Manager ] (Maintains desired state) |
+-------------------------------------------------------------+
          ^
          | (gRPC/API Communications)
          v
+-------------------------------------------------------------+
|                     WORKER NODE(S)                          |
|                                                             |
|  [ kubelet ] <--- (Node agent communicating with API)       |
|  [ kube-proxy ] <--- (Maintains network routing rules)      |
|                                                             |
|  [ Container Runtime (e.g., containerd / Docker) ]          |
|       |--> [ Pod (App Container) ]                          |
|       |--> [ Pod (App Container) ]                          |
+-------------------------------------------------------------+

```

<img width="2366" height="1662" alt="image" src="https://github.com/user-attachments/assets/cb850a23-0331-4d70-be13-08d4079ef3bd" />


Control Plane (Master Node):

* API Server — the front door to the cluster, every command goes through it
* etcd — the database that stores all cluster state
* Scheduler — decides which node a new pod should run on
* Controller Manager — watches the cluster and makes sure the desired state matches reality

Worker Node:

* kubelet — the agent on each node that talks to the API server and manages pods
* kube-proxy — handles networking rules so pods can communicate
* Container Runtime — the engine that actually runs containers (containerd, CRI-O)

**Tracing a Request (`kubectl apply -f pod.yaml`):**

1. The request hits the **API Server**, which validates it and writes the desired state to **etcd**.
2. The **Scheduler** sees a new Pod needs a node and assigns it based on available resources.
3. The **kubelet** on the assigned Worker Node receives the instruction from the API Server.
4. The **kubelet** tells the **Container Runtime** to pull the image and start the container.
5. The **kubelet** reports the success back to the API Server, updating the state in **etcd**.

**Failure Scenarios:**

* **If the API server goes down:** Existing pods keep running, but you cannot deploy new pods, update configurations, or query the cluster state until it recovers.
* **If a worker node goes down:** The **Controller Manager** detects the node is unresponsive, and the **Scheduler** spins up replacement pods on healthy worker nodes to maintain the desired state.

--- 

### Task 3: Installing kubectl

To interact with the cluster, I installed the Kubernetes command-line tool (kubectl) on my Linux environment:

```bash

# Download the latest release
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make the binary executable
chmod +x kubectl

# Move it to the system path
sudo mv kubectl /usr/local/bin/

# Verify the client version
kubectl version --client


# Make the binary executable
chmod +x kubectl

# Move it to the system path
sudo mv kubectl /usr/local/bin/

# Verify the client version
kubectl version --client

```

<img width="2474" height="422" alt="image" src="https://github.com/user-attachments/assets/939b827f-4db7-4fcb-b750-dccfd7077a5c" />

---

### Task 4: Setting Up the Local Cluster

For this Production-Ready-DevOps-SRE-Journey milestone, I chose kind (Kubernetes in Docker).

Why kind?

Because it runs local Kubernetes clusters by spinning up standard Docker containers to act as "nodes." 
It is incredibly resource-efficient and bridges perfectly with the Docker container management techniques I've established earlier in this challenge.

Installation and Setup:

```Bash
# Download and install kind for Linux
curl -Lo ./kind [https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64](https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64)
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Provision the local cluster
kind create cluster --name devops-cluster

# Verify
kubectl cluster-info

```
<img width="2188" height="792" alt="image" src="https://github.com/user-attachments/assets/f4723086-c369-4897-8778-deddd2c21d20" />


---

## Task 5: Exploring the Cluster
Once the cluster was provisioned, I ran the following commands to inspect the environment:

```Bash
# Verify cluster connection
kubectl cluster-info

# View running worker nodes
kubectl get nodes
OR
kubectl get nodes -o wide

# View system namespaces and pods
kubectl get namespaces
kubectl get pods -n kube-system

```
**Screenshot 1: Cluster Nodes**

<img width="2188" height="242" alt="image" src="https://github.com/user-attachments/assets/95467fb3-12ef-4fe8-9f05-e97e234a6b33" />


**Screenshot 2: Core Architecture Pods**

<img width="2188" height="446" alt="image" src="https://github.com/user-attachments/assets/dc95be1f-978b-44b9-bccb-079d1940af35" />


**What each `kube-system` pod does:**

* **etcd:** The highly-available key-value database storing the configuration and state of the entire cluster.
* **kube-apiserver:** The control plane's front end that handles all REST requests.
* **kube-scheduler:** Watches for newly created Pods with no assigned node, and selects a node for them to run on.
* **kube-controller-manager:** Runs controller processes that regulate the state of the cluster (e.g., node controller, replication controller).
* **coredns:** Provides internal DNS and service discovery so pods can resolve each other via service names.
* **kube-proxy:** Maintains network rules on nodes to allow network communication to your Pods from inside or outside of your cluster.

### Task 6: Practice Cluster Lifecycle

To build muscle memory, I executed a full teardown and recreation of the cluster:

```Bash
kind delete cluster --name devops-cluster
kind create cluster --name devops-cluster
```

<img width="2940" height="1354" alt="image" src="https://github.com/user-attachments/assets/6125be46-b3c2-428d-97bf-a9b0e21123e1" />


**Understanding kubeconfig**

* **What it is:** A `kubeconfig` is a YAML configuration file that acts as the connection map for the `kubectl` CLI tool. It stores essential information such as cluster addresses, user credentials, context definitions, namespaces, and authentication mechanisms, telling `kubectl` exactly where your cluster is and how to securely communicate with the API Server.
* **Where it is stored:** By default, it is securely stored on your local machine in your home directory at `~/.kube/config`.
* **How to view it:** You can inspect your current cluster connections and authentication mappings by running `kubectl config view`.
