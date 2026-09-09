
# Day 50: Kubernetes Architecture and Cluster Setup

### Task 1: The Kubernetes Story

* Kubernetes was originally created by Google and was heavily inspired by their internal container orchestration system known as Borg. 

* While Docker is excellent for building and running individual containers, it lacks the built-in capability to manage thousands of containers across multiple servers, handle load balancing, or automatically restart failing containers. 

* Kubernetes solves this by providing a robust orchestration layer. The name "Kubernetes" comes from Greek, meaning "helmsman" or "pilot," which perfectly describes its role in steering containerized applications.

### Task 2: Kubernetes Architecture Diagram
```text
+---------------------------------------------------+
|               CONTROL PLANE (Master)              |
|                                                   |
|  [ API Server ] <--- Front door / CLI traffic     |
|       |                                           |
|       +--> [ etcd ] (State/Data Store)            |
|       +--> [ Scheduler ] (Assigns Nodes)          |
|       +--> [ Controller Manager ] (Maintains State|
+---------------------------------------------------+
          ^
          | (API Communications)
          v
+---------------------------------------------------+
|                 WORKER NODE(S)                    |
|                                                   |
|  [ kubelet ] <--- Node agent talking to API       |
|  [ kube-proxy ] <--- Network routing / IP rules   |
|                                                   |
|  [ Container Runtime (containerd/Docker) ]        |
|       |--> [ Pod ]                                |
|       |--> [ Pod ]                                |
+---------------------------------------------------+


```

<img width="2366" height="1662" alt="image" src="https://github.com/user-attachments/assets/cb850a23-0331-4d70-be13-08d4079ef3bd" />


**Tracing a Request (`kubectl apply -f pod.yaml`):**

1. The request hits the **API Server**, which validates it and writes the desired state to **etcd**.
2. The **Scheduler** sees a new Pod needs a node and assigns it based on available resources.
3. The **kubelet** on the assigned Worker Node receives the instruction from the API Server.
4. The **kubelet** tells the **Container Runtime** to pull the image and start the container.
5. The **kubelet** reports the success back to the API Server, updating the state in **etcd**.

**Failure Scenarios:**

* **If the API server goes down:** Existing pods keep running, but you cannot deploy new pods, update configurations, or query the cluster state until it recovers.
* **If a worker node goes down:** The **Controller Manager** detects the node is unresponsive, and the **Scheduler** spins up replacement pods on healthy worker nodes to maintain the desired state.

### Tasks 3 & 4: Tool Choice and Setup

**Chosen Tool:** `kind` (Kubernetes in Docker)
**Reason:** I chose `kind` because it spins up Kubernetes clusters using local Docker containers as nodes. Since I have been extensively working with Docker containers in previous tasks, this provides a seamless, lightweight, and fast local testing environment.

### Task 5: Cluster Exploration

**Screenshot 1: Cluster Nodes**
*[Insert screenshot of `kubectl get nodes` here]*

**Screenshot 2: Core Architecture Pods**
*[Insert screenshot of `kubectl get pods -n kube-system` here]*

**What each `kube-system` pod does:**

* **etcd:** The highly-available key-value database storing the configuration and state of the entire cluster.
* **kube-apiserver:** The control plane's front end that handles all REST requests.
* **kube-scheduler:** Watches for newly created Pods with no assigned node, and selects a node for them to run on.
* **kube-controller-manager:** Runs controller processes that regulate the state of the cluster (e.g., node controller, replication controller).
* **coredns:** Provides internal DNS and service discovery so pods can resolve each other via service names.
* **kube-proxy:** Maintains network rules on nodes to allow network communication to your Pods from inside or outside of your cluster.

### Task 6: Practice Cluster Lifecycle

**What is a kubeconfig?**
A `kubeconfig` is a configuration file that stores information about clusters, users, namespaces, and authentication mechanisms. It tells the `kubectl` CLI tool exactly where your cluster is and how to securely connect to it.

**Where is it stored?**
On most systems, the default location is in the user's home directory at `~/.kube/config`.

```

```
