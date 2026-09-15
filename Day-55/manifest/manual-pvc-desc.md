# 🎫 PersistentVolumeClaim (PVC) Manifest Breakdown
**File:** `manual-pvc.yaml`

If the Persistent Volume (PV) is the physical hard drive provided by the administrator, the Persistent Volume Claim (PVC) is the **claim ticket** created by a developer requesting a piece of that storage. 

Unlike a PV (which is cluster-wide), a PVC is a **namespaced** resource that belongs directly to your application's environment.

### 📝 Line-by-Line YAML Explanation

**1. The API & Resource Type**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim

```

* `apiVersion: v1`: Uses the core Kubernetes API.
* `kind: PersistentVolumeClaim`: Tells Kubernetes that an application in this namespace is requesting storage infrastructure.

**2. The Identity**

```yaml
metadata:
  name: manual-pvc

```

* `name: manual-pvc`: The unique name for this claim ticket. Later, when we write our Pod manifest, we will tell the Pod to attach to this exact name.

**3. The Blueprint Specifications**

```yaml
spec:
  storageClassName: ""

```

* `storageClassName: ""`: **The SRE Binding Override.** By setting this to an empty string, we explicitly disable Kubernetes' dynamic provisioning (which would normally spin up a brand new cloud volume). This forces the cluster to look for a *statically* provisioned PV (like our `manual-pv`) that has no storage class assigned.

**4. Access Rules**

```yaml
  accessModes:
    - ReadWriteOnce

```

* `ReadWriteOnce`: The requested access mode. **Crucial Rule:** The access mode requested by the PVC must perfectly match the access mode offered by the PV, or Kubernetes will refuse to bind them together.

**5. The Storage Request**

```yaml
  resources:
    requests:
      storage: 500Mi

```

* `storage: 500Mi`: We are requesting 500 Megabytes of storage.
* *SRE Context:* Because our `manual-pv` is `1Gi` (1024Mi), it has more than enough space to satisfy this 500Mi request. Kubernetes will successfully bind them. However, the remaining 524Mi on that PV is now "locked" — no other PVC can claim the leftover space. A PV can only be bound to exactly one PVC at a time!

---

### 🚀 Execution Commands

**1. Submit the Claim**

```bash
kubectl apply -f manual-pvc.yaml

```

* **What it does:** Sends your claim ticket to the Kubernetes API. The cluster's control plane instantly acts as a matchmaker, scanning all available PVs to find one that satisfies your capacity (`500Mi`) and access mode (`ReadWriteOnce`) requirements.

**2. Verify the Developer's View (The Claim)**

```bash
kubectl get pvc

```

* **What it does:** Lists the claims in your namespace.
* **What to look for:** You want the `STATUS` to say `Bound` and the `VOLUME` to explicitly list `manual-pv`. If it says `Pending`, it means Kubernetes could not find a PV that matches your exact requirements (or a dynamic provisioner is failing).

**3. Verify the Administrator's View (The Infrastructure)**

```bash
kubectl get pv

```

* **What it does:** Lists the physical volumes across the whole cluster.
* **What to look for:** The `manual-pv` status will have flipped from `Available` to `Bound`, and the `CLAIM` column will now show `default/manual-pvc`, proving that this specific hard drive is locked to your claim ticket.

```

```
