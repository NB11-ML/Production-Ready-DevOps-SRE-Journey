# 🗄️ Day 56 Cheat Sheet: StatefulSets & Headless Services

## ⚡ Core StatefulSet Commands
```bash
# List all StatefulSets (short name: sts)
kubectl get sts

# Watch pods create in strict sequential order
kubectl get pods -l app=nginx -w

# Scale a StatefulSet up or down (maintains strict ordering)
kubectl scale sts web --replicas=5

# Delete a StatefulSet safely (leaves PVCs intact by default)
kubectl delete sts web

```

## 🆚 Deployment vs. StatefulSet

| Feature | Deployment (Stateless) | StatefulSet (Stateful) |
| --- | --- | --- |
| **Pod Identity** | Random (`web-7df6c...`) | Predictable, Indexed (`web-0`, `web-1`) |
| **Startup / Scaling** | Parallel (All at once) | Sequential (`0`, then `1`, then `2`) |
| **Termination** | Random | Reverse Sequential (`2`, then `1`, then `0`) |
| **Storage (PVC)** | Shared (Usually one PVC for all) | Unique (Each pod gets its own PVC) |
| **Network Identity** | Load-balanced (ClusterIP) | Individual DNS per pod (Headless Service) |

## 📄 Quick YAML Snippets

**1. The Headless Service:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
spec:
  clusterIP: None  # <-- The magic line that makes it Headless
  selector:
    app: nginx
  ports:
  - port: 80

```

**2. The StatefulSet (Key Requirements):**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx-headless" # 1. MUST match the Headless Service name
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    # ... standard pod template goes here ...
  
  # 2. Automatically generates a unique PVC for every replica
  volumeClaimTemplates:
  - metadata:
      name: web-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Mi

```

## 🚨 SRE Troubleshooting & Gotchas

* **How do I reach a specific pod internally?**
* *Resolution:* Use the exact DNS format: `<pod-name>.<service-name>.<namespace>.svc.cluster.local`. (Example: `web-0.nginx-headless.default.svc.cluster.local`).


* **I deleted the StatefulSet, but the PVCs and PVs are still there!**
* *Resolution:* This is a built-in Kubernetes safety net to prevent catastrophic database deletion. You must manually run `kubectl delete pvc <pvc-name>` to actually destroy the physical storage.


* **I scaled down my StatefulSet, will I lose data?**
* *Resolution:* No. Scaling down terminates the pod compute, but leaves the unique PVC perfectly intact. If you scale back up, `web-2` will automatically remount the exact `web-data-web-2` PVC it was using before.


* **My StatefulSet pods are stuck in `Pending`!**
* *Resolution:* The `volumeClaimTemplates` likely requested a StorageClass that doesn't exist, or your cluster lacks a dynamic provisioner. Check the PVC status using `kubectl describe pvc <pvc-name>`.


## 🎤 Interview Spotlight: The Database Routing Question

📖 **Interview Question:**

* If you deploy a MySQL database with 1 Primary and 2 Replicas using a StatefulSet, how do you prevent your web application from accidentally sending Write requests to a Read-Only replica? *
   
    *   **The Trap:** Beginners will say "Just use a Kubernetes Service to connect the web app to the database." But a standard Service round-robins traffic randomly. If it routes a Write to `mysql-1` or `mysql-2` (the read-only replicas), the database will reject it and the application will crash!

    *   **The SRE Answer:** "Because StatefulSets provide guaranteed stable network identities, we do not use a standard load-balancing Service for Write operations. Instead, we configure the backend application's database connection string to point exactly to the Primary node's specific DNS record: `mysql-0.mysql-headless.default.svc.cluster.local`. For Read operations, we can either point the application to the replica-specific DNS names, or create a separate Service that only selects pods with a `role: replica` label."
