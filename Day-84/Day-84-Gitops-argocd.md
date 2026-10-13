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

## Task 4: Deploying AI-BankApp via ArgoCD

1. Cleaned the slate by deleting the manually applied namespace:
```bash
kubectl delete namespace bankapp 2>/dev/null

```


2. Applied the ArgoCD `Application` manifest pointing to the forked repository.
3. Monitored the deployment lifecycle natively through the ArgoCD UI Resource Tree. ArgoCD intelligently applied all manifests, successfully orchestrating the Stateful dependencies (MySQL & Ollama) alongside the Spring Boot application pods.

*(Insert Screenshot: `images/argocd-resource-tree.png` - Showing the healthy Application Resource Tree from the ArgoCD UI)*

---

## Task 5 & 6: SRE Chaos Testing & Self-Healing Validation

To validate GitOps immutability, I conducted three manual "chaos" modifications directly against the live cluster to observe ArgoCD's `selfHeal` behavior.

### Test 1: Unauthorized Replica Scaling

* **Action:** Attempted to manually scale down the application to 1 replica.
```bash
kubectl scale deployment bankapp -n bankapp --replicas=1

```


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

*(Insert Screenshot: `images/argocd-sync-drift.png` - Showing the Sync event history and drift correction in the ArgoCD UI)*

### Conclusion

By enforcing `selfHeal: true` and `prune: true`, the EKS cluster is now strictly bound to Git. Any manual `kubectl` intervention is temporary and actively overwritten. All infrastructure and application changes must now undergo standard SDLC processes: Pull Requests, Code Reviews, and Auditable Git Merges.
