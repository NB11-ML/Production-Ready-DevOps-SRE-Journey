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

<img width="2910" height="2036" alt="image" src="https://github.com/user-attachments/assets/1af3f3b7-fb4b-45b6-9264-f254379e803d" />

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

To secure the AI-BankApp with HTTPS, we install `cert-manager` to handle automated certificate issuance and renewals via Let's Encrypt.

### 1. Install cert-manager via Helm

```bash
helm repo add jetstack [https://charts.jetstack.io](https://charts.jetstack.io)
helm repo update

helm install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set crds.enabled=true \
  --wait

```

<img width="2236" height="1650" alt="image" src="https://github.com/user-attachments/assets/1a22601e-206f-470c-9be1-337a4ec26e08" />


Verify that all three cert-manager controller pods are running:

```bash
kubectl get pods -n cert-manager

```

<img width="1814" height="402" alt="image" src="https://github.com/user-attachments/assets/5c8b46a2-87f3-4edf-b686-a0c4f9c14801" />

---

### 2. SRE Gotcha: Configuring `nip.io` with AWS NLB DNS Names

#### The Issue

When running on local Kubernetes clusters (like Minikube or KinD), the load balancer address is an IPv4 address, allowing commands like `export HOSTNAME="${GATEWAY_IP}.nip.io"` to produce valid wildcard domains (e.g., `52.25.142.20.nip.io`).

On AWS EKS, Envoy Gateway provisions an AWS Network Load Balancer (NLB), which assigns a **DNS hostname** rather than a static IP:

```text
a0db2818a7fxxxxxxxxxxxxd6674e-xxxxxxxxxx.us-west-2.elb.amazonaws.com

```

Appending `.nip.io` directly to an existing AWS DNS hostname yields an invalid domain (`...elb.amazonaws.com.nip.io`) that Let's Encrypt cannot resolve.

#### The Fix: Extract the Underlying NLB Public IPv4

Resolve one of the active public IP addresses backing the AWS NLB before creating the `nip.io` hostname:

```bash
# 1. Resolve an active public IP behind the AWS NLB
export NLB_IP=$(dig +short $GATEWAY_IP | grep -E '^[0-9]' | head -n 1)

# 2. Construct the valid nip.io wildcard domain
export HOSTNAME="${NLB_IP}.nip.io"
echo "Correct HTTPS URL: https://$HOSTNAME"

```

<img width="2242" height="332" alt="image" src="https://github.com/user-attachments/assets/a3660f70-98a3-44a6-b4a3-4288190f761e" />

---

### 3. Apply the Let's Encrypt ClusterIssuer

Study and apply the `ClusterIssuer` configured for Gateway API HTTP-01 challenges (`k8s/cert-manager.yml`):

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: [https://acme-v02.api.letsencrypt.org/directory](https://acme-v02.api.letsencrypt.org/directory)
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
    - http01:
        gatewayHTTPRoute:
          parentRefs:
          - group: gateway.networking.k8s.io
            kind: Gateway
            name: bankapp-gateway
            namespace: bankapp

```

Apply the issuer:

```bash
kubectl apply -f k8s/cert-manager.yml

```

---

### 4. How the Gateway API ACME HTTP-01 Workflow Works

1. **Certificate Request:** cert-manager detects the `cert-manager.io/cluster-issuer: letsencrypt-prod` annotation on `bankapp-gateway` (or a dedicated `Certificate` resource) and initiates an ACME order with Let's Encrypt.
2. **Dynamic Route Creation:** cert-manager provisions a temporary `HTTPRoute` referencing `bankapp-gateway` specifically to solve the ACME HTTP-01 challenge path (`/.well-known/acme-challenge/*`).
3. **Challenge Validation:** Let's Encrypt verifies ownership by sending a GET request through the AWS NLB to the temporary route.
4. **Secret Storage:** Once verified, Let's Encrypt issues the certificate, which cert-manager writes to the `bankapp-tls` Kubernetes Secret.
5. **TLS Termination:** Envoy Gateway attaches the `bankapp-tls` secret to its HTTPS listener on port 443, terminating TLS traffic before routing requests to `bankapp-service`.

---

### 5. Update Gateway Hostname and Verify

Update the `https` listener hostname in `k8s/gateway.yml` with your resolved `$HOSTNAME`:

```yaml
listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: <your-resolved-ip>.nip.io
    tls:
      mode: Terminate
      certificateRefs:
      - group: ""
        kind: Secret
        name: bankapp-tls

```

Apply changes and verify certificate issuance:

```bash
kubectl apply -f k8s/gateway.yml

# Check certificate issuance status
kubectl get certificate -n bankapp
kubectl describe clusterissuer letsencrypt-prod

```

### Safety Check: Yes, It Is Safe

There are no AWS account IDs, private keys, passwords, or cloud credentials in this output.

* The UID (`8e92a1e8...`) is an internal Kubernetes cluster ID, not an AWS identifier.


* The email `mentor@trainwithshubham.com` is the public challenge contact email. You can keep it as-is or replace it with a placeholder like `admin@example.com` when publishing to a public repository.



---

### Verification: Active Certificate & ClusterIssuer

Check that cert-manager successfully registered with Let's Encrypt and issued the TLS certificate:

```bash
kubectl get certificate -n bankapp

```

**Output:**

```text
NAME          READY   SECRET        AGE
bankapp-tls   True    bankapp-tls   11m

```

```bash
kubectl describe clusterissuer letsencrypt-prod

```

**Output:**

```text
Name:         letsencrypt-prod
API Version:  cert-manager.io/v1
Kind:         ClusterIssuer
Metadata:
  Creation Timestamp:  2026-10-12T12:15:44Z
Spec:
  Acme:
    Email:  mentor@trainwithshubham.com
    Private Key Secret Ref:
      Name:  letsencrypt-account-key
    Server:  [https://acme-v02.api.letsencrypt.org/directory](https://acme-v02.api.letsencrypt.org/directory)
    Solvers:
      http01:
        Gateway HTTPRoute:
          Parent Refs:
            Group:      gateway.networking.k8s.io
            Kind:       Gateway
            Name:       bankapp-gateway
            Namespace:  bankapp
Status:
  Conditions:
    Message:               The ACME account was registered with the ACME server
    Reason:                ACMEAccountRegistered
    Status:                True
    Type:                  Ready

```

<img width="1818" height="1220" alt="image" src="https://github.com/user-attachments/assets/614cb580-77dd-459c-a574-051721fd18dd" />


---

### Troubleshooting 1: `gateway api is not enabled` in cert-manager

#### Symptom

During HTTP-01 challenge processing, `kubectl describe challenge -n bankapp` returns:

```text
Warning  PresentError  cert-manager-challenges  Error presenting challenge: couldn't Present challenge ...: gateway api is not enabled

```

#### Root Cause

By default, cert-manager disables Gateway API controller support to reduce overhead when only standard Ingress is used. When configuring `gatewayHTTPRoute` solvers under a `ClusterIssuer`, cert-manager will not reconcile solver routes until Gateway API support is explicitly enabled on the controller.

#### Resolution

Patch the cert-manager deployment to include the `--enable-gateway-api` flag:

```bash
kubectl -n cert-manager patch deployment cert-manager \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-gateway-api"}]'

# Wait for controller restart
kubectl rollout status deployment cert-manager -n cert-manager

```

---

### Troubleshooting 2: `No resources found in bankapp namespace` for Certificate

#### Symptom

After applying `k8s/gateway.yml` with the `cert-manager.io/cluster-issuer` annotation, running `kubectl get certificate -n bankapp` returns `No resources found`.

#### Root Cause

The `gateway-shim` in cert-manager watches `Gateway` resources dynamically. If cert-manager was started before the Gateway API CRDs were installed, or if the Gateway annotation is ignored, the certificate resource will not auto-generate.

#### Resolution

Declare the `Certificate` resource explicitly in GitOps rather than relying on dynamic annotations:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: bankapp-tls
  namespace: bankapp
spec:
  secretName: bankapp-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - "<your-resolved-nlb-ip>.nip.io"

```

Apply the manifest directly to trigger ACME order generation:

```bash
kubectl apply -f k8s/certificate.yml

```

### Deep Dive: How the TLS & cert-manager Flow Works under Gateway API

The TLS lifecycle consists of two distinct stages:
1. **Control Plane Workflow:** Automated certificate issuance and validation (ACME HTTP-01 Challenge).
2. **Data Plane Workflow:** Runtime HTTPS traffic encryption and TLS termination at Envoy Gateway.

---

#### 1. The Certificate Issuance Flow (ACME HTTP-01 Challenge)

Unlike traditional Ingress (which spins up an Ingress rule or temporary solver Pod), Gateway API integrates natively with `cert-manager` by dynamically creating a temporary `HTTPRoute`.

```text
+-------------------+             +-----------------------+             +------------------------+
|   Let's Encrypt   |             |     cert-manager      |             |   Envoy Gateway        |
|   (ACME Server)   |             |   (Cluster Control)   |             |   & Gateway API        |
+---------+---------+             +-----------+-----------+             +-----------+------------+
          |                                   |                                     |
          |  1. Request Cert (Order Created)  |                                     |
          |<----------------------------------+                                     |
          |                                   |                                     |
          |  2. Returns HTTP-01 Token Key     |                                     |
          +---------------------------------->|                                     |
          |                                   |  3. Injects temporary solver pod   |
          |                                   |     & dynamic HTTPRoute             |
          |                                   +------------------------------------>|
          |                                   |                                     |
          |  4. GET /.well-known/acme-challenge/<token>                             |
          +------------------------------------------------------------------------>| (Hits AWS NLB)
          |                                                                         |
          |                               5. Matches challenge path & forwards      |
          |                                  to cert-manager solver pod             |
          |                                   |<------------------------------------+
          |  6. Token matches! Challenge PASS |                                     |
          +<----------------------------------+                                     |
          |                                   |                                     |
          |  7. Issues X.509 Certificate      |                                     |
          +---------------------------------->|                                     |
          |                                   |  8. Saves cert to Secret:           |
          |                                   |     "bankapp-tls" (tls.crt/tls.key) |
          |                                   +------------------------------------>|

```

##### Detailed Issuance Mechanics:

1. **Trigger:** `cert-manager` detects the `cert-manager.io/cluster-issuer: letsencrypt-prod` annotation on `bankapp-gateway` (or a `Certificate` CRD).
2. **ACME Order:** It requests a certificate from the Let's Encrypt ACME API (`https://acme-v02.api.letsencrypt.org/directory`).
3. **Challenge Token:** Let's Encrypt responds: *"Prove you own this domain by serving token `XYZ` at `http://<domain>/.well-known/acme-challenge/XYZ`."*
4. **Gateway API Solver Route:** `cert-manager` automatically creates:
* A lightweight challenge pod running a temporary web server holding token `XYZ`.
* An **`HTTPRoute`** attached to `bankapp-gateway` under the `http` listener targeting `/.well-known/acme-challenge/*`.


5. **Validation:** Let's Encrypt makes a standard HTTP request to `http://<your-ip>.nip.io/.well-known/acme-challenge/XYZ`. Traffic flows through the AWS NLB, matches the solver `HTTPRoute`, and receives `XYZ`.
6. **Issuance & Cleanup:** Let's Encrypt signs and returns the public certificate. `cert-manager` tears down the temporary solver route and writes the certificate and private key into the Kubernetes Secret `bankapp-tls`.

---

#### 2. The Runtime HTTPS Data Plane Flow (TLS Termination)

Once the Secret `bankapp-tls` exists in the `bankapp` namespace, the Envoy Gateway HTTPS listener starts accepting encrypted traffic.

```text
[Browser / Client]
       |
       | 1. HTTPS Request (Port 443 / TLS ClientHello)
       v
  [AWS NLB] (Layer 4 TCP Passthrough)
       |
       | 2. Passes encrypted TCP packets directly to Envoy
       v
[Envoy Proxy Pod] (Layer 7 TLS Termination)
  |-- Mounts Secret: bankapp-tls (tls.crt + tls.key)
  |-- Completes TLS Handshake with Client
  |-- Decrypts payload from HTTPS to plain HTTP
  |-- Evaluates BackendTrafficPolicy (BANKAPP_AFFINITY cookie)
       |
       | 3. Unencrypted HTTP traffic (Port 8080) inside VPC
       v
[bankapp-service:8080]
       |
       +---> [bankapp-pod-1] (Pinned via affinity cookie)
       +---> [bankapp-pod-2]

```

##### Key Concepts in the Runtime Flow:

* **Layer 4 vs. Layer 7:** The AWS NLB operates at Layer 4 (TCP), passing the raw encrypted TLS stream directly to Envoy without decrypting it.
* **Edge TLS Termination:** Envoy Gateway terminates TLS at the edge of the Kubernetes cluster. It performs the cryptographic handshake using the keys mounted from `bankapp-tls`.
* **Internal VPC Routing:** Once decrypted, Envoy inspects HTTP headers, matches the route rules (`PathPrefix: /`), calculates the session affinity cookie hash, and sends plain HTTP to `bankapp-service` on port `8080`.
* **Resource Isolation:** Pods inside the cluster do not need to manage certificates, Java Keystores (`JKS`), or TLS CPU overhead—Envoy offloads all encryption and certificate renewals.

---

### Verification Commands for TLS Status

Add these checks to verify each stage of the TLS process:

```bash
# 1. Check if the Certificate object was created and is valid
kubectl get certificate -n bankapp

# 2. Check the order and challenge status
kubectl get certificaterequest -n bankapp
kubectl get challenges -n bankapp

# 3. Check if the TLS Secret was generated
kubectl get secret bankapp-tls -n bankapp

# 4. Test TLS handshake and certificate issuer via cURL
curl -Iv https://$HOSTNAME

```

<img width="2706" height="1450" alt="image" src="https://github.com/user-attachments/assets/f8006370-ef23-4b2e-bd74-4d122bfd4383" />

---


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
<img width="3152" height="676" alt="image" src="https://github.com/user-attachments/assets/bfa02900-dd80-4279-9d73-cec85414b2c0" />

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
<img width="2834" height="1154" alt="image" src="https://github.com/user-attachments/assets/17397f9c-b2c4-4700-be45-6888df6efd39" />


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

