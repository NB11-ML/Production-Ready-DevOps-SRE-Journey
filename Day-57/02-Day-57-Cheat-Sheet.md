# 🚦 Day 57 Cheat Sheet: Resources, Limits & Probes

## ⚡ Core Troubleshooting Commands
```bash
# Check why a Pod is pending, restarted, or OOMKilled
kubectl describe pod <pod-name>

# View live CPU and Memory usage (requires Metrics Server)
kubectl top pods
kubectl top nodes

# Watch Pod state changes in real-time
kubectl get pods -w

```

## 🆚 Requests vs. Limits

| Concept | Definition | Enforced By | Failure Behavior |
| --- | --- | --- | --- |
| **Requests** | The guaranteed minimum hardware required. | **Scheduler** (At deployment time) | Pod stays in `Pending` state if no Node has enough capacity. |
| **Limits** | The absolute maximum hardware allowed. | **Kubelet** (At runtime) | CPU is throttled (slowed). Memory is **OOMKilled** (Exit Code 137). |

## 📊 Quality of Service (QoS) Classes

When a Node runs out of memory, Kubernetes evicts Pods in this order:

1. **BestEffort (Evicted First):** No requests or limits are set.
2. **Burstable (Evicted Second):** Requests are lower than Limits.
3. **Guaranteed (Evicted Last):** Requests and Limits are exactly equal.

## 🩺 Health Probes Cheat Sheet

| Probe Type | What it checks | Failure Action | Use Case |
| --- | --- | --- | --- |
| **Startup** | Is the application fully booted? | Kills & Restarts | Legacy/Slow apps (e.g., Java Spring Boot). |
| **Liveness** | Is the application deadlocked/frozen? | Kills & Restarts | Self-healing a stuck process. |
| **Readiness** | Can it handle user traffic right now? | Removes from Service | Database syncing, temporary overload. |

## 📄 Quick YAML Snippet (The SRE Gold Standard)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: production-ready-pod
spec:
  containers:
  - name: my-app
    image: nginx
    resources:
      requests:
        cpu: "100m"      # 0.1 Cores
        memory: "128Mi"
      limits:
        cpu: "500m"      # 0.5 Cores
        memory: "256Mi"
    readinessProbe:
      httpGet:
        path: /healthz
        port: 80
      periodSeconds: 5

```

## 🚨 SRE Troubleshooting & Gotchas

* **Pod status is `Pending` forever!**
* *Resolution:* Run `kubectl describe pod`. The Events will show `FailedScheduling` because you requested more CPU/Memory than any single physical node in your cluster has available.


* **Container keeps restarting with `Exit Code 137`!**
* *Resolution:* 137 means `OOMKilled` (Out of Memory). The application tried to use more RAM than its `limit` allowed. The developer needs to fix a memory leak, or you need to increase the memory limit.


* **Application is running, but nobody can reach it through the Service!**
* *Resolution:* Check the Readiness probe. If a Readiness probe fails, the Pod stays `Running` (0/1 Ready) but its IP address is silently removed from the Service Endpoints to protect users from hitting a broken app.



---

## 🎤 Interview Spotlight: The "Noisy Neighbor" Question

* **Interview Question:** *"A developer deploys a new application to our production cluster without setting any resource limits. Suddenly, three other critical applications on the same Node crash. What happened, and how do you prevent it?"*
* **The SRE Answer:** "The new application caused a 'Noisy Neighbor' incident. Because it had no limits, it defaulted to a `BestEffort` QoS class and had a memory leak that consumed all the Node's RAM. To protect the node, the Linux kernel started OOMKilling processes. To prevent this, I would implement a `LimitRange` or `ResourceQuota` at the Namespace level to strictly enforce that all Pods *must* have CPU and Memory limits defined before the API server will even accept their deployment."
