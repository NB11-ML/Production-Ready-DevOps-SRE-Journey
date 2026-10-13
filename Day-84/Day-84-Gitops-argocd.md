# :octocat: Day 84: Introduction to GitOps and ArgoCD

## Overview
As part of the #90DaysOfDevOps challenge, today marks the transition from manual `kubectl` deployments to a fully automated, declarative **GitOps** model. By introducing ArgoCD to the Amazon EKS cluster, Git becomes the single source of truth for the AI-BankApp infrastructure and application state. 

This runbook documents the deployment of ArgoCD, the breakdown of the Application manifest, and real-world validation of ArgoCD's continuous reconciliation and self-healing capabilities.

---

## Prerequisite: Infrastructure Provisioning & Cluster Access
Since the environment was completely torn down at the end of Day 83 to prevent cloud charges, the first step is to re-provision the infrastructure. 

**1. Apply the Terraform Configuration:**

This provisions the VPC, EKS cluster, managed node groups, and automatically installs the ArgoCD Helm chart (via `terraform/argocd.tf`).

```bash
cd terraform
terraform apply -auto-approve
```
**2. Update Local Kubeconfig:**
Because Terraform created a brand new cluster with a new control plane endpoint, the local terminal must be authenticated to the new cluster before running any GitOps tasks:

```Bash
aws eks update-kubeconfig --region us-west-2 --name bankapp-eks
```

---

## Task 1: Understanding GitOps Principles

### What is GitOps?
GitOps is a modern continuous delivery framework where Git serves as the single source of truth for declarative infrastructure and applications. Instead of a CI server pushing changes to a cluster, a GitOps operator (like ArgoCD) continuously monitors the Git repository, compares the desired state against the live cluster state, and automatically reconciles any drift (self-healing).

### The Four Core GitOps Principles (OpenGitOps)
1. **Declarative:** A system managed by GitOps must have its desired state expressed declaratively (e.g., Kubernetes YAML).
2. **Versioned and Immutable:** The desired state is stored in a way that enforces immutability and versioning (e.g., Git commits).
3. **Pulled Automatically:** Software agents automatically pull the desired state declarations from the source.
4. **Continuously Reconciled:** Software agents continuously observe the actual system state and apply the desired state to resolve drift.

### Traditional CI/CD vs. GitOps
| Aspect | Traditional CI/CD (Push) | GitOps (Pull) |
| :--- | :--- | :--- |
| **Deployment Trigger** | CI pipeline executes `kubectl apply` | Git commit triggers cluster sync |
| **Source of Truth** | Pipeline scripts / external variables | The Git repository |
| **Drift Detection** | None (requires manual intervention) | Continuous automatic reconciliation |
| **Rollback** | Re-run an older pipeline manually | `git revert` (native version control) |
| **Audit Trail** | Fragmented across pipeline logs | Unified in Git commit history |
| **Access & Security** | CI server needs broad cluster admin credentials | Only ArgoCD (inside the cluster) has access |

### AI-BankApp GitOps Flow Architecture
```text
[Developer] pushes code to `feat/gitops`
       │
       ▼
[GitHub Actions CI]
 ├── Builds Maven project
 ├── Runs unit tests
 ├── Builds & tags Docker image (Git SHA)
 ├── Pushes to DockerHub
 └── Updates image tag in `k8s/bankapp-deployment.yml` and commits to Git
       │
       ▼
[ArgoCD Controller on EKS]
 ├── Watches the Git repository for new commits
 ├── Detects desired state changes in `k8s/`
 ├── Compares Git state vs. Live Cluster state (Drift Detection)
 └── Syncs changes via rolling update
       │
       ▼
[Zero Human Intervention] Live pods reflect the updated state.

```

---

## Task 2: Accessing ArgoCD on Amazon EKS

ArgoCD was provisioned during the Day 81 Terraform infrastructure build. Verified the operational status of the ArgoCD control plane components:

```bash
# Verify ArgoCD Pods
kubectl get pods -n argocd

# Retrieve Initial Admin Password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Expose ArgoCD UI via Port-Forwarding
kubectl port-forward svc/argocd-server -n argocd 8443:443

```

<img width="1696" height="492" alt="image" src="https://github.com/user-attachments/assets/b035dcea-6b96-41a2-93dc-23a2efe2f673" />

<img width="1680" height="534" alt="image" src="https://github.com/user-attachments/assets/91b69f3d-6136-4d8d-8900-faed502beedf" />


<img width="2620" height="2026" alt="image" src="https://github.com/user-attachments/assets/22b58f65-a29d-4d98-bd79-2c7fcbc96202" />



*Successfully authenticated to the ArgoCD UI (`https://localhost:8443`) and ArgoCD CLI using the `admin` credentials.*

---

## Task 3: The ArgoCD Application Manifest Breakdown

To deploy AI-BankApp via GitOps, I utilized the `argoproj.io/v1alpha1` Application CRD. Here is the configuration and its exact purpose:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bankapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: [https://github.com/](https://github.com/)<your-username>/AI-BankApp-DevOps.git
    targetRevision: feat/gitops
    path: k8s
  destination:
    server: [https://kubernetes.default.svc](https://kubernetes.default.svc)
    namespace: bankapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true

```

### Key Field Explanations

| Field | Purpose |
| --- | --- |
| `source.repoURL` | The target Git repository ArgoCD watches for manifests. |
| `source.targetRevision` | The specific Git branch, tag, or commit to sync (`feat/gitops`). |
| `source.path` | The directory in the repository containing the Kubernetes YAMLs (`k8s`). |
| `destination.server` | Deploys to the local EKS cluster (`kubernetes.default.svc`). |
| `syncPolicy.automated` | Enables automatic sync upon detecting Git changes. |
| `prune: true` | **Garbage Collection:** Automatically deletes resources in the cluster if they are removed from Git. |
| `selfHeal: true` | **Reconciliation:** Instantly reverts any manual changes made directly to the cluster back to the Git state. |
| `CreateNamespace=true` | Automatically creates the `bankapp` namespace if it is missing. |
| `ServerSideApply=true` | Utilizes Kubernetes SSA to prevent annotation size limits and handle field ownership conflicts better. |

---

Here is the complete, formatted Markdown section for Task 4 that you can copy and paste directly into your `day-84-gitops-argocd.md` file. It includes the deployment steps, the exact troubleshooting fixes you performed for the Envoy Gateway CRDs, the correct UI access method, and a placeholder for your screenshot.

---

### Task 4: GitOps Deployment and Verification via Argo CD

In this task, we deploy the AI-BankApp microservices using an Argo CD `Application` manifest. This manifest points Argo CD to our Git repository, enforcing a GitOps workflow where the cluster state automatically mirrors the repository state.

#### 4.1 Apply the Argo CD Application

First, deploy the application configuration that tells Argo CD to monitor the `feat/gitops` branch:

```bash
kubectl apply -f argocd/application.yml

```

#### 4.2 Troubleshooting: Envoy Gateway CRD Validation Error

During the initial sync, Argo CD reported a `Degraded` status with a validation error on the `BackendTrafficPolicy` (`bankapp-session`).

**The Cause:** The cluster was running Envoy Gateway v1.0.1, but the repository manifests utilized features introduced in v1.1+ (specifically `type: Cookie` for consistent hashing and plural `targetRefs`).

**The Fix:** Upgraded Envoy Gateway and its CRDs to v1.1.0 to align the cluster schema with the GitOps manifests:

```bash
# 1. Pull the v1.1.0 chart
helm pull oci://docker.io/envoyproxy/gateway-helm --version v1.1.0 --untar

# 2. Apply the updated v1.1.0 CRDs
kubectl apply --server-side --force-conflicts -f gateway-helm/crds/generated/
rm -rf gateway-helm

# 3. Upgrade the Envoy Gateway Helm release
helm upgrade eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.1.0 \
  -n envoy-gateway-system \
  --skip-crds

```

After the upgrade, we triggered a fresh sync:

```bash
kubectl patch application bankapp -n argocd --type merge -p '{"operation":{"sync":{"prune":true}}}'

```

#### 4.3 Accessing the Argo CD UI

To visually verify the deployment, we need to access the Argo CD dashboard. We retrieved the initial admin password using:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

```

**Access Method 1: AWS Load Balancer (Primary)**
The `argocd-server` service is provisioned with an AWS Classic Load Balancer. You can access the UI directly via plain HTTP to avoid TLS mismatch errors:

```bash
kubectl get svc -n argocd argocd-server

```

*URL:* `http://<YOUR-ELB-DNS-NAME>`

**Access Method 2: Local Port-Forwarding**
If the Load Balancer is restricted by security groups, use port-forwarding. Note: We must forward to target port 80 (which maps to the container's plaintext HTTP port 8080) to avoid `connection reset by peer` errors caused by TLS handshakes on a plaintext listener:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80

```

*URL:* `http://localhost:8080`

#### 4.4 Final Verification (Resource Tree)

Once logged in (Username: `admin`), clicking on the `bankapp` application reveals the complete GitOps state. The application successfully transitioned to **Synced** and **Healthy**, indicating all workloads (MySQL, Ollama, Spring Boot Pods, and Gateway API routes) are actively running.

<img width="3306" height="1400" alt="image" src="https://github.com/user-attachments/assets/8a4fb98f-329d-4c33-8e42-7b290ea1dcbd" />

---

## Task 5 & 6: SRE Chaos Testing & Self-Healing Validation

To validate GitOps immutability, I conducted three manual "chaos" modifications directly against the live cluster to observe ArgoCD's `selfHeal` behavior.

### Test 1: Unauthorized Replica Scaling

* **Action:** Attempted to manually scale down the application to 1 replica.
```bash
kubectl scale deployment bankapp -n bankapp --replicas=1

```

<img width="1982" height="340" alt="image" src="https://github.com/user-attachments/assets/a798477f-2ffe-471a-8da6-d06963ba9641" />


<img width="3316" height="1132" alt="image" src="https://github.com/user-attachments/assets/ac7a1886-bf0a-407d-afa4-6a5570e6129d" />



* **Result:** ArgoCD detected an `OutOfSync` drift within its 3-minute polling window. It immediately reconciled the Deployment, spinning the replicas back up to match the Git state (or the HPA's declared baseline).

### Test 2: Accidental Resource Deletion

* **Action:** Deleted a critical environment ConfigMap.
```bash
kubectl delete configmap bankapp-config -n bankapp

```


* **Result:** ArgoCD identified the missing resource and automatically recreated it from the Git source of truth, preventing extended application downtime.

### Test 3: Unauthorized Configuration Tampering

* **Action:** Edited the ConfigMap to inject an invalid database name.
```bash
kubectl edit configmap bankapp-config -n bankapp

```


* **Result:** The live cluster drift was detected. ArgoCD safely overwrote the manual tampering with the validated, version-controlled configuration stored in Git.

<img width="3312" height="1684" alt="image" src="https://github.com/user-attachments/assets/16e3752c-7660-4a0e-a8a7-c3b2818abbf1" />

<img width="3308" height="1872" alt="image" src="https://github.com/user-attachments/assets/be599a42-e525-4248-8672-628e5f1f8de3" />

### Conclusion

By enforcing `selfHeal: true` and `prune: true`, the EKS cluster is now strictly bound to Git. Any manual `kubectl` intervention is temporary and actively overwritten. All infrastructure and application changes must now undergo standard SDLC processes: Pull Requests, Code Reviews, and Auditable Git Merges.
