# Day 66: EKS Provisioning & Troubleshooting Cheat Sheet

## 1. Directory Structure

Keep remote module orchestrations and Kubernetes manifests organized locally:

```text
terraform-eks/
├── providers.tf        # AWS and Kubernetes provider configuration
├── variables.tf        # Input variables definitions
├── terraform.tfvars    # Environment-specific variable values
├── vpc.tf              # AWS VPC module (source = "terraform-aws-modules/vpc/aws")
├── eks.tf              # AWS EKS module (source = "terraform-aws-modules/eks/aws")
├── outputs.tf          # Captured cluster connection details
└── k8s/
    └── nginx-deployment.yaml # Kubernetes Deployment and LoadBalancer Service

```

## 2. Core Infrastructure Commands

| Action | Command | Purpose |
| --- | --- | --- |
| **Initialize** | `terraform init` | Downloads remote AWS modules (`vpc/aws`, `eks/aws`) and providers. |
| **Apply** | `terraform apply -auto-approve` | Provisions the VPC, EKS Control Plane, and Node Groups (takes ~15-25 mins). |
| **Auth** | `aws eks update-kubeconfig --name  --region us-east-1` | Updates local MacBook `~/.kube/config` to securely route `kubectl` commands to the new cluster. |
| **Destroy** | `terraform destroy -auto-approve` | Tears down all resources to prevent hourly billing charges. |

## 3. Crucial SRE Troubleshooting Gotchas

**EKS Module v20+ Authentication Lockout**
In version `20.0` and higher of the AWS EKS Terraform module, the cluster creator is no longer granted administrator permissions by default via `aws-auth`. Connecting via `kubectl` will return an `Unauthorized` API error.

* **The Fix:** Explicitly map the Terraform executor to the admin role using Access Entries.

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  
  # Required to prevent "Unauthorized" errors in kubectl
  enable_cluster_creator_admin_permissions = true 
  # ...
}

```

**Auto Scaling Group (ASG) Launch Failures**
If the EKS cluster creates successfully but nodes remain stuck in a "Creating" state for over 15 minutes, the underlying EC2 instances are likely failing to boot.

* **The Debug Path:** AWS Console -> EC2 -> Auto Scaling Groups -> Select ASG -> **Activity Tab**.
* **Free Tier Constraint:** Strict AWS Free Tier accounts will actively reject `t3.medium` instances (`InvalidParameterCombination`).
* **The Fix:** Downgrade the instance type in your variables to `t3.micro` and re-apply.

**NAT Gateway Routing**
Nodes in private subnets require an `Available` NAT Gateway with a valid Public IPv4 address. If the Route Table is missing the `0.0.0.0/0` route targeting the NAT Gateway, instances will boot but fail to download `kubelet` dependencies to join the cluster.

## 4. Kubernetes Workload Deployment

When deploying standard web workloads, ensure the compute (Deployment) and networking (Service) blocks are separated by `---` in the same YAML file.

**Deploy the Application:**

```bash
kubectl apply -f k8s/nginx-deployment.yaml

```

**Verify Node Health:**

```bash
kubectl get nodes

```

**Retrieve the Public URL:**

```bash
kubectl get svc nginx-service -w

```

*(Watch the `EXTERNAL-IP` column. Once it populates with an AWS `elb.amazonaws.com` address, copy it to your browser to view the application. Note: Load balancers take 2-3 minutes to fully register targets).*

---
