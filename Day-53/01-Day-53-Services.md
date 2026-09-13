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

---

### Task 2: Verify the ClusterIP Service

Because a ClusterIP is internal, we cannot access it from our laptop browser. We must launch a temporary "test" Pod inside the cluster to ping it.

**1. Launch a temporary interactive Pod:**

```bash
kubectl run test-pod --image=busybox:1.28 --restart=Never -n dev -it --rm -- sh

```

**2. Test connectivity using the Service DNS:**
Inside the busybox terminal, hit the Service using its DNS name (`<service-name>.<namespace>.svc.cluster.local`):

```bash
wget -qO- app-clusterip.dev.svc.cluster.local:80

```

*Verification:* You should see the raw HTML output of your application. Type `exit` to destroy the test pod.

---

### Task 3: Discover Services with DNS

Kubernetes has a built-in DNS server (CoreDNS). Every Service gets a DNS entry automatically in this format:
`<service-name>.<namespace>.svc.cluster.local`

**Test the DNS resolution:**
Launch a temporary interactive Pod to test the network from inside the cluster:
```bash
kubectl run dns-test --image=busybox:latest --rm -it --restart=Never -n dev -- sh

```

**Inside the Pod shell, execute these tests:**

```bash
# 1. Short name (Works when communicating within the SAME namespace)
wget -qO- http://app-clusterip

# 2. Full DNS name (Required when reaching ACROSS different namespaces)
wget -qO- [http://app-clusterip.dev.svc.cluster.local](http://app-clusterip.dev.svc.cluster.local)

# 3. Look up the exact DNS entry to see the ClusterIP mapping
nslookup app-clusterip

# Exit to destroy the test pod automatically
exit

```

**SRE Context:**
Both the short name and the full DNS name resolve to the exact same ClusterIP. In production, your applications should use the **short name** when communicating with microservices inside their own namespace, and the **full name** when querying a service hosted in a different namespace (e.g., a frontend in `dev` reaching a database in `backend`).


---

### Task 4: Create a LoadBalancer Service (Cloud Access)

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

*Verification:* Look at the `EXTERNAL-IP` column. If you are running this locally on Docker/Minikube/Kind, it will permanently say `<pending>` because you don't have AWS attached. If you run this on AWS EKS, it will output a public DNS URL!

---

### Task 5: Explore Service Endpoints

How does the Service know the exact IPs of your dynamic Pods? It utilizes an `Endpoints` tracking list.

```bash
# View the live routing table for your Service
kubectl get endpoints app-clusterip -n dev

# Inspect the backend IPs matching the Deployment
kubectl describe svc app-clusterip -n dev

```

---

### Task 6: Clean Up

Maintain good cluster hygiene by tearing down the resources at the end of the day.

```bash
kubectl delete -f clusterip-service.yaml
kubectl delete -f nodeport-service.yaml
kubectl delete -f loadbalancer-service.yaml
kubectl delete deployment nginx-deployment -n dev
kubectl delete namespace dev

```
