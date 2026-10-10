# Day 80 — Helm Project: Multi-Environment Deployment and CI/CD

## 🎯 Objective
Bring together two days of Helm fundamentals and custom chart creation for the AI-BankApp. This project establishes environment-specific configurations (`dev`, `staging`, `prod`), implements Helm hooks for database readiness, packages the chart for distribution, installs charts directly from packaged archives, integrates Helm into a GitOps CI/CD pipeline, and reviews production best practices.

---

## 📋 Task 1: Create Environment-Specific Values

One chart, three environments. The AI-BankApp runs differently in development vs production.

### 1. `bankapp/values-dev.yaml`
```yaml
bankapp:
  replicaCount: 1
  image:
    repository: my-local-bankapp
    tag: "latest"
    pullPolicy: IfNotPresent
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "250m"
  autoscaling:
    enabled: false

mysql:
  enabled: true
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "250m"
  persistence:
    size: 2Gi
    storageClass: standard

ollama:
  enabled: true
  model: tinyllama
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "1.5Gi"
      cpu: "1000m"
  persistence:
    size: 5Gi
    storageClass: standard

storageClass:
  create: false

```

### 2. `bankapp/values-staging.yaml`

```yaml
bankapp:
  replicaCount: 2
  image:
    repository: my-local-bankapp
    tag: "v1.2.0"
    pullPolicy: IfNotPresent
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 3
    targetCPUUtilization: 75

mysql:
  enabled: true
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  persistence:
    size: 5Gi
    storageClass: gp3

ollama:
  enabled: true
  model: tinyllama
  persistence:
    size: 10Gi
    storageClass: gp3

secrets:
  mysqlRootPassword: StagingPass@456
  mysqlUser: root
  mysqlPassword: StagingPass@456

storageClass:
  create: true

```

### 3. `bankapp/values-prod.yaml`

```yaml
bankapp:
  replicaCount: 4
  image:
    repository: my-local-bankapp
    tag: "v1.2.0"
    pullPolicy: IfNotPresent
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 4
    targetCPUUtilization: 70

mysql:
  enabled: true
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
  persistence:
    size: 20Gi
    storageClass: gp3

ollama:
  enabled: true
  model: tinyllama
  resources:
    requests:
      memory: "2Gi"
      cpu: "900m"
    limits:
      memory: "2.5Gi"
      cpu: "1500m"
  persistence:
    size: 10Gi
    storageClass: gp3

secrets:
  mysqlRootPassword: ProdSecure@789
  mysqlUser: root
  mysqlPassword: ProdSecure@789

storageClass:
  create: true

gateway:
  enabled: true
```

### Environment Comparison Matrix

| Setting | Dev | Staging | Prod |
| --- | --- | --- | --- |
| **BankApp Replicas** | 1 (fixed) | 2-3 (HPA) | 2-4 (HPA) |
| **Image tag** | `latest` | `v1.2.0` | `v1.2.0` |
| **MySQL storage** | 2Gi | 5Gi | 20Gi |
| **MySQL resources** | 128Mi / 100m | 256Mi / 250m | 512Mi / 500m |
| **Ollama memory** | 1Gi | 2Gi | 2.5Gi |
| **Gateway** | Disabled | Disabled | Enabled |

### Deployment & Rendering Commands

```bash
# Dev deployment (on KinD)
helm install bankapp-dev bankapp/ -f bankapp/values-dev.yaml -n dev --create-namespace

# Staging dry-run template check
helm template bankapp-staging bankapp/ -f bankapp/values-staging.yaml | grep -i "replicas:"

# Prod dry-run template check
helm template bankapp-prod bankapp/ -f bankapp/values-prod.yaml | grep -i "replicas:"

```

<img width="2384" height="1004" alt="image" src="https://github.com/user-attachments/assets/590cbfab-9296-480e-9154-b511e41a1d76" />

<img width="2408" height="480" alt="image" src="https://github.com/user-attachments/assets/40fffe5f-b866-440e-ba1a-82a2f6e38e25" />

---

## 🪝 Task 2: Add Helm Hooks

Helm hooks offer an alternative approach to init containers by running pre-install or pre-upgrade tasks.

### 1. Pre-Install Job (`bankapp/templates/pre-install-job.yaml`)

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "bankapp.fullname" . }}-db-ready
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      containers:
        - name: db-check
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - |
              echo "Waiting for MySQL to be ready..."
              until nc -z {{ include "bankapp.fullname" . }}-mysql 3306; do
                echo "MySQL not ready, retrying in 3s..."
                sleep 3
              done
              echo "MySQL is ready!"
          resources:
            requests: { memory: "32Mi", cpu: "50m" }
            limits: { memory: "64Mi", cpu: "100m" }
      restartPolicy: Never
  backoffLimit: 10

```

* **`helm.sh/hook: pre-install,pre-upgrade`**: Executes prior to chart installation or upgrade.
* **`before-hook-creation`**: Cleans up old job instances automatically on subsequent runs.

### 2. Helm Test Pod (`bankapp/templates/tests/test-connection.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ include "bankapp.fullname" . }}-test
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: test
      image: busybox:1.36
      command: ['sh', '-c', 'wget -qO- http://{{ include "bankapp.fullname" . }}-service:8080/actuator/health']
  restartPolicy: Never

```

Run test validation post-deployment:

```bash
helm test bankapp-dev -n dev --logs
```


<img width="2544" height="1086" alt="image" src="https://github.com/user-attachments/assets/68ddace2-d818-43b2-b021-0f38c53b2979" />

---

## 📦 Task 3: Package and Version the Chart

1. **Lint and Package:**
```bash
helm lint bankapp/
helm package bankapp/

```
<img width="2672" height="504" alt="image" src="https://github.com/user-attachments/assets/92389e3c-cb99-4378-ab68-9c78f2bb7d82" />


*(This initially generates `bankapp-0.1.0.tgz`)*

2. **Bump Versions in `Chart.yaml`:**

After modifying structure or adding hooks, update versions:

```yaml
version: 0.2.0        # Chart structure changed (added hooks)
appVersion: "1.1.0"    # App version updated

```
3. **Re-package:**
```bash
helm package bankapp/

```
<img width="2622" height="456" alt="image" src="https://github.com/user-attachments/assets/b886b745-2872-4e6e-a99d-3df9ca3047f1" />

<img width="1538" height="376" alt="image" src="https://github.com/user-attachments/assets/2f5f6418-6a57-4a34-96cb-b2463a0135eb" />

*(Now you have both `bankapp-0.1.0.tgz` and `bankapp-0.2.0.tgz`)*

4. **Install Directly from the Packaged Archive:**
   
```bash
helm install my-bankapp bankapp-0.2.0.tgz -f bankapp/values-dev.yaml -n bankapp --create-namespace

```
<img width="2352" height="618" alt="image" src="https://github.com/user-attachments/assets/988e1ddd-db40-45bb-a8f8-5cc6259081cd" />


<img width="1704" height="1412" alt="image" src="https://github.com/user-attachments/assets/e21b225a-7d8c-425c-a966-31ab4f2eec20" />


5. **Create Chart Repository Index (for GitHub Pages distribution):**
```bash
mkdir chart-repo
cp bankapp-*.tgz chart-repo/
helm repo index chart-repo/ --url [https://your-username.github.io/helm-charts](https://your-username.github.io/helm-charts)
cat chart-repo/index.yaml

```



---

## 🔄 Task 4: Understand Helm in the AI-BankApp GitOps Pipeline

### Workflow Evolution

* **Raw Manifest Pipeline:** Developer pushes code -> CI builds image and updates image tag via `sed` in `k8s/bankapp-deployment.yml` -> Git commit -> ArgoCD syncs.
* **Helm-based Pipeline:** Developer pushes code -> CI builds image and updates `image.tag` in `helm-chart/values-prod.yaml` via `yq` -> Git commit -> ArgoCD syncs via `helm upgrade`.

### GitHub Actions Snippet (`yq` update pattern)

```yaml
- name: Update Helm values with new image tag
  run: |
    TAG=${{ steps.tag.outputs.sha_short }}
    yq -i '.bankapp.image.tag = "'$TAG'"' helm-chart/bankapp/values-prod.yaml

```

### ArgoCD Application Source Configuration

```yaml
source:
  path: helm-chart/bankapp
  helm:
    valueFiles:
      - values-prod.yaml

```

---

## 🛡️ Task 5: Helm Best Practices for Production

1. **Robust Installation Command:**
```bash
helm upgrade --install bankapp bankapp/ \
  -f bankapp/values-prod.yaml \
  --set bankapp.image.tag=$GIT_SHA \
  -n bankapp --create-namespace \
  --wait --timeout 300s \
  --atomic

```


2. **Diff Verification:** Use `helm diff upgrade bankapp bankapp/ -f bankapp/values-prod.yaml` before applying upgrades.
3. **Resource Quotas (`templates/resourcequota.yaml`):**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: {{ include "bankapp.fullname" . }}-quota
  namespace: {{ .Release.Namespace }}
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi

```


4. **Secret Management:** Rely on external controllers (External Secrets Operator, Vault, or Sealed Secrets) rather than hardcoding passwords in `values.yaml`.

---

## 🧹 Task 6: Clean Up and Review

Verify deployments cluster-wide:

```bash
helm list -A

```
## Troubleshooting & Post-Mortem: Day 80 Helm Deployment

**1. Helm Pre-Install Hook Deadlock**

* **Symptom:** Running `helm install` caused the terminal to hang indefinitely. No services, deployments, or PVCs were created in the namespace.
* **Root Cause:** The `pre-install-job.yaml` utilized a `"helm.sh/hook": pre-install` annotation. This hook instructed Helm to wait for the job to complete *before* creating any other resources. However, the job contained a script (`nc -z`) waiting for the MySQL service to become available, creating a deadlock (the job waited for the service, but the service couldn't be created until the job finished).
* **Resolution:** Removed the `pre-install` hook annotation, allowing standard Kubernetes container initialization and init-containers to manage the startup sequence organically.

**2. MySQL OOMKilled & CrashLoopBackOff**

* **Symptom:** The `bankapp-dev-mysql` pod repeatedly crashed immediately upon startup, throwing an `OOMKilled` status code followed by `CrashLoopBackOff`.
* **Root Cause:** MySQL requires sufficient memory overhead to allocate its InnoDB buffer pool during initialization. The container was strictly limited to `256Mi` of RAM.
* **Resolution:**
* Updated the hardcoded resource block in `bankapp/templates/mysql-deployment.yaml` to dynamically parse values using `{{- toYaml .Values.mysql.resources | nindent 12 }}`.
* Increased the memory allocation in `values-dev.yaml` to `requests: 512Mi` and `limits: 1Gi`.



**3. Stuck Helm Upgrades (Pending Lock)**

* **Symptom:** Attempting to apply the new memory limits using `helm upgrade` returned an error: `UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress`.
* **Root Cause:** The previous `helm install` command was interrupted (Ctrl+C) while it was deadlocked by the pre-install hook, leaving the Helm release state locked in a "pending-install" status.
* **Resolution:** Executed a full `helm uninstall bankapp-dev -n dev` to clear the corrupted release state and wipe orphaned resources, followed by a clean `helm install` with the corrected configuration.

**4. Resource Starvation from Ghost Pods**

* **Symptom:** Even with Docker memory limits set high (8GB+), the cluster struggled to allocate resources.
* **Root Cause:** An orphaned MySQL StatefulSet (`bankapp-mysql-0`) from a previous exercise was still running in the `default` namespace, consuming cluster node memory.
* **Resolution:** Manually purged the stale StatefulSet and service using `kubectl delete statefulset bankapp-mysql`, freeing up the necessary node memory for the dev deployment.

<img width="2334" height="1056" alt="image" src="https://github.com/user-attachments/assets/aabdc784-5bac-46d0-b8f8-0a833c6b8774" />
<img width="1902" height="512" alt="image" src="https://github.com/user-attachments/assets/af975bd2-14de-496f-b7cc-bee126c0a6aa" />
<img width="2518" height="894" alt="image" src="https://github.com/user-attachments/assets/71ec3670-dfe6-4a22-bc0c-6307515e8a95" />



### 3-Day Helm Journey Summary

| Day | Concept | AI-BankApp Connection |
| --- | --- | --- |
| **78** | Install, repos, values, upgrade, rollback | Deployed external MySQL via Bitnami chart |
| **79** | Custom chart creation, Go templates | Converted 12 raw `k8s/` manifests into a Helm chart |
| **80** | Multi-env values, hooks, packaging, CI/CD | Production-ready chart with dev/staging/prod configs |

### Helm vs. Raw Manifests vs. Kustomize

* **Raw Manifests:** Best for simple, single-env deployments (`k8s/` directory).
* **Helm:** Best for multi-environment, complex applications with dependencies.
* **Kustomize:** Best for patching existing manifests without template engines.

### Clean-up Commands

```bash
helm uninstall bankapp-dev -n dev
kubectl delete namespace dev
kind delete cluster --name tws-cluster

```
---
