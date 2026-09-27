#  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/terraform/terraform-original.svg" width="30" height="30" alt="Terraform Logo" /> Day 67: TerraWeek Capstone — Multi-Environment Infrastructure

Welcome to the TerraWeek Capstone! This project combines seven days of Terraform fundamentals—providers, resources, variables, modules, and state management—into a single, production-grade architecture.

Instead of copying and pasting code to create separate folders for Dev, Staging, and Prod, we use **Terraform Workspaces** and **Custom Modules** to dynamically provision three completely isolated environments from one unified codebase.

---

## 🏗️ Task 1: Understanding Terraform Workspaces

Workspaces allow you to manage multiple distinct state files from a single configuration directory. Think of them as parallel universes for your infrastructure.

**Commands to manage workspaces:**

```bash
# Initialize the project
mkdir terraweek-capstone && cd terraweek-capstone
terraform init

# View current workspace (defaults to 'default')
terraform workspace show 

# Create new isolated workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# List all available workspaces
terraform workspace list

# Switch between environments
terraform workspace select dev

```
<img width="1708" height="394" alt="image" src="https://github.com/user-attachments/assets/06c2ccf1-5bd9-4e22-a76a-a15bdbb894c3" />
<img width="2886" height="1392" alt="image" src="https://github.com/user-attachments/assets/fd2334b4-756f-45c9-94ff-0c2267d5f1f1" />
<img width="1532" height="252" alt="image" src="https://github.com/user-attachments/assets/9ec72941-af88-468a-96b5-5fd5dd8d1398" />

### Capstone Q&A

* **What does `terraform.workspace` return inside a config?**
It returns the exact name of the currently active workspace as a string (e.g., `"dev"`, `"staging"`, or `"prod"`). This allows you to dynamically name resources, apply tags, or trigger logic based on the environment you are currently operating in.
* **Where does each workspace store its state file?**
Instead of saving to the root directory, local workspaces store their state in a hidden directory structured as: `terraform.tfstate.d//terraform.tfstate`. If you use a remote backend like S3, it appends the workspace name to the object key path (e.g., `env://terraform.tfstate`).
* **How is this different from using separate directories per environment?**
Using separate directories requires duplicating your `.tf` files across multiple folders, which violates the DRY (Don't Repeat Yourself) principle and can lead to code drift. Workspaces allow you to use the exact same code, isolating the environments strictly through different state files and variable inputs.

---

## 📁 Task 2: Project Structure & Security

This file structure is considered best practice because it separates logic from configuration. The root module orchestrates the workflow, `.tfvars` files handle environment-specific inputs, and child modules isolate the actual resource creation.

### Directory Tree

```text
terraweek-capstone/
├── main.tf                 # Root module -- calls child modules
├── variables.tf            # Root variables
├── outputs.tf              # Root outputs
├── providers.tf            # AWS provider and backend
├── locals.tf               # Local values using workspace
├── dev.tfvars              # Dev environment values
├── staging.tfvars          # Staging environment values
├── prod.tfvars             # Prod environment values
├── .gitignore              # Ignores state and tfvars with secrets
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security-group/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ec2-instance/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf

```

### `.gitignore` (Security Best Practice)

Never commit state files or variable files to source control. They can contain sensitive cloud provider credentials, architecture details, and passwords.

```gitignore
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
.terraform.lock.hcl

```

---

## 🧩 Task 3: Building the Custom Modules

Modules are reusable "Lego blocks" of code. We build them once and call them multiple times.

### 1. VPC Module (`modules/vpc/`)

Creates an isolated network environment.

**`variables.tf`**

```hcl
variable "cidr" {}
variable "public_subnet_cidr" {}
variable "environment" {}
variable "project_name" {}

```

**`main.tf`**

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.cidr
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project = var.project_name
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

```

**`outputs.tf`**

```hcl
output "vpc_id" { value = aws_vpc.main.id }
output "subnet_id" { value = aws_subnet.public.id }

```

### 2. Security Group Module (`modules/security-group/`)

Acts as a dynamic firewall to control inbound and outbound traffic.

**`variables.tf`**

```hcl
variable "vpc_id" {}
variable "ingress_ports" { type = list(number) }
variable "environment" {}
variable "project_name" {}

```

**`main.tf`**

```hcl
resource "aws_security_group" "sg" {
  name        = "\({var.project_name}-\){var.environment}-sg"
  description = "Managed by Terraform for ${var.environment}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

```

**`outputs.tf`**

```hcl
output "sg_id" { value = aws_security_group.sg.id }

```

### 3. EC2 Instance Module (`modules/ec2-instance/`)

Provisions the compute server.

**`variables.tf`**

```hcl
variable "ami_id" {}
variable "instance_type" {}
variable "subnet_id" {}
variable "security_group_ids" { type = list(string) }
variable "environment" {}
variable "project_name" {}

```

**`main.tf`**

```hcl
resource "aws_instance" "server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  tags = {
    Name = "\({var.project_name}-\){var.environment}-server"
    Environment = var.environment
    Project = var.project_name
  }
}

```

**`outputs.tf`**

```hcl
output "instance_id" { value = aws_instance.server.id }
output "public_ip" { value = aws_instance.server.public_ip }

```

### 🧠 Mental Model: How Terraform Modules Communicate

If you are wondering why there are multiple `main.tf` files and how data moves between them, think of a Terraform project like a professional restaurant kitchen:

**The Root `main.tf` is the Head Chef.** 
The Head Chef doesn't actually cook the food. Their job is to read the customer's order ticket (your `.tfvars` file) and coordinate the kitchen stations. 

**The Child Modules are the Specialized Kitchen Stations.**
*   `modules/vpc/` is the **Prep Station** (Networking).
*   `modules/security-group/` is the **Grill Station** (Firewalls).
*   `modules/ec2-instance/` is the **Plating Station** (Compute).

**How the data flows between them:**
1. **Data flows IN via Variables:** The Head Chef reads the ticket and yells to the Prep Station (VPC Module), *"I need a network, and the size needs to be `10.0.0.0/16`!"* The Prep Station accepts this data through its `variables.tf` file and builds the network.
2. **Data flows OUT via Outputs:** The Prep Station finishes and yells back to the Head Chef, *"Network is done! The ID is `vpc-12345`!"* It passes this ID back up to the Chef using its `outputs.tf` file.
3. **Data flows BETWEEN modules:** The Head Chef takes that `vpc-12345` ID and hands it to the Grill Station (Security Group Module), saying, *"Build a firewall, and attach it to `vpc-12345`."* 

By setting it up this way, the Grill Station doesn't need to know how to build a VPC, and the Prep Station doesn't need to know how to build a firewall. They just take instructions (`variables.tf`) from the Head Chef, do their specific job in their own `main.tf`, and hand back the results (`outputs.tf`).

---

## 🔌 Task 4: Wire It All Together (Root Config)

By utilizing `terraform.workspace`, the root module dynamically adjusts parameters based on the active environment.

**`locals.tf`**

```hcl
locals {
  environment = terraform.workspace
  name_prefix = "\({var.project_name}-\){local.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Workspace   = terraform.workspace
  }
}

```

**`variables.tf`**

```hcl
variable "project_name" { type = string, default = "terraweek" }
variable "vpc_cidr" { type = string }
variable "subnet_cidr" { type = string }
variable "instance_type" { type = string }
variable "ingress_ports" { type = list(number), default = [22, 80] }

```

**`main.tf`**

```hcl
module "vpc" {
  source             = "./modules/vpc"
  cidr               = var.vpc_cidr
  public_subnet_cidr = var.subnet_cidr
  environment        = local.environment
  project_name       = var.project_name
}

module "security_group" {
  source        = "./modules/security-group"
  vpc_id        = module.vpc.vpc_id
  ingress_ports = var.ingress_ports
  environment   = local.environment
  project_name  = var.project_name
}

module "ec2_instance" {
  source             = "./modules/ec2-instance"
  ami_id             = "ami-0c7217cdde317cfec" # Replace with valid regional Ubuntu AMI
  instance_type      = var.instance_type
  subnet_id          = module.vpc.subnet_id
  security_group_ids = [module.security_group.sg_id]
  environment        = local.environment
  project_name       = var.project_name
}

```

### Highlighting Environment Differences (`.tfvars`)

The true power of this setup lies in the `.tfvars` files. Notice how **CIDR blocks do not overlap** to prevent peering conflicts, **instance types scale up**, and the **Production environment denies SSH (Port 22) access**.

**`dev.tfvars`**

```hcl
vpc_cidr      = "10.0.0.0/16"
subnet_cidr   = "10.0.1.0/24"
instance_type = "t2.micro"
ingress_ports = [22, 80]

```

**`staging.tfvars`**

```hcl
vpc_cidr      = "10.1.0.0/16"
subnet_cidr   = "10.1.1.0/24"
instance_type = "t2.small"
ingress_ports = [22, 80, 443]

```

**`prod.tfvars`**

```hcl
vpc_cidr      = "10.2.0.0/16"
subnet_cidr   = "10.2.1.0/24"
instance_type = "t3.small"
ingress_ports = [80, 443] 

```

**`providers.tf`**
Tells Terraform to download the AWS plugin (version 6.x) and sets the region where our infrastructure will be built.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

```

**`outputs.tf`**
This root output file grabs the results from the child modules and prints them to our terminal so we can see the Public IPs after deployment.

```hcl
output "environment_details" {
  description = "Active Workspace Deployment Details"
  value = {
    active_workspace = local.environment
    vpc_id           = module.vpc.vpc_id
    instance_id      = module.ec2_instance.instance_id
    server_public_ip = module.ec2_instance.public_ip
  }
}

```

With these added to Task 4, your markdown file is fully complete and perfectly reflects a production-ready setup!

---

## 🚀 Task 5: Deploy All Three Environments

Deploy the isolated environments by selecting the target workspace and feeding it the corresponding variables file.

```bash
# Pre-requisite:
terraform init

# 1. Dev Deployment
terraform workspace select dev
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars" -auto-approve

# 2. Staging Deployment
terraform workspace select staging
terraform plan -var-file="staging.tfvars"
terraform apply -var-file="staging.tfvars" -auto-approve

# 3. Prod Deployment
terraform workspace select prod
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars" -auto-approve

```
<img width="1696" height="938" alt="image" src="https://github.com/user-attachments/assets/84d8973c-9fc6-4a7a-a8dd-54633c2cc592" />


### Verification Screenshots:

**AWS Console:**
<img width="2636" height="570" alt="image" src="https://github.com/user-attachments/assets/afd446f0-ac6d-4687-8333-fbae03539e4b" />

## Terminal Outputs for all three Env :**Dev, Staging, Prod**

<img width="1772" height="1176" alt="image" src="https://github.com/user-attachments/assets/5e3e3d2e-7c3a-49e9-bcbe-858ef8cd81f1" />

---

## 📜 Task 6: Terraform Best Practices Guide

* **File structure:** Separate provider configs, variables, outputs, locals, and main logic into distinct files. Keep modules focused in a `modules/` directory.
* **State management:** Always use a remote backend (like S3) for team collaboration, enable state locking (like DynamoDB) to prevent concurrent overwrites, and enable bucket versioning.
* **Variables:** Never hardcode configuration values. Use `.tfvars` per environment and validate inputs using `validation` blocks in `variables.tf`.
* **Modules:** Design modules with a single concern (e.g., networking vs. compute). Always define explicit inputs and outputs, and pin public registry module versions to avoid breaking changes.
* **Workspaces:** Use workspaces for strict environment isolation (dev/stage/prod) when the underlying codebase is identical. Reference `terraform.workspace` to dynamically name resources.
* **Security:** Maintain a strict `.gitignore` for `.tfstate` and `.tfvars` files. Encrypt state files at rest and strictly limit IAM access to the remote backend.
* **Commands:** Always run `terraform plan` to verify the blast radius before `apply`. Use `terraform fmt` and `terraform validate` to ensure clean, error-free code before committing.
* **Tagging:** Tag every resource with identifying markers like `Project`, `Environment`, and `ManagedBy = "Terraform"` for clear cost tracking and operations.
* **Naming:** Use a consistent prefix pattern: `--` (e.g., `terraweek-prod-vpc`).
* **Cleanup:** Consistently run `terraform destroy` on non-production (Dev/Staging) environments when not actively in use to eliminate idle cloud costs.

---

## 🗑️ Task 7: Destroy All Environments

To ensure a clean AWS account and prevent unexpected billing, environments are destroyed in reverse order.

```bash
# Clean up environments
terraform workspace select prod
terraform destroy -var-file="prod.tfvars" -auto-approve

terraform workspace select staging
terraform destroy -var-file="staging.tfvars" -auto-approve

terraform workspace select dev
terraform destroy -var-file="dev.tfvars" -auto-approve

# Delete the workspaces to clean up the local directory
terraform workspace select default
terraform workspace delete dev
terraform workspace delete staging
terraform workspace delete prod

```

*Verification Check: Navigating to the AWS console confirms all VPCs, Instances, and Security Groups have been successfully terminated.*

---

## 🗺️ TerraWeek Journey Recap

| Day | Concepts Mastered |
| --- | --- |
| **61** | IaC, HCL, init/plan/apply/destroy, state basics |
| **62** | Providers, resources, dependencies, lifecycle |
| **63** | Variables, outputs, data sources, locals, functions |
| **64** | Remote backend, locking, import, drift |
| **65** | Custom modules, registry modules, versioning |
| **66** | EKS with modules, real-world provisioning |
| **67** | Workspaces, multi-env, capstone project |
