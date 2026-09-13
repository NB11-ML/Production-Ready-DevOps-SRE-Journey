# 🚀 Day 53: Kubernetes Services & The Networking Layer ☸️

### 🤔 The Core Problem: Why Services?

Every Pod gets its own IP address. But there are two problems:
1. **Pod IPs are not stable:** When a Pod restarts or gets replaced, it gets a new IP.
2. **A Deployment runs multiple Pods:** Which IP do you connect to?

**A Service solves both problems. It provides:**
* A stable IP and DNS name that never changes.
* Load balancing across all Pods that match its selector.

```text
[Client] --> [Service (stable IP)] --> [Pod 1]
                                   --> [Pod 2]
                                   --> [Pod 3]

```

---

### ⚙️ Pre-requisite: Establish the Workload

Because a Service routes traffic to Pods, we need an active application running. Let's spin up yesterday's Deployment in our namespace.

```bash
# Create the namespace
kubectl create namespace dev

# Apply the Deployment from Day 52 (Nginx or Todo-App)
kubectl apply -f nginx-deployment.yaml

# Verify the Pods are running (Notice how they all have unique IPs)
kubectl get pods -n dev -o wide

```
<img width="1462" height="523" alt="Pre-requisite" src="https://github.com/user-attachments/assets/3b664111-83a7-40f2-a5a8-04e29be78972" />

---

### Task 1: Create a ClusterIP Service (Internal Access)

The `ClusterIP` is the default Kubernetes Service. It exposes the application on an internal IP address within the cluster, meaning it can only be accessed by other Pods *inside* the same cluster (ideal for backend databases).

**1. Create the `clusterip-service.yaml` manifest:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-clusterip
  namespace: dev
spec:
  type: ClusterIP
  selector:
    app: nginx      # This MUST match the labels in your Deployment
  ports:
  - protocol: TCP
    port: 80        # The port the Service listens on
    targetPort: 80  # The port the Container is listening on

```

**2. Apply and Verify:**

```bash
kubectl apply -f clusterip-service.yaml
kubectl get svc -n dev

```

<img width="2294" height="1520" alt="image" src="https://github.com/user-attachments/assets/da10655e-e4a0-4862-b880-22984a0cd4fd" />

---

### Task 2: Verify the ClusterIP Service
Because a ClusterIP is purely internal, we cannot access it from our laptop browser. We must launch a temporary "test" Pod inside the cluster to ping it.

**1. Launch a stable background test Pod:**
To avoid terminal race conditions, we start the pod in the background and tell it to stay awake for an hour:
```bash
kubectl run test-pod --image=busybox:latest --restart=Never -n dev -- sleep 3600

```

**2. Exec into the running Pod:**
Wait a few seconds for the pod's status to reach `Running`, then open an interactive shell inside it:

```bash
kubectl exec -it test-pod -n dev -- sh

```

**3. Test connectivity to the Service:**
Inside the busybox terminal, retrieve the Nginx homepage using the Service's short name:

```bash
wget -qO- http://app-clusterip

```
<img width="1468" height="1046" alt="image" src="https://github.com/user-attachments/assets/79df4e0f-6a00-49eb-ae86-343f72627d96" />


---
### Task 3: Discover Services with DNS

Kubernetes has a built-in DNS server (CoreDNS). Every Service gets a DNS entry automatically in this format:
`<service-name>.<namespace>.svc.cluster.local`

**Test the DNS resolution:**
Using the exact same `test-pod` shell we opened in Task 2, execute these DNS tests:

```bash
# 1. Short name (Works when communicating within the SAME namespace)
wget -qO- http://app-clusterip

# 2. Full DNS name (Required when reaching ACROSS different namespaces)
wget -qO- [http://app-clusterip.dev.svc.cluster.local](http://app-clusterip.dev.svc.cluster.local)

# 3. Look up the exact DNS entry to see the ClusterIP mapping
# Note: Using the full DNS name prevents noisy NXDOMAIN resolver logs
nslookup app-clusterip.dev.svc.cluster.local

```

<img width="1448" height="770" alt="image" src="https://github.com/user-attachments/assets/a7ce4775-3cc5-4d64-9d3e-246597b81cf2" />
<img width="1456" height="914" alt="image" src="https://github.com/user-attachments/assets/f438316f-27c5-4283-9263-d179c0e6034c" />

**SRE Context:**
Both the short name and the full DNS name resolve to the exact same ClusterIP. In production, your applications should use the **short name** when communicating with microservices inside their own namespace, and the **full name** when querying a service hosted in a different namespace (e.g., a frontend in `dev` reaching a database in `backend`).

**Clean Up the Test Pod:**
Once you are done with your tests, type `exit` to leave the container shell, and then delete the pod:

```bash
kubectl delete pod test-pod -n dev

```

---

### Task 4: Create a NodePort Service (External Access)
A `NodePort` Service exposes the application to the outside world by opening a static port (between 30000-32767) on every physical Worker Node's IP.

**1. Create the `nodeport-service.yaml` manifest:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-nodeport
  namespace: dev
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30007   # External port on the Host machine

```

**2. Apply and Verify:**

```bash
kubectl apply -f nodeport-service.yaml
kubectl get svc -n dev

```

*Note for local `kind` clusters: To test this in your browser securely, use port-forwarding: `kubectl port-forward svc/app-nodeport 8080:80 -n dev` and open `localhost:8080`.*

####  Port-Forwarding

<img width="2482" height="1458" alt="image" src="https://github.com/user-attachments/assets/674236dd-2511-474a-85a7-a8af9ac560d6" />

#### Host: localhost:8080
<img width="2876" height="586" alt="image" src="https://github.com/user-attachments/assets/9367dc27-ea66-405e-910f-b261c3cdd8c7" />


---
### Task 5: Create a LoadBalancer Service (Cloud Access)

This is the enterprise standard. When deployed on cloud platforms (AWS, GCP, Azure), this Service type commands the cloud provider to provision a physical Load Balancer (like an AWS NLB/ALB) and route external internet traffic directly into your cluster.

**1. Create the `loadbalancer-service.yaml` manifest:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-loadbalancer
  namespace: dev
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80

```

**2. Apply and Verify:**

```bash
kubectl apply -f loadbalancer-service.yaml
kubectl get svc app-loadbalancer -n dev

```
<img width="2390" height="1402" alt="image" src="https://github.com/user-attachments/assets/4564d0f1-cbb8-4d6d-8c9b-0028849f4d83" />


*Verification:* Look at the `EXTERNAL-IP` column. If you are running this locally on Docker/Minikube/Kind, it will permanently say `<pending>` because you don't have AWS attached. If you run this on AWS EKS, it will output a public DNS URL!

---

### Task 6: Explore Service Endpoints

How does the Service know the exact IPs of your dynamic Pods? It utilizes an `Endpoints` tracking list.

```bash
# View the live routing table for your Service
kubectl get endpoints app-clusterip -n dev

# Inspect the backend IPs matching the Deployment
kubectl describe svc app-clusterip -n dev

```

<img width="1462" height="826" alt="image" src="https://github.com/user-attachments/assets/a80e9b83-7072-4229-8b1a-0d484c0776c9" />

---

### Task 7: Clean Up

Maintain good cluster hygiene by tearing down the resources at the end of the day.

```bash
kubectl delete -f clusterip-service.yaml
kubectl delete -f nodeport-service.yaml
kubectl delete -f loadbalancer-service.yaml
kubectl delete deployment nginx-deployment -n dev
kubectl delete namespace dev

```
