# 💾 PersistentVolume (PV) Manifest Breakdown
**File:** `manual-pv.yaml`

This manifest acts as a blueprint for a Cluster Administrator (you) to manually carve out a piece of physical storage and make it available to the Kubernetes cluster.

### 📝 Line-by-Line YAML Explanation

**1. The API & Resource Type**
```yaml
apiVersion: v1
kind: PersistentVolume

```

* `apiVersion: v1`: We are using the core Kubernetes API.
* `kind: PersistentVolume`: We are telling Kubernetes to create a PV. Note that a PV is a **cluster-wide** resource. It does not belong to any specific namespace. It is a raw piece of infrastructure, like a physical hard drive plugged into a server.

**2. The Identity**

```yaml
metadata:
  name: manual-pv

```

* `name: manual-pv`: The unique identifier for this storage block. When a developer creates a PVC (Claim), Kubernetes will look at this name and its specifications to see if it's a match.

**3. The Blueprint Specifications**

```yaml
spec:
  capacity:
    storage: 1Gi

```

* `spec:`: The beginning of the actual hardware specifications.
* `capacity:` -> `storage: 1Gi`: We are strictly allocating exactly 1 Gigabyte of space. If a developer later creates a PVC asking for `2Gi`, Kubernetes will refuse to bind them to this volume because it is too small.

**4. Access Rules**

```yaml
  accessModes:
    - ReadWriteOnce

```

* `ReadWriteOnce (RWO)`: This restricts the volume so it can only be mounted as read-write by a **single Kubernetes Node at a time**.
* *SRE Context:* This is the standard safeguard for stateful applications like databases (MySQL, PostgreSQL) to ensure two different nodes don't try to write to the exact same database file simultaneously, which would cause catastrophic data corruption.

**5. The Safety Net**

```yaml
  persistentVolumeReclaimPolicy: Retain

```

* `Retain`: This dictates what happens to the physical storage if the developer deletes their PVC (Claim). By setting it to `Retain`, we ensure the data is kept completely intact. The PV will enter a `Released` state, allowing an administrator to manually back up the data or reassign it. (The alternative is `Delete`, which would instantly wipe the hard drive!).

**6. The Storage Backend (Where does it physically live?)**

```yaml
  hostPath:
    path: "/tmp/k8s-pv-data"
    type: DirectoryOrCreate

```

* `hostPath`: Tells Kubernetes to use the physical hard drive of the Worker Node that the Pod lands on.
* `path: "/tmp/k8s-pv-data"`: The exact folder on the Node's OS where the data will be saved.
* `type: DirectoryOrCreate`: If the folder `/tmp/k8s-pv-data` does not exist on the node, Kubernetes will automatically run a `mkdir` to create it before attempting to save data there.
* *SRE Context:* `hostPath` is excellent for local testing in `kind` or Minikube, but it is **strictly forbidden in multi-node production clusters**. If a Pod dies and is rescheduled to a *different* node, it won't have access to the `/tmp` folder of the old node! Production uses cloud storage like AWS EBS.

---

### 🚀 Execution Commands

**1. Create the Resource**

```bash
kubectl apply -f manual-pv.yaml

```

* **What it does:** Sends the blueprint to the Kubernetes API server. The API server validates the syntax and registers the 1Gi storage block as available infrastructure in the cluster.

**2. Verify the Status**

```bash
kubectl get pv

```

* **What it does:** Lists all PersistentVolumes in the entire cluster.
* **What to look for:** You want to see the `STATUS` column listed as `Available`. This means the storage is healthy, registered, and patiently waiting for a developer to create a PVC to claim it!

```

```
