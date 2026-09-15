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
