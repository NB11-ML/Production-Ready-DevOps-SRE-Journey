# 🚀 Day 52: Kubernetes Namespaces and Deployments ☸️

Yesterday we created standalone Pods. The problem? Delete a Pod and it is gone forever — no one recreates it. 

Today we will fix that with Deployments, the enterprise standard for running applications in Kubernetes. 

We will also learn Namespaces, which let you organize and isolate resources inside a cluster.

---

### Task 1: Explore Default Namespaces
Kubernetes comes with built-in namespaces to separate user workloads from cluster management operations.

**List all default namespaces:**
```bash
kubectl get namespaces

```

* **`default`**: Where your resources go if you do not specify a namespace.
* **`kube-system`**: The Kubernetes Control Plane components (API server, scheduler, etcd).
* **`kube-public`**: Publicly readable resources.
* **`kube-node-lease`**: Node heartbeat tracking.

**Inspect the Control Plane:**

```bash
kubectl get pods -n kube-system

```

<img width="2490" height="822" alt="image" src="https://github.com/user-attachments/assets/fc335cc6-86be-4a79-9020-05da7e7fa644" />


*Verification:* These pods are the brain of your cluster. You should see components like `etcd`, `kube-apiserver`, `kube-controller-manager`, and `kube-scheduler` running here. Never manually delete these.

---

### Task 2: Create and Use Custom Namespaces

Create two distinct namespaces to simulate a real-world multi-environment cluster.

**Imperative Creation:**

```bash
kubectl create namespace dev
kubectl create namespace staging

```

**Declarative Creation (YAML):**

```yaml
# production-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production

```

```bash
kubectl apply -f production-namespace.yaml

```

**Deploying to specific namespaces:**

```bash
kubectl run nginx-dev --image=nginx:latest -n dev
kubectl run nginx-staging --image=nginx:latest -n staging

```

**Viewing across namespaces:**

Running `kubectl get pods` will show nothing (it defaults to the `default` namespace). 
You must specify the namespace or use `-A` to see everything:

```bash
kubectl get pods -A

```

<img width="2484" height="1372" alt="image" src="https://github.com/user-attachments/assets/094e479c-5dcf-4262-b819-1740e014bbd7" />

---

### Task 3: Create Your First Deployment

A Deployment guarantees that a specific number of Pod replicas are running at all times.

**Manifest: `nginx-deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: dev
  labels:
    app: nginx
spec:
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
        image: nginx:1.24
        ports:
        - containerPort: 80

```

**Key Differences from a Pod:**

* **`kind: Deployment`** and **`apiVersion: apps/v1`**.
* **`replicas: 3`**: Tells the cluster to maintain 3 identical pods.
* **`selector.matchLabels`**: Connects the Deployment to its Pods.
* **`template`**: The blueprint used to stamp out the new Pods.

**Apply and Check:**

```bash
kubectl apply -f nginx-deployment.yaml
kubectl get deployments -n dev
kubectl get pods -n dev

```

*Verification:* The columns in `get deployments` mean:

* **READY**: How many replicas are available vs desired (e.g., 3/3).
* **UP-TO-DATE**: Replicas that match the current deployment spec.
* **AVAILABLE**: Replicas running and successfully serving traffic.

<img width="2486" height="666" alt="image" src="https://github.com/user-attachments/assets/15ce8ee4-a63b-4ea0-924e-d6f27e4bf281" />

---

### Task 4: Self-Healing — Delete a Pod and Watch It Come Back

This is the core difference between a Deployment and a standalone Pod.

```bash
# List current pods
kubectl get pods -n dev

# Delete one specific pod manually
kubectl delete pod <insert-pod-name-here> -n dev

# Instantly check the pods again
kubectl get pods -n dev

```

*Verification:* The Deployment controller detected a drift (2 running vs 3 desired) and instantly spun up a replacement. The replacement pod has a completely different, randomly generated suffix in its name.

<img width="2388" height="886" alt="image" src="https://github.com/user-attachments/assets/ab0adc3a-ea34-43a4-b75c-37f6420cc9ec" />


---

### Task 5: Scale the Deployment

Scale horizontally to handle traffic spikes.

**Imperative Scaling:**

```bash
# Scale up to 5
kubectl scale deployment nginx-deployment --replicas=5 -n dev
kubectl get pods -n dev

# Scale down to 2
kubectl scale deployment nginx-deployment --replicas=2 -n dev
kubectl get pods -n dev

```

<img width="2384" height="616" alt="image" src="https://github.com/user-attachments/assets/e31efb80-ed4e-415e-884d-305978adcf7b" />
<img width="2422" height="470" alt="image" src="https://github.com/user-attachments/assets/ae5d8a06-cc1c-4195-9356-a526e86a3959" />


**Declarative Scaling:**

Change `replicas: 4` directly in `nginx-deployment.yaml` and run `kubectl apply -f nginx-deployment.yaml`.
*Verification:* When you scale down, Kubernetes gracefully terminates the extra pods, changing their status to `Terminating` until they are destroyed.

<img width="2396" height="1390" alt="image" src="https://github.com/user-attachments/assets/76aacc8b-aea6-4000-9397-60e3db32ce79" />


---

### Task 6: Rolling Update and Rollback

Update versions with zero downtime.

**Trigger a Rolling Update (1.24 to 1.25):**

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.25 -n dev

```

**Watch the Rollout in Real-Time:**

```bash
kubectl rollout status deployment/nginx-deployment -n dev

```
<img width="2382" height="404" alt="image" src="https://github.com/user-attachments/assets/ebfdee38-3566-4d7e-850e-0abd60f19a6e" />
<img width="2398" height="270" alt="image" src="https://github.com/user-attachments/assets/9d872f57-5e39-4ff5-bd3c-a91024b50f35" />


*Note: Kubernetes replaces pods one by one. Old pods are terminated only after new ones are healthy.*

**Check History and Rollback:**

```bash
# View deployment revisions
kubectl rollout history deployment/nginx-deployment -n dev

# Rollback to the previous version
kubectl rollout undo deployment/nginx-deployment -n dev
kubectl rollout status deployment/nginx-deployment -n dev

# Verify the image is back to 1.24
kubectl describe deployment nginx-deployment -n dev | grep Image

```

<img width="2908" height="892" alt="image" src="https://github.com/user-attachments/assets/8d612dac-58e8-44c2-839e-7b1437f7eaed" />
<img width="2394" height="1036" alt="image" src="https://github.com/user-attachments/assets/939c38a3-6acd-4277-ab28-4f6d08b9923d" />

---

### Task 7: Clean Up

Deleting a namespace cascades and deletes everything inside it.

```bash
kubectl delete deployment nginx-deployment -n dev
kubectl delete pod nginx-dev -n dev
kubectl delete pod nginx-staging -n staging
kubectl delete namespace dev staging production

kubectl get namespaces
kubectl get pods -A

```

<img width="2474" height="1254" alt="image" src="https://github.com/user-attachments/assets/6241da55-9a97-45b8-8a08-8374a761cc40" />
<img width="2492" height="976" alt="image" src="https://github.com/user-attachments/assets/0f057fbd-f6b7-4e81-b36f-18932c7ef088" />


*Verification:* All custom namespaces and the resources previously running inside them are completely gone.

---

### Hints & Best Practices

* `kubectl get <resource> -n <namespace>` — Targets a specific namespace.
* `kubectl get <resource> -A` — Lists resources across all namespaces globally.
* `selector.matchLabels` must exactly match `template.metadata.labels` — if they do not match, the Deployment will not be able to manage the Pods.
* `kubectl set image` — Updates a container image quickly without editing the YAML file.
* Deployments create ReplicaSets behind the scenes to manage the pods. View them with `kubectl get replicasets -n dev`.

```
