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
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

```

**2. Verify Installation:**

```bash
helm version
helm env

```

<img width="2880" height="1638" alt="image" src="https://github.com/user-attachments/assets/3712271e-59a3-4d92-b92e-d2e5d3b35c5e" />


> **✅ Verify:** *What version of Helm is installed?*
> **Answer:** *(Run `helm version` and paste your version output here, e.g., v3.14.0)*

---

### Task 2: Add a Repository and Search

We will use the **Bitnami** repository, which is widely trusted in the industry for secure, production-ready charts.

**1. Add and Update the Repo:**

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

```

**2. Search the Repo:**

```bash
helm search repo bitnami
helm search repo nginx

```
<img width="3014" height="1702" alt="image" src="https://github.com/user-attachments/assets/3bfca476-283a-436e-bfed-0ed6125c4a82" />

<img width="2872" height="386" alt="image" src="https://github.com/user-attachments/assets/a7126f07-8fea-4546-b4b8-926020717137" />

> **✅ Verify:** *How many charts does Bitnami have?*
> **Answer:** *(Look at the bottom of the `helm search repo bitnami` output or count the lines. It usually contains well over 100+ enterprise charts).*

---

### Task 3: Install a Chart

Let's replace writing Deployments and Services by hand with a single Helm command.

**1. Install Nginx:**

```bash
helm install my-nginx bitnami/nginx

```
<img width="2886" height="956" alt="image" src="https://github.com/user-attachments/assets/aff453f4-11a8-456e-9d6b-30aab69295d6" />


**2. Inspect the Release:**

```bash
kubectl get all
helm list
helm status my-nginx
helm get manifest my-nginx  # This shows the actual YAML Helm generated and applied!

```

<img width="2876" height="1336" alt="image" src="https://github.com/user-attachments/assets/cb161d4f-edc0-4442-81c0-24b309de91c3" />

<img width="2876" height="1696" alt="image" src="https://github.com/user-attachments/assets/9be20f31-687a-42ab-bdca-13e7950f2908" />

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
<img width="2876" height="1410" alt="image" src="https://github.com/user-attachments/assets/1afbbc31-9490-4453-9f39-8eddb0a0879f" />

**3. Check the overrides:**

```bash
helm get values custom-nginx

```

<img width="2838" height="746" alt="image" src="https://github.com/user-attachments/assets/5b2ad9b5-0f62-4717-9074-bfbe423568a1" />
<img width="1826" height="208" alt="image" src="https://github.com/user-attachments/assets/ab5b47d7-0e94-46ed-8540-255cad095a6a" />


### 🚨 SRE Troubleshooting Spotlight: Helm Case-Sensitivity
During this task, I encountered a real-world configuration drift issue: my NodePort was being assigned a random high port (e.g., `31291`) instead of the `30080` I defined in my `custom-values.yaml`[cite: 4].

**The Debugging Steps:**
1. First, I verified what configuration Helm *actually* applied by running:

```bash
   helm get values custom-nginx

```

2. The output revealed the root cause: I had written `NodePorts` with a capital **N**.


3. Because Helm chart templates are strictly case-sensitive, it ignored `NodePorts` as an unrecognized custom field and fell back to its default behavior of generating a random port!

**The Fix:**
I updated the file to use the correct lowercase `nodePorts`, saved it, and pushed the fix instantly using Helm's upgrade feature:

```bash
helm upgrade custom-nginx bitnami/nginx -f custom-values.yaml
kubectl get svc

```

*Result:* The upgrade applied successfully, and the service immediately locked onto the correct `30080` port without needing to uninstall and reinstall the release.

<img width="2890" height="1680" alt="image" src="https://github.com/user-attachments/assets/d14c5cca-07c2-4ad1-95bc-9512f14d57c0" />
<img width="2870" height="428" alt="image" src="https://github.com/user-attachments/assets/c479bf6d-103c-4502-b34b-4c01e118fc6a" />

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

<img width="2874" height="1144" alt="image" src="https://github.com/user-attachments/assets/7431c0b2-c474-4350-8001-1ac870bfd137" />

> **✅ Verify:** *How many revisions after the rollback?*
> **Answer:** There are now **4 Revisions**. Because I ran the upgrade command twice, I generated Revisions 1, 2, and 3. When I rolled back to Revision 1, Helm did not overwrite the intermediate steps; it created a brand new **Revision 4** containing the exact configuration state of Revision 1. This proves Helm maintains a completely immutable audit trail!

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
<img width="2872" height="1734" alt="image" src="https://github.com/user-attachments/assets/a3fb348e-0651-4a78-a880-bdf1389dfcfa" />


**4. Install and Upgrade:**

```bash
helm install my-release ./my-app
helm upgrade my-release ./my-app --set replicaCount=5

```

<img width="3052" height="1728" alt="image" src="https://github.com/user-attachments/assets/e3d0be60-70fc-46d6-bf97-93ee9934d112" />


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

<img width="2374" height="474" alt="image" src="https://github.com/user-attachments/assets/2a735fe1-2305-4367-bcbd-e39604e6e2fd" />


> **✅ Verify:** *Does helm list show zero releases?*
> **Answer:** Yes, running `helm list` now returns an empty terminal.
