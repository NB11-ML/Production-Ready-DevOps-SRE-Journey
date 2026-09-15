# 📦 Persistent Pod Manifest Breakdown
**File:** `pvc-pod.yaml`

We have our physical storage (PV) and our claim ticket (PVC). Now, it is time to actually attach that storage to a running application. This manifest proves that by decoupling the storage from the Pod, our data will survive a complete container crash or deletion.

### 📝 Line-by-Line YAML Explanation

**1. The API & Resource Type**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: persistent-pod

```

* We are creating a standard Kubernetes Pod named `persistent-pod`.

**2. The Container Blueprint**

```yaml
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ["/bin/sh", "-c", "sleep 3600"]

```

* We use the lightweight `busybox` Linux image.
* `command`: Because Busybox isn't a web server (like Nginx), it will exit immediately upon starting. The `sleep 3600` command keeps the container alive for an hour so we have time to `exec` inside and test our storage.

**3. The Internal Mount (Inside the Container)**

```yaml
    volumeMounts:
    - name: persistent-storage
      mountPath: /data

```

* **Crucial SRE Concept:** This block belongs to the *container*. It tells the container: "Look for a volume named `persistent-storage` and plug it into my internal file system at the `/data` directory."

**4. The External Volume (Outside the Container)**

```yaml
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: manual-pvc

```

* This block belongs to the *Pod*. It tells Kubernetes how to construct the volume named `persistent-storage`.
* `persistentVolumeClaim -> claimName: manual-pvc`: This is the magic link! Instead of creating a temporary `emptyDir` (which deletes data on crash), it attaches our `manual-pvc` claim ticket. Kubernetes reads the ticket, finds the locked `manual-pv` hard drive, and physically mounts it to this Pod.

---

### 🚀 Execution & SRE Chaos Testing Breakdown

**1. Deploy the Pod**

```bash
kubectl apply -f pvc-pod.yaml

```

* **What it does:** Kubernetes spins up the Pod and attaches the PV.

**2. Inject the Test Data**

```bash
kubectl exec persistent-pod -- sh -c "echo 'SRE Data Test 1' > /data/message.txt"
kubectl exec persistent-pod -- cat /data/message.txt

```

* **What it does:** We jump into the running container, write a string of text into a file called `message.txt` inside our `/data` mount, and read it back to confirm it saved.

**3. Simulate a Catastrophic Crash**

```bash
kubectl delete pod persistent-pod

```

* **What it does:** We completely destroy the container. In Task 1 with `emptyDir`, this action permanently destroyed our data.

**4. Recreate and Verify (The Punchline)**

```bash
kubectl apply -f pvc-pod.yaml
kubectl exec persistent-pod -- cat /data/message.txt

```

* **What it does:** We spin up a brand new instance of the Pod, which automatically reattaches to the same PVC. We then check inside the `/data` folder.
* **The Result:** The file prints `SRE Data Test 1`. You have successfully decoupled your application's state from its compute lifecycle. The data outlived the container!

```
