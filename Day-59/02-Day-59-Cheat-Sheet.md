
# 📦 Day 59 Cheat Sheet: Helm — Kubernetes Package Manager

## ⚡ Core Helm Commands
```bash
# --- Repository Management ---
helm repo add bitnami [https://charts.bitnami.com/bitnami](https://charts.bitnami.com/bitnami)
helm repo update
helm search repo bitnami/nginx

# --- Release Lifecycle ---
helm install my-release bitnami/nginx -f custom-values.yaml
helm upgrade my-release bitnami/nginx --set replicaCount=5
helm rollback my-release 1
helm uninstall my-release

# --- Observability & Auditing ---
helm list                      # List all active releases
helm history my-release        # View revision history
helm get values my-release     # View user-supplied overrides
helm get manifest my-release   # View the final rendered YAML applied to the cluster

```

## 🛠️ Custom Chart Development

```bash
helm create my-app                 # Scaffold a new chart structure
helm lint ./my-app                 # Validate syntax and strict formatting
helm template my-release ./my-app  # Render templates locally without installing (Dry-run)

```

## 📐 The Helm Trinity

| Concept | Definition | Analogy |
| --- | --- | --- |
| **Chart** | A package of Go-templated Kubernetes YAML manifests. | The blueprint or source code. |
| **Repository** | A centralized server storing packaged Charts. | Docker Hub or an APT Repository. |
| **Release** | A specific, running instance of a Chart in a cluster. | A deployed container. |

## 🚨 SRE Troubleshooting & Gotchas

* **Case Sensitivity Failures:** Helm templates are strictly case-sensitive. Writing `NodePorts` instead of `nodePorts` in a `values.yaml` file will cause Helm to silently ignore the field and fall back to the chart's defaults. Always use `helm get values <release>` to verify what Helm actually parsed.
* **Rollbacks are Immutable:** Running `helm rollback` does not delete intermediate revisions. If you upgrade to Revision 2, then rollback to Revision 1, Helm creates a brand new **Revision 3** that mirrors the state of Revision 1. This ensures your deployment audit log is never destroyed.
* **Template Rendering Errors:** Never test template logic directly in the cluster. Always use `helm template` locally first to catch missing variables or YAML indentation breaks before touching the Kubernetes API.

---

## 🎤 Interview Spotlight: Helm vs. Kubectl Apply

* **Interview Question:** *"We already have all our Kubernetes manifests written in YAML and apply them using `kubectl apply -f`. Why should we migrate our infrastructure to Helm?"*
* **The SRE Answer:** "Using raw YAML leads to configuration drift and violates the DRY (Don't Repeat Yourself) principle. If we deploy the same app to Dev, Staging, and Prod, raw YAML forces us to maintain three separate copies of every manifest. Helm allows us to maintain a single 'Chart' template and inject environment-specific variables via separate `values.yaml` files. Furthermore, `kubectl apply` treats every file individually, whereas Helm treats the entire application stack as a single 'Release', enabling atomic upgrades and instant, reliable rollbacks if an incident occurs."
