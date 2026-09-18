# 📈 Day 58 Cheat Sheet: Metrics Server & HPA

## ⚡ Core Observability & Scaling Commands
```bash
# View real-time node resource consumption
kubectl top nodes

# View real-time pod consumption across all namespaces, sorted by CPU
kubectl top pods -A --sort-by=cpu

# Create a basic HPA imperatively (autoscaling/v1 - CPU only)
kubectl autoscale deployment my-app --cpu-percent=50 --min=1 --max=10

# Patch Metrics Server for local VM testing (Bypass self-signed certs)
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

```

## 🧠 HPA Scaling Logic

The Horizontal Pod Autoscaler runs a control loop (default 15s) and calculates scaling requirements using this exact formula:

> **`desiredReplicas = ceil(currentReplicas * (currentUsage / targetUsage))`**

* **Scale Up:** Extremely aggressive by default. If load spikes, HPA immediately spins up replicas to prevent outages.
* **Scale Down:** Conservative by default. HPA waits for a **5-minute Stabilization Window** before terminating pods, preventing "thrashing" if traffic fluctuates.

## 🆚 autoscaling/v1 vs autoscaling/v2

| Feature | `autoscaling/v1` (Imperative) | `autoscaling/v2` (Declarative) |
| --- | --- | --- |
| **Metrics Supported** | CPU percentage only. | CPU, Memory, and Custom Metrics (e.g., Queue length). |
| **Scaling Behavior** | Hardcoded defaults. | Fully customizable via the `behavior` block. |
| **Creation Method** | `kubectl autoscale` | YAML Manifests. |

## 📄 Quick YAML Snippet (autoscaling/v2)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: production-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300 # Wait 5 mins before scaling down
    scaleUp:
      stabilizationWindowSeconds: 0   # React instantly to traffic spikes

```

## 🚨 SRE Troubleshooting & Gotchas

* **HPA TARGETS shows `<unknown>`!**
* *Resolution 1:* Check if the deployment actually has `resources.requests.cpu` defined. HPA cannot calculate a percentage if there is no baseline request.
* *Resolution 2:* Verify the Metrics Server is running (`kubectl top nodes`). If the metrics API is broken, HPA is blind.


* **Difference between `top` and `describe`:**
* `kubectl describe pod`: Shows what you *asked* for (Requests/Limits).
* `kubectl top pod`: Shows what the container is *actually* using right now.



---

## 🎤 Interview Spotlight: HPA Troubleshooting

* **Interview Question:** *"You deployed an application and configured an HPA to scale at 50% CPU. Suddenly, user traffic spikes, but the HPA does not scale up the deployment. What are the first two things you check?"*
* **The SRE Answer:** "First, I would run `kubectl get hpa` to see if the Targets column shows `<unknown>`. If it does, the most common culprit is that the developer forgot to define CPU `requests` in the Deployment manifest, leaving the HPA without a mathematical baseline. If the requests are defined, my second step is to run `kubectl get pods -n kube-system` to verify the `metrics-server` is actually running and healthy, as the HPA relies entirely on its API for real-time utilization data."
