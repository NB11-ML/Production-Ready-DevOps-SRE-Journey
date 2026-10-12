# Day 82: EKS Networking with Gateway API and Persistent Storage

## Prerequisites: Reconnecting to an Ephemeral Cluster
If you run `terraform destroy` to save costs overnight and `terraform apply` to spin the cluster back up the next day, your local `kubectl` configuration will point to a dead server.

Run this command to update your local kubeconfig with the new cluster's connection details:

```bash
aws eks update-kubeconfig --region us-west-2 --name bankapp-eks

# Verify connection
kubectl get nodes

```

---

### The Technical Explanation Behind the Error

When you run `terraform apply` for a second time, it doesn't "wake up" your old cluster; it creates a brand new one from scratch.

* **The Control Plane Lifecycle:** EKS provisions a highly available control plane across multiple AWS Availability Zones. AWS fronts this control plane with a network load balancer, generating a completely unique, randomized API server URL for that specific cluster instance (e.g., `[https://9D757...eks.amazonaws.com](https://9D757...eks.amazonaws.com)`).
* **The Stale DNS Mapping:** `kubectl` has no native awareness of your cloud provider. It blindly trusts the connection string cached in your local `~/.kube/config` file. Because yesterday's cluster was destroyed, its AWS endpoint was deleted. When `kubectl` tried to resolve that old URL today, your computer's DNS resolver returned the `no such host` error.
* **How the Fix Works:** Running `aws eks update-kubeconfig` acts as the bridge. It calls the AWS API, asks for the current endpoint URL and certificate authority data for the cluster named `bankapp-eks`, and safely overwrites the stale block in your `~/.kube/config` file.

```

## Introduction
While the AI-BankApp was successfully deployed using raw manifests, a production-grade deployment requires robust ingress, HTTPS, session persistence, and reliable storage. Today, we transition from the traditional Ingress controller to the **Kubernetes Gateway API** using **Envoy Gateway**, configure TLS with **cert-manager**, and explore dynamic **EBS persistent storage** on Amazon EKS.

## Task 1: Gateway API vs. Ingress

The AI-BankApp leverages the Gateway API, representing the next generation of Kubernetes traffic management. 

### Comparison: Ingress vs. Gateway API

| Feature | Ingress | Gateway API |
| :--- | :--- | :--- |
| **API Maturity** | Stable but limited | GA since Kubernetes 1.26 |
| **Traffic Splitting** | Not natively supported | Built-in (weighted backends) |
| **Header Matching** | Annotation-dependent | Native HTTPRoute rules |
| **Role Separation** | Single monolithic resource | `GatewayClass` (Infra) -> `Gateway` (Ops) -> `HTTPRoute` (Dev) |
| **TLS Management** | Annotation-based | Native TLS config in Gateway listeners |
| **Session Affinity** | Not standardized | `BackendTrafficPolicy` (with Envoy) |

### Gateway API Architecture Flow

```text
[Internet]
    |
[AWS NLB] (Provisioned by Envoy Gateway)
    |
[Gateway: bankapp-gateway]
  |-- Listener: HTTP (port 80)
  |-- Listener: HTTPS (port 443, TLS terminated)
    |
[HTTPRoute: bankapp-route]
    |
[Service: bankapp-service:8080]
    |
[Pods: bankapp x2-4] (Session affinity via cookie)

```

## Task 2: Installing Envoy Gateway

Envoy Gateway serves as the implementation controller for our Gateway API resources.

```bash
# Install Envoy Gateway via Helm
helm install envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
  --version v1.4.0 \
  -n envoy-gateway-system --create-namespace \
  --wait

# Verify installation
kubectl get pods -n envoy-gateway-system
kubectl get gatewayclass

```

<img width="2238" height="994" alt="image" src="https://github.com/user-attachments/assets/b5e686dc-453c-4282-b958-645e67669fb0" />


*If Gateway API CRDs are missing, they can be installed via:*

```bash
kubectl apply -f [https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml](https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml)

```

<img width="2106" height="982" alt="image" src="https://github.com/user-attachments/assets/63b002bc-15b6-4966-bcb6-56d935588ebb" />


### Troubleshooting & Core Concept: CRD Order and `GatewayClass` Resolution

#### The Core Problem: Missing Standard Gateway API CRDs
Unlike traditional `Ingress`, Kubernetes Gateway API resources (`GatewayClass`, `Gateway`, `HTTPRoute`) are not built into standard EKS binaries. They are managed as external Custom Resource Definitions (CRDs).

If the Envoy Gateway Helm chart is deployed before the Kubernetes SIG Gateway API CRDs exist in the cluster:
1. The `envoy-gateway` controller starts successfully, but the Kubernetes API schema for `GatewayClass` does not exist.
2. The controller fails to register its default class on boot, causing `kubectl get gatewayclass` to return `No resources found`.

#### Resolution & Verification Workflow

1. **Install the Standard Gateway API CRDs:**

```bash
kubectl apply -f [https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml](https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml)
```

2. **Verify CRD Registration:**

```bash
kubectl get crd | grep gateway.networking.k8s.io

```

*Expected CRDs:*
* `gatewayclasses.gateway.networking.k8s.io`
* `gateways.gateway.networking.k8s.io`
* `httproutes.gateway.networking.k8s.io`
* `referencegrants.gateway.networking.k8s.io`


3. **Declare or Reconcile the `GatewayClass`:**

Restart the Envoy Gateway controller to re-trigger reconciliation, or declare the `GatewayClass` explicitly:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy-gateway
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller

```


Apply the manifest:

```bash
kubectl apply -f k8s/gatewayclass.yml

```


4. **Verify GatewayClass Status:**
```bash
kubectl get gatewayclass

```


*Output:*
```text
NAME            CONTROLLER                                      ACCEPTED   AGE
envoy-gateway   gateway.envoyproxy.io/gatewayclass-controller   True       30s

```



> **Key SRE Takeaway:** A `GatewayClass` functions identically to a `StorageClass` in Kubernetes. It defines the cluster-level infrastructure controller responsible for managing the lifecycle of actual gateways (such as provisioning an AWS NLB when a `Gateway` resource is instantiated).


---

## Task 3: Deploying AI-BankApp with Gateway API

### 1. Core Resource Deployment

Ensure the application backend and services are running:

```bash
cd AI-BankApp-DevOps
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/pv.yml
kubectl apply -f k8s/pvc.yml
kubectl apply -f k8s/configmap.yml
kubectl apply -f k8s/secrets.yml
kubectl apply -f k8s/mysql-deployment.yml
kubectl apply -f k8s/service.yml
kubectl apply -f k8s/ollama-deployment.yml
kubectl apply -f k8s/bankapp-deployment.yml
kubectl apply -f k8s/hpa.yml

```

### 2. Gateway Resources Explained

* **GatewayClass (`envoy-gateway`):** Defines the controller (`gateway.envoyproxy.io/gatewayclass-controller`) responsible for processing Gateway resources.
* **Gateway (`bankapp-gateway`):** Triggers Envoy to automatically provision an AWS Network Load Balancer (NLB). It defines the physical listeners (Port 80 HTTP, Port 443 HTTPS).
* **HTTPRoute (`bankapp-route`):** Attaches to the Gateway listeners and provides layer 7 routing rules (e.g., routing `PathPrefix /` to `bankapp-service` on port `8080`).
* **BackendTrafficPolicy (`bankapp-session`):** Configures session persistence.
* *Why cookie-based affinity?* The AI-BankApp uses Spring Security form-based login. Without session affinity, sequential user requests might land on different pods, breaking the session and logging the user out. The `BANKAPP_AFFINITY` cookie ensures a specific client always maps to the same pod.



### 3. Applying and Verifying the Gateway

```bash
kubectl apply -f k8s/gateway.yml

# Wait for the AWS NLB to be provisioned
kubectl get gateway -n bankapp -w

```

> **Screenshot:** `kubectl get gateway` showing the AWS NLB external address.
<img width="2344" height="204" alt="image" src="https://github.com/user-attachments/assets/ce0c7769-b79b-4af3-a7ec-762827f8a109" />

```bash
# Test Access
export GATEWAY_IP=$(kubectl get gateway bankapp-gateway -n bankapp -o jsonpath='{.status.addresses[0].value}')
echo "App URL: http://$GATEWAY_IP"
curl http://$GATEWAY_IP

```
<img width="2152" height="626" alt="image" src="https://github.com/user-attachments/assets/8469d1d9-e5db-4725-b15c-d915cbd11584" />

--- 

### Troubleshooting: Resolving HTTP 404 on Raw NLB Endpoints

#### Symptom
Querying the raw AWS NLB endpoint (`curl -I http://$GATEWAY_IP`) returned an `HTTP/1.1 404 Not Found` directly from Envoy, despite the Gateway reporting `Programmed: True`.

#### Root Cause
The default `HTTPRoute` manifest contained a strict host header restriction:
```yaml
spec:
  hostnames:
  - 52.25.142.20.nip.io

```

When sending requests to the AWS NLB DNS name (`a0db2818...elb.amazonaws.com`), Envoy compared the incoming `Host:` request header against the allowed `hostnames` list. Because the NLB hostname did not match the hardcoded `nip.io` domain, Envoy rejected the request with `404 Not Found`.

#### Fix

Comment out or remove the `hostnames:` specification under `HTTPRoute.spec` to allow wildcard hostname matching across the HTTP listener:

```yaml
spec:
  # hostnames:
  # - 52.25.142.20.nip.io
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: bankapp-gateway
    sectionName: http

```

#### Verification & Proof of Session Affinity

Reapplying the route immediately resolved the routing path:

```bash
curl -I http://$GATEWAY_IP

```

**Output:**

```text
HTTP/1.1 302 Found
location: [http://a0db2818a7f124feebf93c705dd6674e-979423440.us-west-2.elb.amazonaws.com/login](http://a0db2818a7f124feebf93c705dd6674e-979423440.us-west-2.elb.amazonaws.com/login)
set-cookie: BANKAPP_AFFINITY="80387b034f325236"; Max-Age=3600; HttpOnly

```

* **Routing Verified:** The Spring Boot backend responded with `302 Found`, redirecting to `/login`.
* **Session Persistence Verified:** Envoy Gateway successfully injected the `BANKAPP_AFFINITY` cookie with a 1-hour TTL (`Max-Age=3600`), confirming the `BackendTrafficPolicy` configuration works.


---


## Task 4: Automating TLS with cert-manager

To secure the Gateway with HTTPS, we integrate `cert-manager` with Let's Encrypt.

### 1. Installation

```bash
helm repo add jetstack [https://charts.jetstack.io](https://charts.jetstack.io)
helm repo update

helm install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set crds.enabled=true \
  --wait

```

### 2. How the TLS Flow Works

1. `cert-manager` reads the `ClusterIssuer` and requests a cert from Let's Encrypt.
2. Let's Encrypt issues an HTTP-01 challenge.
3. `cert-manager` creates a temporary `HTTPRoute` to solve the challenge.
4. Upon verification, the certificate is stored in a Kubernetes Secret (`bankapp-tls`).
5. The Envoy Gateway terminates HTTPS using this newly generated Secret.

*(Testing Note: To utilize Let's Encrypt effectively without a custom domain, `nip.io` provides wildcard DNS mapping directly to the NLB IP).*

```bash
export HOSTNAME="${GATEWAY_IP}.nip.io"
echo "HTTPS URL: https://$HOSTNAME"

```

## Task 5: EBS Persistent Storage in Action

The AI-BankApp requires stateful storage for MySQL (5Gi) and Ollama (10Gi).

### Storage Flow Diagram

`StorageClass (gp3)` -> `PersistentVolumeClaim (PVC)` -> `PersistentVolume (PV)` -> `AWS EBS Volume` -> `Pod`

### Verifying Storage

```bash
kubectl get storageclass gp3
kubectl get pvc -n bankapp
kubectl get pv

```

> **Screenshot:** `kubectl get pvc -n bankapp` showing MySQL and Ollama PVCs in `Bound` status.
> *(Insert Screenshot Here)*

### Key EBS Concepts on EKS

* **WaitForFirstConsumer:** Volume creation is delayed until the pod is scheduled, guaranteeing the EBS volume is created in the exact same Availability Zone (AZ) as the pod.
* **ReadWriteOnce (RWO):** EBS volumes can only attach to one EC2 node at a time. (This is why MySQL and Ollama use the `Recreate` deployment strategy).
* **gp3:** The default storage class provides a cost-effective, high-performance SSD with a baseline of 3000 IOPS.
* **allowVolumeExpansion:** Enables dynamic resizing of volumes without recreation.

### Testing Persistence

```bash
# Insert/Check data, then delete the pod to test state recovery
kubectl exec -n bankapp deploy/mysql -- mysql -uroot -pTest@123 -e "SHOW DATABASES;"
kubectl delete pod -n bankapp -l app=mysql

# Watch it recreate and verify data survived
kubectl get pods -n bankapp -l app=mysql -w
kubectl exec -n bankapp deploy/mysql -- mysql -uroot -pTest@123 -e "SHOW DATABASES;"

```

## Task 6: HPA & Resource Budgeting

Understanding cluster capacity is crucial for SREs. We monitor scaling and node utilization using the Metrics Server:

```bash
kubectl get hpa -n bankapp
kubectl top nodes
kubectl top pods -n bankapp

```

### EKS Resource Budget (AI-BankApp on 3x Nodes)

| Component | CPU Request | Memory Request | Instances |
| --- | --- | --- | --- |
| **BankApp** | 250m | 256Mi | 2-4 pods |
| **MySQL** | 250m | 256Mi | 1 pod |
| **Ollama** | 900m | 2Gi | 1 pod |
| **Init Containers** | 50m | 32Mi | temporary |
| **System Pods** | ~500m | ~500Mi | per node |
| **Total Available** | 6000m (3 nodes) | 12Gi (3 nodes) | - |

*Note: Ollama is the heaviest consumer. If the HPA scales the frontend to 4 pods, CPU requests approach ~2.9 cores plus node system overhead.*

## Cleanup Workloads

Preserve the EKS cluster for Day 83, but scale down application workloads to save resources:

```bash
kubectl delete -f k8s/gateway.yml 2>/dev/null
kubectl delete -f k8s/hpa.yml
kubectl delete -f k8s/bankapp-deployment.yml
kubectl delete -f k8s/ollama-deployment.yml
kubectl delete -f k8s/mysql-deployment.yml
kubectl delete -f k8s/service.yml
kubectl delete -f k8s/secrets.yml
kubectl delete -f k8s/configmap.yml
kubectl delete -f k8s/pvc.yml
kubectl delete -f k8s/pv.yml
kubectl delete -f k8s/namespace.yml

```

---
---
```
