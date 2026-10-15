# 🚀 Day 86: GitOps Project — End-to-End CI/CD Pipeline with AI-BankApp

## Executive Overview
Day 86 marks the culmination of the Amazon EKS and GitOps engineering block. Building upon the foundational ArgoCD setup, sync waves, App of Apps architecture, and RBAC security established over the last two days, today's focus is wiring the **complete, end-to-end GitOps CI/CD pipeline**. 

In this production architecture, a developer pushes an application code change to GitHub, **GitHub Actions** compiles the Java codebase, builds and pushes a version-tagged Docker image to DockerHub, and programmatically updates the Kubernetes deployment manifest in Git. **ArgoCD** detects the updated desired state in the repository and executes a zero-downtime rolling update on Amazon EKS—achieving a 100% automated, zero-touch path from `git push` to production.

---

## End-to-End GitOps Pipeline Architecture

```text
[Developer] ──(1. git push src/)──► [GitHub Repository (feat/gitops)]
                                            │
                                            ▼ (Triggers on src/**, pom.xml, Dockerfile)
                                   [GitHub Actions CI]
                                    ├── Checkout & Setup JDK 21
                                    ├── Maven Package & Unit Tests
                                    ├── Extract Short Git SHA (e.g., a1b2c3d)
                                    ├── Build & Push Image to DockerHub (:sha & :latest)
                                    ├── sed: Update image tag in k8s/bankapp-deployment.yml
                                    └── Commit & Push with "[skip ci]" via github-actions[bot]
                                            │
                                            ▼
                                   [GitHub Repository] (Updated Desired State)
                                            │
                                            ▼ (Polls every 3m / Webhook)
                              [ArgoCD Controller on Amazon EKS]
                                    ├── Detects Git SHA Drift vs. Live Cluster
                                    ├── Initiates Automated Sync
                                    └── Triggers Kubernetes Rolling Update
                                            │
                                            ▼
                              [Amazon EKS Production Cluster]
                                    ├── Spins up new BankApp Pods (New Image SHA)
                                    ├── Readiness Probes Pass (/actuator/health)
                                    └── Terminates Old Pods Gracefully (Zero Downtime)

```

---

## Prerequisite: Re-Provisioning Lab Infrastructure

Because the AWS environment was completely torn down previously to maintain a **$0 cloud bill**, we first bring the cluster and ArgoCD control plane back online.

```bash
# 1. Provision VPC, EKS Cluster, Node Groups, and ArgoCD via Terraform
cd ~/AI-BankApp-DevOps/terraform
terraform init
terraform apply -auto-approve

# 2. Configure local kubeconfig for the new EKS cluster control plane
aws eks update-kubeconfig --region us-west-2 --name bankapp-eks

# 3. Verify nodes and ArgoCD control plane pods are Running
kubectl get nodes
kubectl get pods -n argocd

```

<img width="1808" height="706" alt="image" src="https://github.com/user-attachments/assets/de179532-8222-41cc-af0a-763acd3520b4" />


---

## Task 1: Study the AI-BankApp's GitOps CI Pipeline

The production workflow is defined in `.github/workflows/gitops-ci.yml`. Below is the architectural breakdown of how the CI pipeline integrates cleanly with the GitOps CD paradigm without causing race conditions or infinite build loops.

### 1.1 Path-Scoped Triggers (Loop Prevention Mechanism #1)

```yaml
on:
  push:
    branches: [feat/gitops]
    paths:
      - 'src/**'
      - 'pom.xml'
      - 'Dockerfile'
  workflow_dispatch:

```

* **Engineering Rationale:** The workflow only triggers when application source code (`src/**`), dependencies (`pom.xml`), or container specifications (`Dockerfile`) are modified. Changes to `k8s/**` manifests do **not** trigger the CI pipeline. Furthermore, `workflow_dispatch` enables manual execution from the GitHub UI for debugging.

### 1.2 Step-by-Step Pipeline Execution Matrix

| Pipeline Step | Underlying Command / Action | Architectural Purpose |
| --- | --- | --- |
| **1. Checkout Code** | `actions/checkout@v4` | Clones the `feat/gitops` branch into the runner workspace. |
| **2. Set up JDK 21** | `actions/setup-java@v4` | Configures Java 21 runtime and caches `~/.m2` Maven dependencies to accelerate builds. |
| **3. Build with Maven** | `./mvnw clean package -DskipTests -B` | Compiles the Spring Boot application and packages the executable `.jar` artifact in batch mode. |
| **4. Run Unit Tests** | `./mvnw test -B` (`continue-on-error: true`) | Executes unit test suites to validate code logic without blocking pipeline validation. |
| **5. Set Image Tag** | `git rev-parse --short HEAD` | Extracts the 7-character immutable Git commit SHA (e.g., `1c7cb0e`) for strict container traceability. |
| **6. Login to DockerHub** | `docker/login-action@v3` | Authenticates securely against DockerHub using encrypted GitHub Actions secrets. |
| **7. Build & Push Image** | `docker/build-push-action@v5` | Builds the multi-stage Docker image and pushes both `:<sha_short>` and `:latest` tags. |
| **8. Update K8s Manifest** | `sed -i "s|image: ...|..." k8s/bankapp-deployment.yml` | Dynamically replaces the old image tag in the Kubernetes deployment manifest with the newly built Git SHA tag. |
| **9. Commit Updated Manifest** | `git commit -m "ci: ... [skip ci]"` & `git push` | Commits the updated deployment YAML back to the `feat/gitops` branch using the `github-actions[bot]` identity. |

### 1.3 Deep Dive: The CI-to-GitOps Handoff & `[skip ci]`

The critical handoff from Continuous Integration (GitHub Actions) to Continuous Delivery (ArgoCD) happens in the final two steps of the workflow:

```yaml
- name: Update Kubernetes deployment manifest
  run: |
    sed -i "s|image: ${{ env.DOCKERHUB_REPO }}:.*|image: ${{ env.DOCKERHUB_REPO }}:${{ steps.tag.outputs.sha_short }}|" k8s/bankapp-deployment.yml

- name: Commit updated manifest
  run: |
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add k8s/bankapp-deployment.yml
    git diff --staged --quiet || git commit -m "ci: update bankapp image to ${{ steps.tag.outputs.sha_short }} [skip ci]"
    git push

```

* **Why `[skip ci]` is Critical (Loop Prevention Mechanism #2):** When `github-actions[bot]` pushes a new commit back to the `feat/gitops` branch, GitHub evaluates whether to trigger workflows on that branch. Appending `[skip ci]` in the commit message explicitly instructs GitHub Actions to bypass workflow execution for that commit, preventing an infinite recursive loop of builds.
* **Why `git diff --staged --quiet || ...` is Used:** This ensures `git commit` only runs if `sed` actually modified the file, preventing pipeline failures due to empty commits on manual re-runs.

---

## Task 2: Set Up the Pipeline on Your Fork

To execute the end-to-end workflow under our own repository (`NB11-ML/AI-BankApp-DevOps`), we configure container registry authentication and align our manifests.

### 2.1 Configure DockerHub Access Token & GitHub Secrets

1. Navigate to **DockerHub** -> **Account Settings** -> **Security** -> **New Access Token**.
2. Generate a token with **Read & Write** permissions and copy the value.
3. Open the GitHub repository (`https://github.com/NB11-ML/AI-BankApp-DevOps`) -> **Settings** -> **Secrets and variables** -> **Actions**.
4. Create two Repository Secrets:
* `DOCKERHUB_USERNAME`: `<your-dockerhub-username>`
* `DOCKERHUB_TOKEN`: `<your-dockerhub-access-token>`



### 2.2 Align Workflow, Deployment Manifest, and ArgoCD Repo URL

**1. Update `.github/workflows/gitops-ci.yml`:**
Modify the `DOCKERHUB_REPO` environment variable to point to your DockerHub namespace:

```yaml
env:
  DOCKERHUB_REPO: <your-dockerhub-username>/ai-bankapp-eks

```

**2. Update `k8s/bankapp-deployment.yml`:**
Update the container image specification so initial deployments pull from your registry:

```yaml
containers:
  - name: bankapp
    image: <your-dockerhub-username>/ai-bankapp-eks:latest

```

**3. Commit and Push Configuration Changes:**

```bash
git checkout feat/gitops
git add .github/workflows/gitops-ci.yml k8s/bankapp-deployment.yml
git commit -m "chore(ci): point DockerHub registry to personal namespace [skip ci]"
git push origin feat/gitops

```

**4. Authenticate ArgoCD CLI & Register the Application:**

```bash
# Port-forward ArgoCD server in a background/separate terminal
kubectl port-forward svc/argocd-server -n argocd 8080:80 &

# Retrieve initial admin password and log in via CLI
ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8080 --username admin --password "$ARGOCD_PWD" --plaintext

# Apply the ArgoCD Application manifest and verify repo URL
kubectl apply -f argocd/application.yml
argocd app set bankapp --repo [https://github.com/NB11-ML/AI-BankApp-DevOps.git](https://github.com/NB11-ML/AI-BankApp-DevOps.git)

```

---

## Task 3: Trigger the Full Pipeline (Code-to-Production)

Now we simulate a real-world feature release by modifying the user interface source code and observing the automated deployment pipeline.

### 3.1 Modify Application Source Code

Edit the HTML layout template to customize the banking portal title:

```bash
# Inspect and update the title tag in the layout template
sed -i 's|<title>.*</title>|<title>AI BankApp - Built by NB11-ML</title>|' src/main/resources/templates/fragments/layout.html

# Verify the modification
grep "<title>" src/main/resources/templates/fragments/layout.html

```

### 3.2 Commit and Push to Trigger GitHub Actions

```bash
git add src/main/resources/templates/fragments/layout.html
git commit -m "feat(ui): customize application title for NB11-ML"
git push origin feat/gitops

```

### 3.3 Monitor CI Execution & Automated Git Commit

1. Navigate to `https://github.com/NB11-ML/AI-BankApp-DevOps/actions`.
2. Observe the **"GitOps CI - Build & Push to DockerHub"** workflow automatically trigger and execute all steps (`Build` -> `Test` -> `Docker Push` -> `Manifest Update`).

### Output:


3. Pull the latest commit history locally to verify the bot commit:

```bash
git pull origin feat/gitops
git log -n 2 --oneline
cat k8s/bankapp-deployment.yml | grep "image:"

```

**Expected Output:**

```text
e4f9a21 (HEAD -> feat/gitops, origin/feat/gitops) ci: update bankapp image to 8b3d1c9 [skip ci]
8b3d1c9 feat(ui): customize application title for NB11-ML
        image: <your-dockerhub-username>/ai-bankapp-eks:8b3d1c9

```
### Output:


### 3.4 Verify ArgoCD Reconciliation & Rolling Update on EKS

Watch ArgoCD detect the new commit and roll out the new pods across the EKS cluster:

```bash
# Force an immediate refresh (or wait up to 3m for automated polling)
argocd app get bankapp --refresh

# Watch ArgoCD sync completion
argocd app wait bankapp --health --timeout 300

# Watch Kubernetes execute the zero-downtime rolling update
kubectl get pods -n bankapp -l app=bankapp -w

```
### Output:

### 3.5 Verify Live Production Change

Forward local traffic to the service and verify the updated HTML title is live:

```bash
kubectl port-forward svc/bankapp-service -n bankapp 8081:8080 &
curl -s http://localhost:8081/login | grep "<title>"

```

**Output:** `<title>AI BankApp - Built by NB11-ML</title>`

---

## Task 4: Test Drift Detection and Automated Recovery

A core tenet of SRE and GitOps is **cluster immutability**: manual out-of-band changes made via `kubectl` (configuration drift) must be automatically rejected and healed back to the Git state. Below, we execute three live chaos scenarios against the cluster.

### Scenario 1: Unauthorized Replica Scaling

* **Chaos Action:** An operator manually scales down the production banking deployment from 2 replicas to 1 replica.
```bash
kubectl scale deployment bankapp -n bankapp --replicas=1

```


* **Verification & Observation:**
```bash
argocd app get bankapp
kubectl get pods -n bankapp -l app=bankapp -w

```


* **Result:** ArgoCD immediately marked the `bankapp` Deployment as `OutOfSync`. Because `selfHeal: true` is active in the sync policy, the controller re-applied the manifest from Git within **~15–45 seconds**, immediately provisioning a replacement pod to restore the desired replica count.

### Scenario 2: Unauthorized Container Image Tampering

* **Chaos Action:** Someone attempts to hijack or hot-patch the running deployment by substituting an unauthorized `nginx:latest` image directly on the cluster.
```bash
kubectl set image deployment/bankapp bankapp=nginx:latest -n bankapp

```


* **Verification & Observation:**
```bash
kubectl describe deployment bankapp -n bankapp | grep "Image:"
kubectl get pods -n bankapp -w

```


* **Result:** As soon as the live Deployment spec diverged from `k8s/bankapp-deployment.yml`, ArgoCD flagged the drift, reverted the image field back to `<dockerhub-user>/ai-bankapp-eks:<sha>`, and terminated the rogue `nginx` rollout.

### Scenario 3: Accidental Deletion of a Critical Network Service

* **Chaos Action:** The internal `ClusterIP` service routing traffic to the banking pods is accidentally deleted.
```bash
kubectl delete service bankapp-service -n bankapp

```


* **Verification & Observation:**
```bash
kubectl get svc -n bankapp -w
argocd app history bankapp

```


* **Result:** ArgoCD detected the missing Kubernetes Service resource and instantaneously recreated `bankapp-service` on port `8080`, restoring internal cluster routing with minimal disruption.

### Drift Detection Audit Matrix & Analysis

| Scenario | Manual Drift Command | Detection Latency | Recovery Time | Final Cluster State |
| --- | --- | --- | --- | --- |
| **1. Scale Down** | `kubectl scale deploy bankapp --replicas=1` | ~10–30 seconds | ~15 seconds | **Healed** (Restored to Git replica count) |
| **2. Image Tamper** | `kubectl set image deploy/bankapp bankapp=nginx:latest` | ~10–30 seconds | ~20 seconds | **Healed** (Reverted to Git SHA image) |
| **3. Service Deletion** | `kubectl delete svc bankapp-service` | Immediate (K8s Watch API) | < 5 seconds | **Healed** (`bankapp-service` recreated) |

#### Architectural Questions:

1. **How long did ArgoCD take to detect and fix the drift?**
* While ArgoCD polls the remote Git repository every **3 minutes** by default, it maintains an active **Kubernetes Watch API stream** against the live cluster resources it manages. Consequently, live cluster modifications (scaling, image changes, resource deletion) are detected almost immediately (within **5 to 30 seconds**), and the `selfHeal` reconciliation loop triggers within seconds of detection.


2. **What would happen if `selfHeal` was disabled (`selfHeal: false`)?**
* If `selfHeal` were disabled, ArgoCD would still detect the live cluster drift and transition the application status in the UI/CLI from `Synced` to **`OutOfSync`** (triggering any configured alerts), **but it would NOT revert the manual changes**. The cluster would remain in a drifted, inconsistent state until either a human operator manually clicked **Sync** or a new commit was pushed to the Git repository triggering a fresh sync operation.



---

## Task 5: Reflect on the Complete 90-Day DevOps Pipeline

Stepping back, this single automated workflow connects almost every foundational domain mastered across the **#90DaysOfDevOps** journey into one cohesive production architecture:

```text
[Developer Writes Code & Commits]
       │
       ▼
[Git Push to GitHub] ────────────────────► Days 22–28: Git Branching, SHA Versioning & GitHub
       │
       ▼
[GitHub Actions CI Pipeline] ────────────► Days 40–49: CI Workflows, Runners, Secrets & Triggers
 ├── Maven Build & Unit Testing
 ├── Multi-Stage Docker Build ───────────► Days 29–37: Dockerfiles, Layer Caching & Non-Root Security
 ├── Push Immutable SHA to DockerHub
 └── Automated Manifest Update (sed) ────► Days 01–21: Linux CLI, Bash Scripting & Text Streams
       │
       ▼
[ArgoCD Continuous Reconciliation] ──────► Days 84–86: GitOps, Sync Waves, App-of-Apps & RBAC
       │
       ▼
[Amazon EKS Production Deployment] ──────► Days 81–83: Terraform IaC, AWS VPC, EKS & Gateway API
 ├── Rolling Update & Readiness Probes ──► Days 65–72: Kubernetes Workloads, Services & Probes
 └── Dynamic Scaling & Helm Packaging ───► Days 78–80: Helm Charts, Values & HPA Autoscaling
       │
       ▼
[Full-Stack Observability Plane] ────────► Days 73–77: Prometheus Scraping, PromQL & Grafana
       │
       ▼
[Production Live — Zero Manual Touch]

```

### The 3-Day GitOps Engineering Progression

| Day | Core Focus Area | Key Engineering Deliverables |
| --- | --- | --- |
| **Day 84** | **GitOps Foundations & Self-Healing** | Deployed ArgoCD on EKS, declarative `Application` CRD setup, Envoy Gateway v1.1.0 CRD alignment, and live chaos drift validation. |
| **Day 85** | **Advanced Sync & Enterprise Security** | Orchestrated ordered startup with Sync Waves (`-5` to `2`), managed manual rollbacks, structured the App of Apps pattern (`root-app.yml`), and enforced least-privilege RBAC (`argocd-rbac-cm`) & Project isolation (`bankapp-team`). |
| **Day 86** | **End-to-End CI/CD & Cloud Hygiene** | Connected GitHub Actions CI with ArgoCD CD, automated immutable SHA tagging (`[skip ci]`), proved live drift recovery, and executed a verified zero-cost infrastructure teardown. |

---

## Task 6: Complete Teardown & Zero-Bill Verification

This concludes the Amazon EKS and ArgoCD engineering block. To ensure **zero lingering AWS charges**, we execute a strict reverse-dependency teardown.

### 6.1 Cascade Delete All ArgoCD Applications

Using the `--cascade` flag is critical—it forces ArgoCD to invoke Kubernetes garbage collection on all downstream child deployments, services, persistent volume claims (EBS volumes), and Gateway load balancers before removing the Application CRD itself.

```bash
argocd app delete bankapp --cascade -y
argocd app delete monitoring --cascade -y 2>/dev/null || true
argocd app delete envoy-gateway --cascade -y 2>/dev/null || true
argocd app delete root-app --cascade -y 2>/dev/null || true

```

### 6.2 Verify Kubernetes Resource & LoadBalancer Cleanup

Wait for all namespaces and cloud-backed LoadBalancers/PVCs to terminate completely before running Terraform destroy (this prevents VPC dependency lock errors on ENIs and Internet Gateways):

```bash
kubectl get all -n bankapp 2>/dev/null
kubectl get all -n monitoring 2>/dev/null
kubectl get svc -A | grep LoadBalancer
kubectl get pvc -A

# Remove the ArgoCD server LoadBalancer to release the AWS ELB
kubectl delete svc argocd-server -n argocd 2>/dev/null || true

```

### 6.3 Destroy AWS Cloud Infrastructure via Terraform

```bash
cd ~/AI-BankApp-DevOps/terraform
terraform destroy -auto-approve

```

### 6.4 Post-Teardown Zero-Cost AWS CLI Audit

Run the verification audit across `us-west-2` to prove that all billable resources have been terminated:

```bash
echo "=== 1. Checking EKS Clusters ==="
aws eks list-clusters --region us-west-2

echo "=== 2. Checking Application/Network Load Balancers ==="
aws elbv2 describe-load-balancers --region us-west-2 --query "LoadBalancers[].LoadBalancerArn" --output table

echo "=== 3. Checking Classic Load Balancers ==="
aws elb describe-load-balancers --region us-west-2 --query "LoadBalancerDescriptions[].LoadBalancerName" --output table

echo "=== 4. Checking EBS Volumes ==="
aws ec2 describe-volumes --region us-west-2 --query "Volumes[].{ID:VolumeId,State:State,Size:Size}" --output table

echo "=== 5. Checking Allocated Elastic IPs ==="
aws ec2 describe-addresses --region us-west-2 --output table

echo "=== 6. Checking Active NAT Gateways ==="
aws ec2 describe-nat-gateways --region us-west-2 --filter "Name=state,Values=available,pending" --output table

```
### Output:

### Final Verification Checklist

* [x] **ArgoCD Applications:** Deleted with `--cascade` (all child K8s resources purged).
* [x] **EKS Clusters:** `0` active clusters (`"clusters": []`).
* [x] **ELB / NLB / ALB:** `0` active load balancers.
* [x] **EBS Volumes:** `0` active or available volumes.
* [x] **NAT Gateways & Elastic IPs:** `0` remaining network appliances.

```

---
