# ☸️ <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/terraform/terraform-original.svg" width="30" height="30" alt="Terraform Logo" /> Day 66: Provision an EKS Cluster with Terraform Modules

Today’s focus is provisioning a production-grade Amazon Elastic Kubernetes Service (EKS) cluster using Infrastructure as Code. Leveraging Terraform registry modules, we automate the creation of the VPC, subnets, NAT gateways, EKS control plane, and managed node groups, entirely eliminating manual console configuration.


---

### 📂 Task 1: Project Setup & Architecture

A clean, modular directory structure is established to manage the infrastructure components.

```text
terraform-eks/
├── providers.tf        # AWS and Kubernetes provider configuration
├── variables.tf        # Input variables definitions
├── terraform.tfvars    # Environment-specific variable values
├── vpc.tf              # AWS VPC module orchestration
├── eks.tf              # AWS EKS module orchestration
├── outputs.tf          # Captured cluster connection details
└── k8s/
    └── nginx-deployment.yaml # Kubernetes workload manifest

```

**`providers.tf`**

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "aws" {
  region = var.region
}

```

**`variables.tf`**

```hcl
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "terraweek-eks"
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "node_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "node_desired_count" {
  type    = number
  default = 2
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

```

**`terraform.tfvars`**

```hcl
region             = "us-east-1"
cluster_name       = "terraweek-eks"
cluster_version    = "1.31"
node_instance_type = "t3.micro"
node_desired_count = 2
vpc_cidr           = "10.0.0.0/16"

```

---

### 🌐 Task 2: Create the VPC with Registry Module

EKS requires a highly available network architecture. We use the official `terraform-aws-modules/vpc/aws` module to rapidly deploy this foundation.

**`vpc.tf`**

```hcl
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # EKS Subnet Tagging Requirements
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

```

**Documentation Notes:**

* **Why does EKS need both public and private subnets?** Best practice dictates that worker nodes (where applications run) sit in private subnets for security, completely isolated from direct internet access. Public subnets are required to host the NAT Gateway (giving private nodes outbound internet access to pull images) and public-facing Load Balancers that route traffic into the cluster.
* **What do the subnet tags do?** The AWS Load Balancer Controller uses these specific tags (`kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb`) to automatically discover which subnets it should place public or internal load balancers into when a Kubernetes `Service` is created.

---

### 🏗️ Task 3: Create the EKS Cluster with Registry Module

We orchestrate the control plane and managed node group using the official `terraform-aws-modules/eks/aws` module. This abstracts away the complex IAM role and security group configurations required for EKS.

**`eks.tf`**

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    terraweek_nodes = {
      ami_type       = "AL2_x86_64"
      instance_types = [var.node_instance_type]

      min_size     = 1
      max_size     = 3
      desired_size = var.node_desired_count
    }
  }

  tags = {
    Environment = "dev"
    Project     = "TerraWeek"
    ManagedBy   = "Terraform"
  }
}

```

---

### 🚀 Task 4: Apply and Connect `kubectl`

**`outputs.tf`**

```hcl
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_region" {
  value = var.region
}

```

**Execution:**

```bash
terraform init
terraform plan
terraform apply -auto-approve

```

<img width="1706" height="1276" alt="image" src="https://github.com/user-attachments/assets/0a444bef-3363-4ef8-98a6-04bd5ecf44c2" />
<img width="3420" height="1438" alt="image" src="https://github.com/user-attachments/assets/3f4a77af-4e96-4df5-847d-337009c504c2" />


*(Total Resources Created: ~52 resources, including VPC, NAT Gateways, EKS Control Plane, Node Groups, and IAM Roles).*

**Verification & Connection:**
Once provisioning is complete (approx. 10-15 minutes), update the local kubeconfig to authenticate with the new cluster:

```bash
aws eks update-kubeconfig --name terraweek-eks --region us-east-1

```

```bash
kubectl get nodes
kubectl cluster-info

```
<img width="1588" height="290" alt="image" src="https://github.com/user-attachments/assets/922fceea-3575-4080-956d-d4aadf204aec" />

---

### 🚢 Task 5: Deploy a Workload on the Cluster

To validate the cluster networking and worker nodes, we deploy an Nginx workload exposed via an AWS Classic Load Balancer.

**`k8s/nginx-deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-terraweek
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---

apiVersion: v1
kind: Service
metadata:
name: nginx-service
spec:
type: LoadBalancer
selector:
app: nginx
ports:

* port: 80
targetPort: 80

```

**Deployment Commands:**

```bash
kubectl apply -f k8s/nginx-deployment.yaml
kubectl get svc nginx-service -w

```

Wait for the `EXTERNAL-IP` to populate, then navigate to the URL in a browser to see the default Nginx welcome page.

<img width="2328" height="502" alt="image" src="https://github.com/user-attachments/assets/b4751be3-71ab-4293-8d72-72dba940300e" />
<img width="3420" height="942" alt="image" src="https://github.com/user-attachments/assets/2ebeaac9-a280-4bc8-851b-61226c102a3b" />

---

### 🧹 Task 6: Destroy Everything (Cost Management)

EKS clusters and NAT Gateways incur significant hourly charges. Clean teardown is critical.

**1. Destroy Kubernetes Resources First**
Failure to delete the LoadBalancer service first leaves an orphaned Elastic Load Balancer (ELB) in AWS, which locks the VPC and causes `terraform destroy` to hang.

```bash
kubectl delete -f k8s/nginx-deployment.yaml

```

*Wait 2-3 minutes and verify the ELB is gone from the AWS EC2 Console.*

**2. Destroy Infrastructure**

```bash
terraform destroy -auto-approve

```

**Verification:** Checked the AWS Console to ensure the EKS cluster is deleted, EC2 nodes are terminated, Elastic IPs are released, and the VPC is completely removed.

---

### 🧠 Reflection: Manual vs. Automated Clusters

Transitioning into Site Reliability Engineering workflows completely redefines how infrastructure is managed. Previously, building an environment like this manually required navigating dozens of AWS console screens, manually configuring IAM trust policies, defining security group interconnects, and painstakingly verifying subnet routes. It was an error-prone process that could take hours.

Compared to setting up a local `kind` or `minikube` cluster (Day 50), deploying EKS via Terraform abstracts massive complexity. By leveraging community modules, we guarantee that networking best practices (like isolated private subnets and automatic IAM mapping) are baked in by default. Entire disaster recovery or staging environments can now be provisioned identically in 15 minutes, representing true production-ready infrastructure automation.

