# ☸️ Day 83: Production Deployment of AI-BankApp on Amazon EKS

## Executive Overview
Day 83 consolidates three intensive days of Amazon EKS engineering into a complete, production-grade deployment of the **AI-BankApp**. The architecture integrates a full-stack Spring Boot banking application with persistent MySQL storage, a self-hosted Ollama local LLM service (TinyLlama), next-generation traffic routing via Kubernetes Gateway API (Envoy Gateway), horizontal pod autoscaling (HPA), and full-stack observability with the Prometheus and Grafana stack.

---

## 1. End-to-End Architecture

```text
                                  INTERNET
                                     │
                                     ▼
                   [ AWS Network Load Balancer (NLB) ]
                                     │
                     (Port 80 / 443 Traffic Ingress)
                                     │
      ┌──────────────────────────────┼──────────────────────────────┐
      │ AWS VPC (3 Availability Zones: us-west-2a, 2b, 2c)          │
      │                              ▼                              │
      │               [ Envoy Gateway Controller Pods ]             │
      │                    (Gateway API Ingress)                    │
      │                              │                              │
      │     HTTPRoute (Path: /)      │     HTTPRoute (Cookie Sticky)│
      │     ┌────────────────────────┘                              │
      │     ▼                                                       │
      │ [ bankapp-service (ClusterIP: 8080) ]                       │
      │     │                                                       │
      │     ├──► [ bankapp-deployment Pod 1 ] (Spring Boot / Non-Root)
      │     └──► [ bankapp-deployment Pod 2 ] (Managed by HPA: 2-4)  │
      │              │                             │                │
      │              ▼                             ▼                │
      │    [ mysql-service: 3306 ]       [ ollama-service: 11434 ]  │
      │              │                             │                │
      │              ▼                             ▼                │
      │     [ mysql Stateful Pod ]        [ ollama LLM Pod ]        │
      │              │                             │                │
      │              ▼                             ▼                │
      │     [ 5Gi EBS gp3 Volume ]        [ 10Gi EBS gp3 Volume ]   │
      │     (Dynamic CSI Binding)         (TinyLlama Model Storage) │
      │                                                             │
      │ ─────────────────────────────────────────────────────────── │
      │ Observability Plane (Namespace: monitoring)                 │
      │                                                             │
      │  [ ServiceMonitor: bankapp-monitor ]                        │
      │              │ (Scrapes /actuator/prometheus every 15s)     │
      │              ▼                                              │
      │   [ Prometheus Server ] ◄───► [ Grafana Dashboards (:3000) ]│
      └─────────────────────────────────────────────────────────────┘

```

---

## Task 1: Deploy the Complete AI-BankApp Stack

### 1.1 Infrastructure Verification

Verify cluster connectivity and confirm that worker nodes across all availability zones are healthy:

```bash
aws eks update-kubeconfig --name bankapp-eks --region us-west-2
kubectl get nodes -o wide

```

### 1.2 Step-by-Step Manifest Application

Deploy the stack in strict dependency order from the repository root:

```bash
cd ~/AI-BankApp-DevOps

# 1. Core Namespace and Persistent Storage Claims
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/pv.yml
kubectl apply -f k8s/pvc.yml

# 2. Configuration & Application Secrets
kubectl apply -f k8s/configmap.yml
kubectl apply -f k8s/secrets.yml

# 3. Database Layer, Internal ClusterIP Services, and Ollama LLM Service
kubectl apply -f k8s/mysql-deployment.yml
kubectl apply -f k8s/service.yml
kubectl apply -f k8s/ollama-deployment.yml

# 4. Await Stateful Backend Readiness
echo "Waiting for MySQL to become ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n bankapp --timeout=180s

echo "Waiting for Ollama to pull TinyLlama model (takes 2-5 minutes)..."
kubectl wait --for=condition=ready pod -l app=ollama -n bankapp --timeout=600s

# 5. Application Layer & Autoscaler
kubectl apply -f k8s/bankapp-deployment.yml
kubectl apply -f k8s/hpa.yml

# 6. Await BankApp Pod Readiness
echo "Waiting for BankApp application pods..."
kubectl wait --for=condition=ready pod -l app=bankapp -n bankapp --timeout=300s

```

### 1.3 Workload & Volume Verification

Check all running resources and persistent volume claims:

```bash
kubectl get all -n bankapp
kubectl get pvc -n bankapp

```

<img width="2990" height="1316" alt="image" src="https://github.com/user-attachments/assets/39c86ffe-58bf-423d-bb71-ca7b886db56b" />


**Expected Status:**

* `mysql`: 1 pod in `Running` state, with `mysql-pvc` (5Gi) `Bound`.
* `ollama`: 1 pod in `Running` state, with `ollama-pvc` (10Gi) `Bound`.
* `bankapp`: 2 pods in `Running` state (governed by `bankapp-hpa`).
* `services`: `bankapp-service`, `mysql-service`, and `ollama-service` active on `ClusterIP`.

---

## Task 2: Gateway API Traffic Routing & Application Access

### 2.1 Envoy Gateway Provisioning & Routing Configuration

Ensure the Envoy Gateway controller is running and apply the gateway configuration:

```bash
helm install envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
  --version v1.4.0 \
  -n envoy-gateway-system --create-namespace \
  --wait 2>/dev/null || echo "Envoy Gateway is already active"

kubectl apply -f k8s/gateway.yml

```

### 2.2 Retrieve the External NLB Endpoint

Wait for the AWS Network Load Balancer (NLB) to be provisioned and retrieve its address:

```bash
# Watch until the external NLB address appears under ADDRESS
kubectl get gateway -n bankapp -w

```

Export the Gateway URL to an environment variable:

```bash
export APP_URL=$(kubectl get gateway bankapp-gateway -n bankapp -o jsonpath='{.status.addresses[0].value}')
echo "AI-BankApp Endpoint: http://$APP_URL"

```

### 2.3 Smoke Testing the Endpoints

```bash
# Check Spring Boot Actuator Health Status
curl -s http://$APP_URL/actuator/health | python3 -m json.tool

# Verify HTTP 200 on Web Root
curl -s -o /dev/null -w "HTTP Status Code: %{http_code}\n" http://$APP_URL

```

<img width="2676" height="1226" alt="image" src="https://github.com/user-attachments/assets/d351bb65-1e13-46a0-8dc1-4fe2b31f62d4" />



### 2.4 End-to-End User Journey Validation

Open `http://$APP_URL` in your browser and complete the following verification steps:

1. **User Registration:** Register a new user (`testuser` / `Password@123`).
2. **Authentication:** Log in to verify session creation and session sticky cookie routing.
3. **Core Banking Transactions:** Execute a **Deposit ($500)**, **Withdrawal ($100)**, and check the updated ledger.
4. **AI Financial Assistant:** Open the AI Chatbot and ask: *"How should I budget my monthly income?"*. Confirm that the TinyLlama model generates a response.
5. **UI Customization:** Toggle dark and light mode to ensure assets load properly without errors.

<img width="3324" height="1880" alt="image" src="https://github.com/user-attachments/assets/615661d8-3426-47c6-935d-c9349637b88b" />


### 2.5 Real-World Troubleshooting: Resolving 504 Gateway Timeout on AI Inference

* **Symptom:** Short prompts like *"hi"* completed successfully (~9–11s), but complex financial queries resulted in UI errors: *"Sorry, something went wrong."*
  
* **Root Cause Analysis:** Inspecting the browser Network tab revealed HTTP `504 Gateway Timeout` errors at exactly ~15.3 seconds. By default, Envoy Gateway enforces a 15-second client request timeout. Because Ollama executes TinyLlama inference on EC2 CPU (`t3.medium`) without hardware GPU acceleration, multi-sentence token generation requires 20–30 seconds. Envoy severed the connection prematurely at second 15.
  
* **Resolution:** Extended the Gateway API HTTP request timeout from 15s to 120s directly in `k8s/gateway.yml` under `HTTPRoute.spec.rules.timeouts`:

```yaml
spec:
  parentRefs:
    - name: bankapp-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: bankapp-service
          port: 8080
      timeouts:
        request: 120s

```

* **Verification:** Re-applied the manifest (`kubectl apply -f k8s/gateway.yml`). Re-tested with full financial prompts; the connection remained open until generation completed, returning HTTP `200 OK`.


---

## Task 3: Deploy the Monitoring Stack (Prometheus & Grafana)

### 3.1 Deploy `kube-prometheus-stack` via Helm

Deploy the Prometheus operator, Prometheus server, Alertmanager, Node Exporter, and Grafana:

```bash
helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.retention=3d \
  --set prometheus.prometheusSpec.resources.requests.memory=256Mi \
  --set prometheus.prometheusSpec.resources.requests.cpu=100m \
  --wait --timeout 600s

```

Verify that all monitoring components are running:

```bash
kubectl get pods -n monitoring

```

<img width="1818" height="490" alt="image" src="https://github.com/user-attachments/assets/0ef91376-cf52-40b9-93c9-c58ae21f0f56" />


### 3.2 Configure Application Metrics Scraping via ServiceMonitor

AI-BankApp natively exposes metrics via Spring Boot Actuator (`/actuator/prometheus`). Create and apply the `ServiceMonitor`:

```bash
cat <<'EOF' > bankapp-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: bankapp-monitor
  namespace: monitoring
  labels:
    release: monitoring
spec:
  namespaceSelector:
    matchNames:
      - bankapp
  selector:
    matchLabels:
      app: bankapp
  endpoints:
    - port: "8080"
      path: /actuator/prometheus
      interval: 15s
EOF

kubectl apply -f bankapp-servicemonitor.yaml

```
<img width="1824" height="822" alt="image" src="https://github.com/user-attachments/assets/9771309b-9e8a-418f-8d74-42c46e00d182" />


### 3.3 Access Grafana & Prometheus Port-Forwards

In separate terminal tabs, open secure port-forward tunnels:

```bash
# Terminal Tab A: Grafana UI (Port 3000)
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

# Terminal Tab B: Prometheus Expression Browser (Port 9090)
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090

```

<img width="3408" height="406" alt="image" src="https://github.com/user-attachments/assets/27f9ec3f-2bbd-4622-8121-8b9fb7de9714" />


* **Grafana Login:** Navigate to `http://localhost:3000` (User: `admin`, Password: `admin123`).
* **Prometheus Targets:** Navigate to `http://localhost:9090/targets` to verify `serviceMonitor/monitoring/bankapp-monitor/0` reports in `UP` state.

<img width="3420" height="2030" alt="image" src="https://github.com/user-attachments/assets/23d75639-84fe-45e1-91c5-43ef90913222" />


### 3.4 Key PromQL Queries for AI-BankApp

Execute these metrics queries in Prometheus or Grafana Explore:

* **JVM Memory Usage:**
```promql
jvm_memory_used_bytes{namespace="bankapp"}

```


* **HTTP Request Rate (Per 5 Minutes):**
```promql
rate(http_server_requests_seconds_count{namespace="bankapp"}[5m])

```


* **HTTP Request Latency (95th Percentile):**
```promql
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{namespace="bankapp"}[5m]))

```

<img width="2542" height="1878" alt="image" src="https://github.com/user-attachments/assets/dd0143c5-511a-4b57-a9c1-9e62d830deed" />


### 3.5 Real-World Troubleshooting: Resolving Prometheus ServiceMonitor `0/0 up` Target Mismatch

* **Symptom:** After applying `bankapp-servicemonitor.yaml`, navigating to Prometheus (`http://localhost:9090/targets`) showed `serviceMonitor/monitoring/bankapp-monitor/0` with status `0 / 0 up` (no active scrape targets discovered)[cite: 6]. PromQL queries like `jvm_memory_used_bytes` returned empty results.
* **Root Cause Analysis:** Prometheus Operator uses CRD-driven discovery that requires two conditions to discover and scrape application endpoints:
  1. **Service Metadata Labels:** The `ServiceMonitor.spec.selector.matchLabels` queries the Kubernetes `Service` resource's `metadata.labels`, not the underlying `Pod` labels. `bankapp-service` was missing `metadata.labels: { app: bankapp }`.
  2. **Named Endpoints:** In Prometheus Operator CRDs, `endpoints[].port` requires the **string name** (`name`) of the target port defined on the Kubernetes Service, not the raw integer port `8080`. The original service manifest had no `name` property under `spec.ports`.
* **Resolution:**
  1. Updated `k8s/service.yml` to explicitly name the port `http` and label the service:
     ```yaml
     apiVersion: v1
     kind: Service
     metadata:
       name: bankapp-service
       namespace: bankapp
       labels:
         app: bankapp
     spec:
       type: ClusterIP
       sessionAffinity: ClientIP
       sessionAffinityConfig:
         clientIP:
           timeoutSeconds: 3600
       selector:
         app: bankapp
       ports:
         - name: http
           port: 8080
           targetPort: 8080
     ```
     
  2. Updated `bankapp-servicemonitor.yaml` to target the named port `http`:
     
     ```yaml
     apiVersion: [monitoring.coreos.com/v1](https://monitoring.coreos.com/v1)
     kind: ServiceMonitor
     metadata:
       name: bankapp-monitor
       namespace: monitoring
       labels:
         release: monitoring
     spec:
       namespaceSelector:
         matchNames:
           - bankapp
       selector:
         matchLabels:
           app: bankapp
       endpoints:
         - port: http
           path: /actuator/prometheus
           interval: 15s
     ```
* **Verification:** Re-applied both manifests. Scrape pool immediately discovered both replicas, updating status to `2 / 2 up`, and Actuator JVM/HTTP metrics began populating in Grafana and Prometheus.

  
Explore pre-built Grafana dashboards:

* **Kubernetes / Compute Resources / Namespace (Pods):** Select namespace `bankapp`.
* **Kubernetes / Compute Resources / Pod:** Drill into the individual `bankapp` and `mysql` pods.
* **Node Exporter / Nodes:** Observe CPU, memory, and disk I/O metrics of the EKS worker nodes.

---

### 3.6 Architecture Note: Managed Control Plane Scrape Targets on Amazon EKS

* **Observation:** In the Prometheus Targets dashboard, `kube-controller-manager`, `kube-etcd`, and `kube-scheduler` display `0 / 0 up`[cite: 7].
* **Explanation:** Unlike bare-metal or self-managed Kubernetes (such as `kubeadm`), Amazon EKS abstracts the Kubernetes control plane into a dedicated, isolated AWS-managed VPC. Customers do not manage or have direct network ingress to the underlying `etcd` nodes, scheduler, or controller manager instances.
* **Production Best Practice:** On Amazon EKS, control plane health is monitored via AWS CloudWatch Control Plane logs and native EKS console metrics. In production Helm values for `kube-prometheus-stack`, these scrapers are explicitly disabled (`kubeControllerManager.enabled: false`, `kubeEtcd.enabled: false`, `kubeScheduler.enabled: false`) to eliminate dead target pools.


---


## Task 4: End-to-End Validation Checklist

Run the validation script to audit all operational layers:

```bash
# Ensure APP_URL is populated dynamically
export APP_URL=$(kubectl get gateway bankapp-gateway -n bankapp -o jsonpath='{.status.addresses[0].value}')

echo "=== 1. APPLICATION LAYER VALIDATION ==="
kubectl get pods -n bankapp
echo "--- App Health Endpoint ---"
curl -s http://$APP_URL/actuator/health
echo -e "\n--- HPA Status ---"
kubectl get hpa -n bankapp
echo "--- Prometheus Actuator Metrics Sample ---"
curl -s http://$APP_URL/actuator/prometheus | head -10

echo -e "\n=== 2. DATA LAYER VALIDATION ==="
echo "--- MySQL Ping Test ---"
kubectl exec -n bankapp deploy/mysql -- mysqladmin ping -h localhost -uroot -pTest@123
echo "--- Persistent Volume Claims ---"
kubectl get pvc -n bankapp
echo "--- Ollama Model List ---"
kubectl exec -n bankapp deploy/ollama -- ollama list

echo -e "\n=== 3. INFRASTRUCTURE LAYER VALIDATION ==="
kubectl get nodes
kubectl top nodes
echo "--- Gateway Status ---"
kubectl get gateway -n bankapp
echo "--- Monitoring Pods ---"
kubectl get pods -n monitoring | head -5

echo -e "\n=== 4. SECURITY & HYGIENE VALIDATION ==="
echo -e "Checking container user (Non-Root compliance):"
kubectl exec -n bankapp deploy/bankapp -- whoami
echo "Checking secret isolation in environment definition:"
kubectl get secret bankapp-secret -n bankapp -o yaml | grep -c "MYSQL_ROOT_PASSWORD"

```

<img width="2362" height="1184" alt="image" src="https://github.com/user-attachments/assets/e0664a11-7474-4313-94c5-73aed7f299a2" />
<img width="2464" height="412" alt="image" src="https://github.com/user-attachments/assets/9554d171-99b4-46f9-9009-57ab3f5d1a4e" />
<img width="2586" height="722" alt="image" src="https://github.com/user-attachments/assets/7ed079ae-ec92-43bc-80bb-e74dea881d2e" />
<img width="1652" height="216" alt="image" src="https://github.com/user-attachments/assets/be7e71c5-def0-43ff-97cd-2860960ccf98" />


### Validation Matrix Results

| Layer | Component Verified | Command / Probe | Result | Status |
| --- | --- | --- | --- | --- |
| **App** | Pod Readiness | `kubectl get pods -n bankapp` | All pods reporting `1/1 Running` | **PASS** |
| **App** | Actuator Health | `curl http://$APP_URL/actuator/health` | `{"status":"UP"}` returned | **PASS** |
| **App** | Autoscaling | `kubectl get hpa -n bankapp` | Active target tracking CPU utilization | **PASS** |
| **Data** | Database Engine | `mysqladmin ping` | `mysqld is alive` returned | **PASS** |
| **Data** | Storage Persistence | `kubectl get pvc -n bankapp` | `mysql-pvc` & `ollama-pvc` both `Bound` | **PASS** |
| **Data** | Local LLM Model | `ollama list` | `tinyllama:latest` loaded in memory | **PASS** |
| **Infra** | Gateway Routing | `kubectl get gateway -n bankapp` | `Programmed: True` with NLB bound | **PASS** |
| **Infra** | Metrics Pipeline | `kubectl top nodes` | Metrics server scraping CPU/memory | **PASS** |
| **Security** | Container Privilege | `whoami` in bankapp pod | Runs under non-root user `devsecops` | **PASS** |
| **Security** | Secret Obfuscation | `kubectl get secret` | Base64 encoded Kubernetes secret | **PASS** |

---

## Task 5: Reflection on the Full 3-Day EKS Journey

### 5.1 Progression Matrix

| Day | Core Engineering Focus | Practical AI-BankApp Implementation |
| --- | --- | --- |
| **Day 81** | Infrastructure as Code (IaC) & EKS Foundations | Automated VPC, subnets, and EKS managed nodes using Terraform; initialized manual deployments. |
| **Day 82** | Modern Ingress & Stateful Storage Architecture | Deployed Kubernetes Gateway API with Envoy, automated TLS via cert-manager, and validated EBS CSI data recovery. |
| **Day 83** | Production Deployment, Observability & Validation | Deployed the complete stack (App + DB + LLM + Gateway + Monitoring), configured ServiceMonitors, and validated end-to-end. |

### 5.2 What Was Built

* **Terraform IaC Engine:** Multi-AZ AWS VPC across 3 availability zones with public/private subnet topology and managed node groups.
* **6 EKS Managed Add-ons:** CoreDNS, AWS VPC CNI, Kube-Proxy, Pod Identity Agent, AWS EBS CSI Driver, and Metrics Server.
* **Modern Cloud-Native Ingress:** Envoy Gateway acting as the Gateway API controller, managing an AWS Network Load Balancer.
* **Stateful Resilience:** Dynamic EBS `gp3` provisioning with `WaitForFirstConsumer` topology binding and automated pod recovery.
* **Full-Stack Observability:** `kube-prometheus-stack` scraping Spring Boot Actuator JVM and HTTP metrics every 15 seconds.

### 5.3 Production Gaps to Address in Enterprise Environments

1. **Automated Public DNS (ExternalDNS & Route 53):** Automatically create A/CNAME records pointing to dynamically provisioned NLB addresses.
2. **Zero-Trust Network Policies:** Restrict traffic flow so only the BankApp can communicate with MySQL on port 3306 and Ollama on port 11434.
3. **Pod Disruption Budgets (PDB):** Guarantee high availability (`minAvailable: 1`) during EKS cluster upgrades and worker node draining.
4. **External Secrets Operator (ESO):** Sync database credentials and API keys directly from AWS Secrets Manager rather than static Kubernetes Secrets.
5. **Scheduled Database Backups:** Automate scheduled MySQL dumps to private Amazon S3 buckets using Velero or native CronJobs.

---

## Task 6: Complete Teardown & Clean Up

To guarantee a clean environment and eliminate unexpected charges, resources are deleted in strict reverse-dependency order.

### 6.1 Delete Kubernetes Workloads & Ingress

```bash
# 1. Uninstall Prometheus & Grafana Stack
helm uninstall monitoring -n monitoring

# 2. Delete Gateway API Resources (Triggers AWS NLB deletion)
kubectl delete -f k8s/gateway.yml 2>/dev/null

# 3. Delete Application, Database, and Storage Resources (Triggers EBS volume deletion)
kubectl delete -f k8s/hpa.yml
kubectl delete -f k8s/bankapp-deployment.yml
kubectl delete -f k8s/ollama-deployment.yml
kubectl delete -f k8s/mysql-deployment.yml
kubectl delete -f k8s/service.yml
kubectl delete -f k8s/secrets.yml
kubectl delete -f k8s/configmap.yml
kubectl delete -f k8s/pvc.yml
kubectl delete -f k8s/pv.yml 2>/dev/null
kubectl delete -f k8s/namespace.yml

# 4. Uninstall Ingress Controllers & Clean Remaining Namespaces
helm uninstall envoy-gateway -n envoy-gateway-system 2>/dev/null
kubectl delete namespace monitoring envoy-gateway-system 2>/dev/null

# 4b. Delete External Tooling / Argo CD LoadBalancer (Triggers AWS Classic ELB deletion)
kubectl delete svc argocd-server -n argocd 2>/dev/null
kubectl delete namespace argocd 2>/dev/null

```

Verify that all LoadBalancers and PVCs have released their AWS cloud resources:

```bash
kubectl get svc -A | grep LoadBalancer
kubectl get pvc -A

```

### 6.2 Destroy AWS Infrastructure via Terraform

Navigate to your Terraform configuration directory and destroy the cluster, node groups, and VPC:

```bash
cd ~/AI-BankApp-DevOps/terraform
terraform destroy -auto-approve

```

### 6.3 Zero-Cost AWS CLI Audit

Run this comprehensive audit to verify that no billable AWS resources remain active:

```bash
echo "1. Checking EKS Clusters..."
aws eks list-clusters --region us-west-2

echo "2. Checking Load Balancers..."
aws elbv2 describe-load-balancers --region us-west-2 --query "LoadBalancers[].LoadBalancerArn" --output table

echo "3. Checking Unattached EBS Volumes..."
aws ec2 describe-volumes --region us-west-2 --query "Volumes[].{ID:VolumeId,State:State,Size:Size}" --output table

echo "4. Checking Elastic IPs..."
aws ec2 describe-addresses --region us-west-2 --output table

echo "5. Checking Active NAT Gateways..."
aws ec2 describe-nat-gateways --region us-west-2 --filter "Name=state,Values=available,pending" --output table

```

**Target Output:** All queries return empty tables or `"clusters": []`.

### 6.3 Post-Teardown Verification Checklist
Verified zero lingering resources across AWS region `us-west-2`:
- [x] **EKS Clusters:** 0 active clusters (`aws eks list-clusters`)
- [x] **Elastic Load Balancers:** 0 active ALBs/NLBs (`aws elbv2 describe-load-balancers`)
- [x] **Classic Load Balancers:** 0 active ELBs (`aws elb describe-load-balancers`)
- [x] **EBS Volumes:** 0 volumes in use or available (`aws ec2 describe-volumes`)
- [x] **Elastic IPs:** 0 allocated addresses (`aws ec2 describe-addresses`)
- [x] **NAT Gateways:** 0 NAT gateways running (`aws ec2 describe-nat-gateways`)

---

## Lab Cost Summary

| Service Component | Active Runtime | Approximate Cost (USD) |
| --- | --- | --- |
| **Amazon EKS Control Plane** ($0.10/hr) | ~8 hours | $0.80 |
| **EC2 Worker Nodes** (2x `t3.medium` @ ~$0.0416/hr) | ~8 hours | $0.67 |
| **AWS Network Load Balancer (NLB)** (~$0.0225/hr + LCU) | ~5 hours | $0.15 |
| **Amazon EBS Storage** (`gp3` Volumes: 15 GiB) | ~8 hours | $0.02 |
| **Data Transfer & CloudWatch Logs** | Variable | < $0.10 |
| **Total Estimated 3-Day Project Cost** |  | **~$1.74 – $2.50** |
