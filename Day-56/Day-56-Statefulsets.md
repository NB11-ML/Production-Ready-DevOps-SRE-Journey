# 🗄️ Day 56: Kubernetes StatefulSets

Deployments are incredible for stateless applications (like web servers or APIs) where any Pod can be destroyed and replaced without consequence. But what happens when you need to run a **database** like MySQL, PostgreSQL, or Kafka?

Databases require:
1.  **Stable Identity:** Pod `db-1` must always be `db-1`, even if it restarts.
2.  **Stable Storage:** Pod `db-1` must always reconnect to its exact same physical hard drive.
3.  **Ordered Startup:** Primary nodes must start before replica nodes.

Today, we transition from stateless to stateful architecture using **StatefulSets**.

---

## 📖 SRE Theory: Deployments vs. StatefulSets

| Feature | Deployment (Stateless) | StatefulSet (Stateful) |
| :--- | :--- | :--- |
| **Pod Names** | Random (e.g., `app-xyz-abc`) | Stable, predictable (e.g., `app-0`, `app-1`) |
| **Startup Order** | All at once (Parallel) | Ordered sequentially (`0`, then `1`, then `2`) |
| **Storage** | Shared PVC (usually) | Each Pod gets its own unique PVC |
| **Network Identity** | Load-balanced, random IP | Stable DNS name per individual Pod |

### Core StatefulSet Components
1.  **Headless Service (`clusterIP: None`):** Instead of giving the Service a single load-balanced IP, a Headless Service creates individual DNS records for *every single Pod* in the StatefulSet.
2.  **`volumeClaimTemplates`:** Instead of creating PVCs manually (like we did in Day 55), the StatefulSet uses this template to automatically generate a unique PVC and PV for every single replica it creates.

---

## 🚀 Challenge Tasks & Execution

### Task 1: Understand the Problem (The Deployment Trap)
First, let's see why Deployments fail at stateful workloads.

**1. Create a quick Deployment:**
```bash
kubectl create deployment nginx-deploy --image=nginx --replicas=3
kubectl get pods

```

*(Notice the random names like `nginx-deploy-6d4b55c659-abcde`)*

**2. Delete a Pod and watch it return:**

```bash
kubectl delete pod <pod-name>
kubectl get pods

```
The replacement Pod has a completely different random name!

<img width="2396" height="820" alt="image" src="https://github.com/user-attachments/assets/c791df45-b299-4513-bfd7-f132f31312c9" />

> **✅ Verify:** *Why would random pod names be a problem for a database cluster?*
> **Answer:** Database clusters rely on strict replication topologies (e.g., Primary and Secondary nodes). If a Secondary node needs to sync data from the Primary node, it needs to know the Primary's exact network address. If Pod names and IPs change randomly every time a Pod crashes, the cluster cannot maintain its replication topology and will break.

**3. Clean up before moving on:**

```bash
kubectl delete deployment nginx-deploy

```
<img width="2392" height="358" alt="image" src="https://github.com/user-attachments/assets/112cef81-9c07-49bf-9d8a-57855b86a322" />


---

### Task 2: Create a Headless Service

StatefulSets require a Headless Service to manage their network identity.

**1. Create `headless-svc.yaml`:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
  labels:
    app: nginx
spec:
  clusterIP: None  # <-- This makes it "Headless"
  selector:
    app: nginx
  ports:
  - port: 80
    name: web

```

**2. Apply and verify:**

```bash
kubectl apply -f headless-svc.yaml
kubectl get svc nginx-headless

```

<img width="2228" height="1346" alt="image" src="https://github.com/user-attachments/assets/24059117-f49e-47ba-bd9c-2810dfb75c6b" />


> **✅ Verify:** *What does the CLUSTER-IP column show?*

> **Answer:** It shows `None`.

---

### Task 3: Create the StatefulSet

Now we deploy the actual stateful workload with dynamically generated storage.

**1. Create `statefulset.yaml`:**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx-headless" # Must match our Headless Service
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        volumeMounts:
        - name: web-data
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: web-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Mi

```

**2. Apply and observe the ordered creation:**

```bash
# Open a second terminal window to watch the pods spin up sequentially!
kubectl get pods -l app=nginx -w

# In your main terminal, apply the manifest:
kubectl apply -f statefulset.yaml

```

**3. Check the automatically generated storage:**

```bash
kubectl get pvc

```

https://github.com/user-attachments/assets/b1481edc-3df5-427e-8da2-496448e57a21

> **✅ Verify:** *What are the exact pod names and PVC names?*
> **Answer:**
> * **Pod Names:** `web-0`, `web-1`, `web-2` (Created strictly in that order).
> * **PVC Names:** `web-data-web-0`, `web-data-web-1`, `web-data-web-2` (Format is `<template-name>-<pod-name>`).

<img width="2814" height="1660" alt="image" src="https://github.com/user-attachments/assets/3858d21b-3d5e-4a0f-adea-cad7f47ff6ab" />

---

### Task 4: Stable Network Identity

Let's prove that each Pod has its own permanent, resolvable DNS name.

**1. Spin up a temporary DNS testing Pod:**

```bash
kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh

```

**2. Inside the busybox shell, test the DNS resolution:**
*Format: `<pod-name>.<service-name>.<namespace>.svc.cluster.local*`

```bash
nslookup web-0.nginx-headless.default.svc.cluster.local
nslookup web-1.nginx-headless.default.svc.cluster.local
nslookup web-2.nginx-headless.default.svc.cluster.local
exit

```
**3. Compare with actual Pod IPs:**

```bash
kubectl get pods -o wide

```

> **✅ Verify:** *Does the nslookup IP match the pod IP?*
> **Answer:** Yes! The Headless Service successfully routed the exact internal DNS query to the specific, individual Pod IP.

<img width="1928" height="1250" alt="image" src="https://github.com/user-attachments/assets/4701f163-1a9b-4958-9e13-e0646b49460b" />

---

### Task 5: Stable Storage (Disaster Recovery Test)

Let's prove that if `web-0` dies, the replacement `web-0` gets its exact same data back.

**1. Write unique data to `web-0`:**

```bash
kubectl exec web-0 -- sh -c "echo 'Data from web-0' > /usr/share/nginx/html/index.html"

```

**2. Nuke the Pod:**

```bash
kubectl delete pod web-0

```

**3. Wait for Kubernetes to recreate it, then read the data:**

```bash
# Wait for web-0 to show 1/1 Running again
kubectl get pods -w 

# Check the file contents
kubectl exec web-0 -- cat /usr/share/nginx/html/index.html

```

> **✅ Verify:** *Is the data identical after pod recreation?*
> **Answer:** Yes! The output is exactly `"Data from web-0"`. When the StatefulSet recreated `web-0`, it automatically re-attached it to `web-data-web-0`, proving our state survived a container crash.

<img width="2936" height="542" alt="image" src="https://github.com/user-attachments/assets/7ff69741-57ba-466d-9b00-637d2aaae818" />

---

### Task 6: Ordered Scaling

StatefulSets scale carefully to prevent database split-brain scenarios.

**1. Scale Up:**

```bash
kubectl scale statefulset web --replicas=5
kubectl get pods -w

```

*(Notice they create in strict order: `web-3`, then `web-4`)*

**2. Scale Down:**

```bash
kubectl scale statefulset web --replicas=3
kubectl get pods -w

```

*(Notice they terminate in reverse strict order: `web-4`, then `web-3`)*

**3. Check Storage:**

```bash
kubectl get pvc

```
<img width="2932" height="628" alt="image" src="https://github.com/user-attachments/assets/b50f5e4a-25bb-45a4-a374-7386842e6b45" />


> **✅ Verify:** *After scaling down, how many PVCs exist?*
> **Answer:** **Five PVCs still exist.** Kubernetes intentionally leaves the PVCs for `web-3` and `web-4` intact. If you ever scale back up to 5, those Pods will seamlessly pick up exactly where they left off without data loss.

---

### Task 7: Clean Up

Let's tear down the lab safely.

**1. Delete the Workloads:**

```bash
kubectl delete statefulset web
kubectl delete svc nginx-headless

```

**2. Check the Storage:**

```bash
kubectl get pvc

```

> **✅ Verify:** *Were PVCs auto-deleted with the StatefulSet?*
> **Answer:** No! This is a critical SRE safety feature. Deleting a StatefulSet destroys the compute, but it leaves the data untouched to prevent catastrophic accidental data deletion.

**3. Manually destroy the hard drives (PVCs):**

```bash
kubectl delete pvc web-data-web-0 web-data-web-1 web-data-web-2 web-data-web-3 web-data-web-4

```

<img width="2926" height="1012" alt="image" src="https://github.com/user-attachments/assets/6698e8b2-6883-4717-8dd2-325492fdcbd6" />

---

