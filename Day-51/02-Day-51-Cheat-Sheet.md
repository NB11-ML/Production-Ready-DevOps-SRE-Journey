# Kubernetes Pods & Operations Cheat Sheet

**The 4 Pillars of a Kubernetes Manifest**

| Field | Purpose | Example Value |
| :--- | :--- | :--- |
| `apiVersion` | The API endpoint and version required to create the object. | `v1`, `apps/v1`, `networking.k8s.io/v1` |
| `kind` | The type of resource you are instructing Kubernetes to create. | `Pod`, `Deployment`, `Service` |
| `metadata` | Data that uniquely identifies the object and organizes it. | `name: nginx-pod`, `labels: {app: web}` |
| `spec` | The desired state of the resource (containers, ports, volumes). | `containers: [{image: nginx}]` |

**Essential Pod Lifecycle Commands**

| Command | Action | Troubleshooting Context |
| :--- | :--- | :--- |
| `kubectl apply -f <file.yaml>` | Creates or updates resources from a YAML manifest. | Standard declarative deployment method. |
| `kubectl get pods -o wide` | Lists pods with their assigned Worker Node and internal IP. | Verifies scheduling and network assignment. |
| `kubectl describe pod <name>` | Outputs detailed state, constraints, and the event log. | Primary command for diagnosing `Pending` or `CrashLoopBackOff` pods. |
| `kubectl logs <name>` | Streams the standard output (stdout/stderr) of the container. | Used for debugging application-level crashes. |
| `kubectl exec -it <name> -- /bin/sh` | Opens an interactive shell inside the running container. | Used for internal network testing and filesystem inspection. |
| `kubectl delete pod <name>` | Permanently destroys a standalone pod. | Note: Bare pods do not recreate themselves upon deletion. |

**Imperative Execution & Manifest Generation (Dry Runs)**

| Command | Purpose |
| :--- | :--- |
| `kubectl run <name> --image=<image>` | Imperatively spins up a pod bypassing YAML files. |
| `kubectl apply -f <file> --dry-run=client` | Validates YAML syntax locally without touching the cluster. |
| `kubectl apply -f <file> --dry-run=server` | Submits YAML to the API server to strictly validate against the schema. |
| `kubectl run <name> --image=<image> --dry-run=client -o yaml > pod.yaml` | Instantly scaffolds a perfectly formatted YAML template to edit. |

**Labeling and Selectors**

| Command | Purpose |
| :--- | :--- |
| `kubectl get pods --show-labels` | Appends a column displaying all key-value pairs attached to the pods. |
| `kubectl get pods -l <key>=<value>` | Filters the output to show only pods matching the specific label. |
| `kubectl label pod <name> <key>=<value>` | Imperatively attaches a new label to a running pod. |
| `kubectl label pod <name> <key>-` | Removes a label from a pod (note the trailing minus sign). |

```
