**Day 52: Namespaces & Deployments Cheat Sheet**

| Command | Action | Production / SRE Context |
| --- | --- | --- |
| `kubectl get namespaces` | Lists all namespaces in the cluster. | Verify cluster separation (e.g., `dev`, `staging`, `kube-system`). |
| `kubectl create namespace <name>` | Imperatively creates a new namespace. | Fast provisioning for isolated testing environments. |
| `kubectl get pods -A` | Lists pods across all namespaces globally. | Essential for cluster-wide audits or finding lost workloads. |
| `kubectl get deployments -n <ns>` | Lists deployments in a specific namespace. | Shows `READY`, `UP-TO-DATE`, and `AVAILABLE` replica counts. |
| `kubectl apply -f <file.yaml>` | Creates/updates a Deployment declaratively. | The standard GitOps method for applying state changes. |
| `kubectl scale deployment <name> --replicas=<N>` | Imperatively scales a deployment. | Emergency horizontal scaling during unexpected traffic spikes. |
| `kubectl set image deployment/<name> <container>=<image>` | Triggers a rolling update to a new image. | Updates workloads with zero downtime by cycling pods one by one. |
| `kubectl rollout status deployment/<name>` | Streams the real-time status of an update. | Validates that new replicas are passing health checks. |
| `kubectl rollout history deployment/<name>` | Displays previous deployment revisions. | Used to identify stable configurations prior to a rollback. |
| `kubectl rollout undo deployment/<name>` | Instantly reverts to the previous revision. | The fastest mitigation for a Sev-1 outage caused by a bad deployment. |
