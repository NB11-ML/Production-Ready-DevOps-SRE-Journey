# 🪄 Dynamic PersistentVolumeClaim (PVC) Breakdown
**File:** `dynamic-pvc.yaml`

In modern DevOps and Cloud environments (AWS, GCP, Azure), administrators do not manually create hard drives (PVs) in advance. Instead, we use **Dynamic Provisioning**. This manifest is a request that tells the Kubernetes cluster: *"Manufacture a brand new hard drive for me on the fly."*

### 📝 Line-by-Line YAML Explanation

**1. The API & Resource Type**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim

```

* We are creating a standard claim ticket (PVC) in the core `v1` API.

**2. The Identity**

```yaml
metadata:
  name: dynamic-pvc

```

* `name: dynamic-pvc`: This is the unique identifier for our claim. Our Pod will use this exact name to attach the resulting storage.

**3. The Storage Engine Trigger**

```yaml
spec:
  storageClassName: standard

```

* `storageClassName: standard`: **This is the most important line.** Instead of setting this to `""` (which looks for a manual PV), we are explicitly calling the `standard` StorageClass.
* *SRE Context:* In our `kind` cluster, the `standard` class is powered by the `rancher.io/local-path` provisioner. In a real cloud, this might be `aws-ebs` or `gce-pd`. This line wakes up the cloud provider and asks it to provision physical hardware.

**4. Access Rules & Sizing**

```yaml
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi

```

* `ReadWriteOnce`: The new hard drive should be exclusively mountable by a single node to prevent data corruption.
* `storage: 2Gi`: We are instructing the automated provisioner to carve out exactly 2 Gigabytes of space.

```

---
