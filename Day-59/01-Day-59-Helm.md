# 📦 Day 59: Helm — The Kubernetes Package Manager

Over the past few days, we have manually written dozens of YAML files for Deployments, Services, ConfigMaps, and Autoscalers. In a production environment, managing hundreds of distinct YAML files leads to "manifest sprawl" and configuration drift. 

Enter **Helm**: the package manager for Kubernetes. Just like `apt` for Ubuntu or `npm` for Node.js, Helm allows you to template, install, upgrade, and version-control entire application stacks with a single command. 

---

## 📖 SRE Theory: The Helm Trinity
Helm operates on three foundational concepts:
1.  **Chart:** A package of pre-configured Kubernetes resource templates (the blueprint).
2.  **Repository:** A hosted collection of published Charts (like Docker Hub, but for Kubernetes manifests).
3.  **Release:** A specific, running instance of a Chart deployed into your cluster.

*Bonus Concept:* **Go Templating:** Helm uses Go template syntax (e.g., `{{ .Values.replicaCount }}`) to inject dynamic variables from a `values.yaml` file into your static Kubernetes manifests before applying them.

---

## 🚀 Challenge Tasks & Execution

### Task 1: Install Helm
First, we install the Helm CLI to interact with our cluster.

**1. Install Helm (Linux/macOS script):**
```bash
curl -fsSL -o get_helm.sh [https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3](https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3)
chmod 700 get_helm.sh
./get_helm.sh

```

**2. Verify Installation:**

```bash
helm version
helm env

```

> **✅ Verify:** *What version of Helm is installed?*
> **Answer:** *(Run `helm version` and paste your version output here, e.g., v3.14.0)*

---

### Task 2: Add a Repository and Search

We will use the **Bitnami** repository, which is widely trusted in the industry for secure, production-ready charts.

**1. Add and Update the Repo:**

```bash
helm repo add bitnami [https://charts.bitnami.com/bitnami](https://charts.bitnami.com/bitnami)
helm repo update

```

**2. Search the Repo:**

```bash
helm search repo bitnami
helm search repo nginx

```

> **✅ Verify:** *How many charts does Bitnami have?*
> **Answer:** *(Look at the bottom of the `helm search repo bitnami` output or count the lines. It usually contains well over 100+ enterprise charts).*

---

### Task 3: Install a Chart

Let's replace writing Deployments and Services by hand with a single Helm command.

**1. Install Nginx:**

```bash
helm install my-nginx bitnami/nginx

```

**2. Inspect the Release:**

```bash
kubectl get all
helm list
helm status my-nginx
helm get manifest my-nginx  # This shows the actual YAML Helm generated and applied!

```

> **✅ Verify:** *How many Pods are running? What Service type was created?*
> **Answer:** By default, it deploys **1 Pod** and a Service of type **LoadBalancer** (or ClusterIP depending on the specific chart defaults, check your `kubectl get all` output!).

---

### Task 4: Customize with Values

Charts are built to be overridden. You can pass single variables via `--set`, or pass an entire configuration file via `-f`.

**1. Create a `custom-values.yaml` file:**

```yaml
# custom-values.yaml
replicaCount: 3
service:
  type: NodePort
  nodePorts:
    http: 30080
resources:
  limits:
    cpu: 250m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

```

**2. Deploy a new customized release:**

```bash
helm install custom-nginx bitnami/nginx -f custom-values.yaml

```

**3. Check the overrides:**

```bash
helm get values custom-nginx

```

> **✅ Verify:** *Does the values file release have the correct replicas and service type?*
> **Answer:** Yes! Running `kubectl get pods` will show 3 replicas, and `kubectl get svc` will show `custom-nginx` exposed via NodePort.

---

### Task 5: Upgrade and Rollback

Helm tracks every change as a "Revision". This makes rollbacks incredibly safe and auditable.

**1. Upgrade the release (Scale to 5):**

```bash
helm upgrade my-nginx bitnami/nginx --set replicaCount=5

```

**2. Check the Audit History:**

```bash
helm history my-nginx

```

**3. Oh no, an incident! Rollback to Revision 1:**

```bash
helm rollback my-nginx 1
helm history my-nginx

```

> **✅ Verify:** *How many revisions after the rollback?*
> **Answer:** There are now **3 Revisions**. Helm does not delete Revision 2; it creates a brand new Revision 3 that contains the exact configuration state of Revision 1. This preserves the immutable audit trail!

---

### Task 6: Create Your Own Chart

Let's scaffold our very own Helm Chart.

**1. Scaffold the directory:**

```bash
helm create my-app

```

*(Explore the generated folder: `Chart.yaml` contains metadata, `values.yaml` contains defaults, and `templates/` contains the Go-templated YAML).*

**2. Edit `my-app/values.yaml`:**
Change these lines in the generated file:

```yaml
replicaCount: 3
image:
  repository: nginx
  tag: "1.25"

```

**3. Lint and Template (SRE Best Practices):**

```bash
# Checks for syntax errors
helm lint my-app 

# Renders the YAML locally WITHOUT applying it to the cluster (Dry-run)
helm template my-release ./my-app

```

**4. Install and Upgrade:**

```bash
helm install my-release ./my-app
helm upgrade my-release ./my-app --set replicaCount=5

```

> **✅ Verify:** *After installing, 3 replicas? After upgrading, 5?*
> **Answer:** Yes, the initial install respected the `values.yaml` (3 replicas), and the imperative `--set` command successfully overrode it during the upgrade (5 replicas).

---

### Task 7: Clean Up

Wipe the cluster clean of all releases.

```bash
helm list
helm uninstall my-nginx custom-nginx my-release
rm -rf my-app custom-values.yaml

```

> **✅ Verify:** *Does helm list show zero releases?*
> **Answer:** Yes, running `helm list` now returns an empty terminal.
