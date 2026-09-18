# 📈 Day 58: Kubernetes Metrics Server & Horizontal Pod Autoscaler (HPA)

Yesterday, we established strict boundaries using Resource Requests and Limits to protect cluster stability. Today, we put those Requests to work. 

A static cluster is an inefficient cluster. In a production environment, traffic fluctuates wildly. If you over-provision static replicas, you waste money. If you under-provision, your application crashes under load. 

Today, we implement the **Horizontal Pod Autoscaler (HPA)**, an automated control loop that dynamically scales your application's replica count up and down based on real-time CPU and memory utilization gathered by the **Metrics Server**.

---

## 📖 SRE Theory: Observability & Autoscaling

### The Metrics Server
Kubernetes natively knows if a Pod is running or crashing, but it does *not* know how much CPU or RAM that Pod is actually consuming. The **Metrics Server** is a cluster-wide aggregator that polls the `kubelet` on every node every 15 seconds to fetch real-time resource usage data. Without it, HPA cannot function.

### How HPA Calculates Scaling
HPA runs on a continuous control loop (default 15s) and uses the following formula to determine how many Pods should exist:
> `desiredReplicas = ceil(currentReplicas * (currentUsage / targetUsage))`

*Example:* If your target is `50%` CPU, but your pods are currently averaging `100%` CPU, HPA calculates `100 / 50 = 2.0`. It will double your replica count to bring the average back down.

### `autoscaling/v1` vs `autoscaling/v2`
*   **v1:** The legacy API. It only supports scaling based on CPU utilization.
*   **v2:** The modern SRE standard. It supports CPU, Memory, custom application metrics (like queue length), and allows you to define strict `behavior` rules (e.g., how fast to scale up vs. how slowly to scale down).

---

## 🚀 Challenge Tasks & Execution

### Task 1: Install the Metrics Server
First, we must install the observability engine. 

**1. Check if it's already running:**
```bash
kubectl get pods -n kube-system | grep metrics-server

```

**2. Install the Metrics Server:**

* **For Minikube:** `minikube addons enable metrics-server`
* **For Kubeadm / Local VM Clusters:**
```bash
kubectl apply -f [https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml](https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)

```


*(Note: If you are running a local testing VM and the metrics server pod fails to start due to certificate errors, you must edit the deployment `kubectl edit deploy metrics-server -n kube-system` and add the `--kubelet-insecure-tls` flag to the container args).*

**3. Wait 60 seconds, then test:**

```bash
kubectl top nodes

```

> **✅ Verify:** *What is the current CPU and memory usage of your node?*
> **Answer:** *(Check your terminal output! It will look something like this: `primaryvm   150m   7%   1200Mi   30%`)*

---

### Task 2: Explore `kubectl top`

Now that we have metrics, let's view real-time consumption.

**1. Run the top commands:**

```bash
kubectl top nodes
kubectl top pods -A
kubectl top pods -A --sort-by=cpu

```

*Note: `kubectl describe pod` shows what is configured (Requests/Limits). `kubectl top` shows what is ACTUALLY happening right now.*

> **✅ Verify:** *Which pod is using the most CPU right now?*
> **Answer:** *(Look at the top of your sorted output list. It is usually `kube-apiserver` or `etcd` in the `kube-system` namespace when the cluster is idle).*

---

### Task 3: Create a Deployment with CPU Requests

HPA mathematically relies on a baseline to calculate percentages. **If a Pod has no CPU Request defined, HPA will not work.**

**1. Create `php-apache.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  selector:
    matchLabels:
      run: php-apache
  replicas: 1
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache

```

**2. Apply and verify:**

```bash
kubectl apply -f php-apache.yaml
kubectl top pod -l run=php-apache

```

> **✅ Verify:** *What is the current CPU usage of the Pod?*
> **Answer:** *(It should be very close to `0m` or `1m` because it is completely idle with no traffic).*

---

### Task 4: Create an HPA (Imperative)

Let's tell Kubernetes to maintain an average of 50% CPU utilization across all replicas.

**1. Create the HPA:**

```bash
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10

```

**2. Inspect the HPA:**

```bash
kubectl get hpa

```

> **✅ Verify:** *What does the TARGETS column show?*
> **Answer:** Immediately after creation, it will show `<unknown>/50%`. It takes about 15-30 seconds for the Metrics Server to collect the first data points. After a few seconds, it will update to `1%/50%` or similar.

---

### Task 5: Generate Load and Watch Autoscaling

Let's simulate a massive spike in user traffic.

**1. Open a second terminal window and watch the HPA:**

```bash
kubectl get hpa php-apache -w

```

**2. In your main terminal, launch the load generator:**

```bash
kubectl run load-generator --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://php-apache; done"

```

**3. Watch the magic happen:**
Over the next 1-3 minutes, you will see the CPU utilization spike (e.g., `250%/50%`). Kubernetes will automatically increment the `REPLICAS` count to spread the load, eventually stabilizing the CPU percentage back near 50%.

> **✅ Verify:** *How many replicas did HPA scale to under load?*
> **Answer:** *(Your exact number may vary based on VM capacity, but it typically scales up to between 5 and 7 replicas to handle this specific busybox loop).*

*📸 [Insert Screenshot of `kubectl get hpa -w` showing the scale up]*

**4. Stop the attack:**

```bash
kubectl delete pod load-generator

```

*(Note: HPA scales UP rapidly to save crashing apps, but it scales DOWN very slowly—a 5-minute stabilization window—to prevent "thrashing" if traffic spikes again).*

---

### Task 6: Create an HPA from YAML (Declarative)

Imperative commands only create `autoscaling/v1` resources. Let's use the modern `v2` API to gain strict behavioral control over our scaling.

**1. Delete the imperative HPA:**

```bash
kubectl delete hpa php-apache

```

**2. Create `hpa-v2.yaml`:**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15

```

**3. Apply and verify:**

```bash
kubectl apply -f hpa-v2.yaml
kubectl describe hpa php-apache

```

> **✅ Verify:** *What does the behavior section control?*
> **Answer:** The `behavior` section dictates the velocity of scaling. In our configuration, it dictates that scaling UP has no stabilization delay (`0` seconds - meaning it reacts instantly to spikes), while scaling DOWN requires a 5-minute cooldown (`300` seconds) to prevent rapid fluctuations if load drops temporarily.

---

### Task 7: Clean Up

Wipe the slate clean for tomorrow, but leave the observability engine running!

```bash
kubectl delete -f hpa-v2.yaml
kubectl delete -f php-apache.yaml
# We intentionally leave the metrics-server running for future modules!

```
