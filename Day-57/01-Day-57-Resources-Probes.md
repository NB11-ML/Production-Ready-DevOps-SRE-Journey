# 🚦 Day 57: Kubernetes Resource Requests, Limits, and Probes

Deploying an application in Kubernetes is easy. Keeping it stable and highly available in a multi-tenant cluster is hard. 

Without **Resource Constraints**, a memory-leaking application will consume the entire physical node's RAM, crashing other critical applications (the "noisy neighbor" problem). Without **Health Probes**, Kubernetes has no idea if your Java application is actually ready to serve web traffic, or if it's deadlocked and needs a reboot.

Today, we implement strict SRE guardrails: smart scheduling, memory limits, and automated self-healing.

---

## 📖 SRE Theory: Resources & QoS

### Requests vs. Limits
*   **Requests (Scheduling):** The *guaranteed minimum* resources a Pod needs. The Kubernetes Scheduler uses this number to find a physical Node big enough to fit the Pod.
*   **Limits (Enforcement):** The *absolute maximum* resources a Pod is allowed to use. The Kubelet enforces this at runtime.

### Compressible vs. Incompressible
*   **CPU is Compressible:** If a Pod exceeds its CPU limit, it is simply **throttled** (slowed down). It will *not* be killed. 
*   **Memory is Incompressible:** You cannot throttle RAM. If a Pod exceeds its memory limit, the Linux kernel terminates it with extreme prejudice. (**OOMKilled**).

### Quality of Service (QoS) Classes
Kubernetes assigns every Pod a QoS class based on your configuration. When a physical node runs out of memory, Kubernetes evicts Pods in this exact order:
1.  **BestEffort (Lowest Priority):** No requests or limits set. (Evicted first).
2.  **Burstable:** Requests are set, but Limits are higher than Requests. 
3.  **Guaranteed (Highest Priority):** Requests and Limits are set exactly equal. (Evicted last).

---

## 🚀 Challenge Tasks & Execution

### Task 1: Resource Requests and Limits (Burstable QoS)

**1. Create `resources-pod.yaml`:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-demo
spec:
  containers:
  - name: qos-demo-ctr
    image: nginx
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m" # 100 millicores (0.1 CPU)
      limits:
        memory: "256Mi"
        cpu: "250m"

```

**2. Apply and Inspect:**

```bash
kubectl apply -f resources-pod.yaml
kubectl describe pod qos-demo | grep -i qos

```

<img width="2568" height="1220" alt="image" src="https://github.com/user-attachments/assets/9001f663-97e2-449b-807a-6a4fc7f8ab57" />

> **✅ Verify:** *What QoS class does your Pod have?*
> **Answer:** **Burstable.** Because the Requests (100m/128Mi) are lower than the Limits (250m/256Mi), Kubernetes guarantees the minimum but allows it to "burst" up to the limit if the node has spare capacity.

---

### Task 2: OOMKilled — Exceeding Memory Limits

Let's intentionally trigger an Out-Of-Memory (OOM) kill.

**1. Create `oom-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: oom-demo
spec:
  containers:
  - name: stress
    image: polinux/stress
    resources:
      limits:
        memory: "100Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "200M", "--vm-hang", "1"] # Tries to allocate 200MB!

```

**2. Apply and Watch:**

```bash
kubectl apply -f oom-pod.yaml
kubectl get pod oom-demo -w
# Wait for the status to change to OOMKilled

kubectl describe pod oom-demo

```

<img width="1470" height="864" alt="Screenshot 2026-09-17 at 05 14 01" src="https://github.com/user-attachments/assets/bc9f4cd9-ea69-4c16-93a7-32e64dd32fda" />


> **✅ Verify:** *What exit code does an OOMKilled container have?*
> **Answer:** **Exit Code 137.** (This is calculated as Linux base code 128 + signal 9 `SIGKILL`). The kernel ruthlessly killed the process for attempting to use 200Mi when its limit was strictly 100Mi.

---

### Task 3: Pending Pod — Requesting Too Much

What happens if you ask for hardware that doesn't exist?

**1. Create `huge-request-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: greedy-pod
spec:
  containers:
  - name: greedy-ctr
    image: nginx
    resources:
      requests:
        cpu: "100"       # 100 entire CPU cores!
        memory: "128Gi"  # 128 Gigabytes of RAM!

```

**2. Apply and Check the Scheduler Event:**

```bash
kubectl apply -f huge-request-pod.yaml
kubectl get pods
kubectl describe pod greedy-pod

```

<img width="1403" height="493" alt="Screenshot 2026-09-17 at 05 24 36" src="https://github.com/user-attachments/assets/05fdb817-4285-4f0e-8bcd-4f65ee3dcdb4" />


> **✅ Verify:** *What event message does the scheduler produce?*
> **Answer:** `Warning  FailedScheduling  default-scheduler  0/1 nodes are available: 1 Insufficient cpu, 1 Insufficient memory.` The Pod remains strictly in a `Pending` state because the Scheduler cannot find a Node big enough to satisfy the guaranteed request.

---

### Task 4: Liveness Probe (Self-Healing)

Liveness probes detect application deadlocks. If the probe fails, the Kubelet restarts the container.

**1. Create `liveness-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      periodSeconds: 5
      failureThreshold: 3

```

*(This container creates a healthy file, waits 30 seconds, and deletes it to simulate a crash).*

**2. Apply and Watch:**

```bash
kubectl apply -f liveness-pod.yaml
kubectl get pod liveness-exec -w

```

> **✅ Verify:** *How many times has the container restarted?*
> **Answer:** After about 45 seconds (30s sleep + 15s of 3 failed checks), the `RESTARTS` column will tick up to `1`, and keep looping.

---

### Task 5: Readiness Probe (Traffic Control)

Readiness probes dictate if a Pod is allowed to receive web traffic. If it fails, the Pod is removed from the Service Endpoints, but it is **NOT** restarted.

**1. Create `readiness-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-demo
  labels:
    app: ready
spec:
  containers:
  - name: nginx
    image: nginx
    readinessProbe:
      httpGet:
        path: /
        port: 80
      periodSeconds: 5

```

**2. Apply, Expose, and Break it:**

```bash
kubectl apply -f readiness-pod.yaml
kubectl expose pod readiness-demo --port=80 --name=readiness-svc

# Verify it is initially healthy and receiving traffic:
kubectl get endpoints readiness-svc

# Delete the index file so the httpGet probe receives a 404 error instead of a 200 OK:
kubectl exec readiness-demo -- rm /usr/share/nginx/html/index.html

```

**3. Observe the outcome:**

```bash
kubectl get pod readiness-demo
kubectl get endpoints readiness-svc

```

> **✅ Verify:** *When readiness failed, was the container restarted?*
> **Answer:** **No.** The `READY` column simply dropped to `0/1`, and the IP address disappeared from `kubectl get endpoints`. This is an SRE failsafe: if a Pod is overwhelmed or syncing a database, we stop sending it user traffic, but we *don't* kill it!

---

### Task 6: Startup Probe (The Protector)

Legacy applications (like heavy Java Spring Boot apps) take a long time to boot. A Liveness probe might kill it before it even finishes starting! A Startup Probe pauses all other probes until the app is fully awake.

**1. Create `startup-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: startup-demo
spec:
  containers:
  - name: slow-app
    image: busybox
    args:
    - /bin/sh
    - -c
    - sleep 20 && touch /tmp/started && sleep 600
    startupProbe:
      exec:
        command: ["cat", "/tmp/started"]
      periodSeconds: 5
      failureThreshold: 12  # Allows up to 60 seconds (5 * 12) for the app to boot
    livenessProbe:
      exec:
        command: ["cat", "/tmp/started"]
      periodSeconds: 5

```

**2. Apply and test:**

```bash
kubectl apply -f startup-pod.yaml

```

> **✅ Verify:** *What would happen if failureThreshold were 2 instead of 12?*
> **Answer:** The Startup probe would fail after 10 seconds (5s period * 2 thresholds). Because our application takes 20 seconds to boot (`sleep 20`), the container would be killed and restarted before it ever had a chance to finish initializing. It would be stuck in an infinite `CrashLoopBackOff`.

---

### Task 7: Clean Up

Wipe the slate clean for the next day of the SRE journey!

```bash
kubectl delete pod qos-demo oom-demo greedy-pod liveness-exec readiness-demo startup-demo
kubectl delete svc readiness-svc

```
