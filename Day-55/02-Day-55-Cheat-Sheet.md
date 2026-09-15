# 💾 Day 55 Cheat Sheet: Persistent Volumes (PV) & Claims (PVC)

## ⚡ Core Storage Commands
```bash
# List all physical hard drives (Cluster-wide)
kubectl get pv

# List all claim tickets in the current namespace
kubectl get pvc

# Check the dynamic provisioners available in the cluster
kubectl get storageclass
kubectl get sc

```

## 🔐 Access Modes Quick Reference

* **`ReadWriteOnce (RWO)`:** Mounted as read-write by a **single node**. (Standard for databases).
* **`ReadOnlyMany (ROX)`:** Mounted read-only by **many nodes**. (Good for shared configs/web assets).
* **`ReadWriteMany (RWX)`:** Mounted read-write by **many nodes**. (Requires advanced network storage like NFS or AWS EFS).

## ♻️ Reclaim Policies (What happens when PVC is deleted?)

* **`Retain`:** The PV transitions to `Released`. Data is kept safe on the disk for manual recovery. (Standard for manual/static provisioning).
* **`Delete`:** The underlying cloud hard drive is instantly and permanently destroyed. (Standard for dynamic provisioning).

## 📄 Quick YAML Snippets

**1. The Claim (PVC):**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard # Leave as "" for static provisioning

```

**2. The Consumer (Pod Mount):**

```yaml
    # 1. Inside the container block:
    volumeMounts:
    - name: data-disk
      mountPath: /var/lib/data
      
  # 2. Inside the pod block (bottom of file):
  volumes:
  - name: data-disk
    persistentVolumeClaim:
      claimName: my-claim

```

## 🚨 SRE Troubleshooting Quick Fixes

* **PVC stuck in `Pending` state forever?**
* *Cause 1:* `WaitForFirstConsumer` is enabled. The PVC won't bind until you deploy a Pod that uses it.
* *Cause 2:* You requested an Access Mode or Capacity that no available PV can satisfy.
* *Cause 3:* You are trying to use a manual PV, but forgot to set `storageClassName: ""` in your PVC.


* **PVC stuck in `Terminating` state?**
* *Cause:* **PVC Protection**. A running Pod is still actively using the claim. You must `kubectl delete pod <name>` first to release the lock on the storage before the PVC can be deleted.


* **Data disappeared after Pod restart?**
* *Cause:* You used an `emptyDir: {}` volume instead of a PVC. `emptyDir` is ephemeral and strictly tied to the Pod's lifecycle.

## 🕵️‍♂️ Advanced SRE Troubleshooting 

*   **Pod stuck in `ContainerCreating` with a `Multi-Attach Error`?**
    *   *Cause:* You are using a `ReadWriteOnce` (RWO) volume, and Kubernetes is trying to spin up a new Pod on **Node B** before the old Pod on **Node A** has completely terminated. The cloud provider refuses to attach the hard drive to two different nodes at the same time.
    *   *Resolution:* Delete the stuck Pod, forcefully terminate the old Pod if it is hanging (`kubectl delete pod <name> --force`), and ensure your Deployments use `strategy: Recreate` instead of `RollingUpdate` for RWO stateful applications.

*   **Cannot reuse a `Released` manual PV? (The Retain Trap)**
    *   *Cause:* When a PVC is deleted and the PV has a `Retain` policy, the PV status changes to `Released`. However, it still holds a hidden reference to the old claim ticket (`claimRef`). Kubernetes will **not** allow a brand new PVC to bind to it, even if the names match perfectly.
    *   *Resolution:* You must edit the PV and manually delete the `claimRef` block. 
        1. Run `kubectl edit pv <pv-name>`
        2. Delete the entire `claimRef:` section (usually at the bottom of the `spec`).
        3. Save and exit. The PV will instantly change back to `Available` and can be claimed again!

*   **Pod fails to start due to `node affinity conflict`?**
    *   *Cause:* In cloud environments (AWS/GCP), physical hard drives exist in specific Availability Zones (e.g., `us-east-1a`). If you use immediate dynamic provisioning, the drive might be created in Zone A, but your Pod gets scheduled on a Worker Node in Zone B. 
    *   *Resolution:* This is exactly why the `VolumeBindingMode: WaitForFirstConsumer` rule exists on your StorageClass. Always ensure this is enabled so the disk is created in the exact same zone where the Pod lands.
