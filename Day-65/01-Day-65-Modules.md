# <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/terraform/terraform-original.svg" width="30" height="30" alt="Terraform Logo" />  Day 65: Terraform Modules - Build Reusable Infrastructure

*Transitioning from Monolithic Configuration to Modular, Production-Grade Infrastructure as Code*

Welcome to Day 65 of the **#90DaysOfDevOps** and **TerraWeek** challenge! Up until now, our configurations lived inside monolithic `main.tf` files. While functional for single-server sandboxes, real-world DevOps and Site Reliability Engineering workflows demand multi-environment scalability (Dev, Staging, Prod). Copy-pasting code leads to drift, deployment friction, and maintenance nightmares.

Today, we break down monolithic code into **Terraform Modules**—reusable, parameterized, and self-contained packages of infrastructure code that function like programming functions: write once, test thoroughly, and deploy everywhere.

---

### 📂 Task 1: Module Directory Architecture & Concepts

A Terraform module is simply any directory containing a collection of `.tf` files. To establish an enterprise-standard layout, we separate custom child modules from our top-level orchestrator.

#### 1. Directory Tree Setup

```bash
# Create root directory and child module subdirectories
mkdir -p terraform-modules/modules/ec2-instance
mkdir -p terraform-modules/modules/security-group

# Navigate into the project
cd terraform-modules

# Create root-level orchestration files
touch main.tf variables.tf outputs.tf providers.tf

# Create custom EC2 child module files
touch modules/ec2-instance/main.tf modules/ec2-instance/variables.tf modules/ec2-instance/outputs.tf

# Create custom Security Group child module files
touch modules/security-group/main.tf modules/security-group/variables.tf modules/security-group/outputs.tf

```

#### 2. Project Directory Structure

```text
terraform-modules/
├── main.tf                    # Root module: orchestrates and calls child modules
├── variables.tf               # Root input variables
├── outputs.tf                 # Root outputs exposed to terminal/CI-CD
├── providers.tf               # AWS provider configuration & shared local values
└── modules/
    ├── ec2-instance/          # Child Module: Custom EC2 provisioning
    │   ├── main.tf            # Resource definition (aws_instance)
    │   ├── variables.tf       # Module input variables
    │   └── outputs.tf         # Module return values (IPs, IDs)
    └── security-group/        # Child Module: Custom Security Group provisioning
        ├── main.tf            # Resource definition with dynamic ingress
        ├── variables.tf       # Ingress port and VPC variables
        └── outputs.tf         # SG ID output for downstream consumption

```

<img width="1704" height="688" alt="image" src="https://github.com/user-attachments/assets/3fb47c1a-e1eb-420f-9445-bf485fc5d191" />


#### 🧠 Root Module vs. Child Module

* **Root Module:** The top-level working directory where the Terraform CLI commands (`terraform init`, `terraform plan`, `terraform apply`) are executed. It acts as the pipeline coordinator, passing environment-specific variables into modules and consuming their outputs.
* **Child Module:** A dedicated, self-contained sub-package of Terraform configurations located in a subfolder or external registry. It cannot run independently; it is called by a root module (or another child module) to provision a focused piece of infrastructure repeatedly.

---

### 🛠️ Task 2: Build a Custom EC2 Module

We package compute provisioning into `modules/ec2-instance/`. By exposing parameters as variables and merging tags, this module can deploy any number of instances with distinct names and roles while maintaining identical base configurations.

#### `modules/ec2-instance/variables.tf`

```hcl
variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch the instance into"
  type        = string
}

variable "security_group_ids" {
  description = "List of Security Group IDs to associate with the instance"
  type        = list(string)
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with the instance Name tag"
  type        = map(string)
  default     = {}
}

```

#### `modules/ec2-instance/main.tf`

```hcl
resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true

  tags = merge(
    var.tags,
    {
      Name = var.instance_name
    }
  )
}

```

#### `modules/ec2-instance/outputs.tf`

```hcl
output "instance_id" {
  description = "The ID of the provisioned EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "The public IPv4 address assigned to the instance"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "The private IPv4 address assigned to the instance"
  value       = aws_instance.this.private_ip
}

```

---

### 🛡️ Task 3: Build a Custom Security Group Module with Dynamic Blocks

Instead of writing repetitive `ingress` blocks for every open port, we use a Terraform `dynamic` block inside `modules/security-group/` to iterate over an array of numeric ports.

#### `modules/security-group/variables.tf`

```hcl
variable "vpc_id" {
  description = "The target VPC ID where the security group will reside"
  type        = string
}

variable "sg_name" {
  description = "Name identifier for the security group"
  type        = string
}

variable "ingress_ports" {
  description = "List of inbound TCP ports to open"
  type        = list(number)
  default     = [22, 80]
}

variable "tags" {
  description = "Tags applied to the security group"
  type        = map(string)
  default     = {}
}

```

#### `modules/security-group/main.tf`

```hcl
resource "aws_security_group" "this" {
  name        = var.sg_name
  description = "Managed dynamically via Terraform Child Module"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      description = "Allow inbound traffic on port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = var.sg_name
    }
  )
}

```

#### `modules/security-group/outputs.tf`

```hcl
output "sg_id" {
  description = "The ID of the generated security group"
  value       = aws_security_group.this.id
}

```

---

### 🌐 Tasks 4 & 5: Public Registry VPC & Root Module Orchestration

We orchestrate our infrastructure by combining the official community **AWS VPC Registry Module** with our custom child modules in the root folder.

#### `providers.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  common_tags = {
    Environment = "Dev"
    Project     = "TerraWeek"
    ManagedBy   = "Terraform"
    Challenge   = "90DaysOfDevOps"
  }
}

```

#### `main.tf` (Root Orchestrator)

```hcl
# 1. Query verified Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 2. Call Official Public Registry Module: VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "terraweek-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway   = false
  enable_dns_hostnames = true

  tags = local.common_tags
}

# 3. Call Custom Child Module: Security Group
module "web_sg" {
  source        = "./modules/security-group"
  vpc_id        = module.vpc.vpc_id
  sg_name       = "terraweek-web-sg"
  ingress_ports = [22, 80, 443]
  tags          = local.common_tags
}

# 4. Call Custom Child Module: Web EC2 Instance
module "web_server" {
  source             = "./modules/ec2-instance"
  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = "t3.small"
  subnet_id          = module.vpc.public_subnets[0]
  security_group_ids = [module.web_sg.sg_id]
  instance_name      = "terraweek-web"
  tags               = local.common_tags
}

# 5. Call Custom Child Module: API EC2 Instance (Reusing the same module)
module "api_server" {
  source             = "./modules/ec2-instance"
  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = "t3.small"
  subnet_id          = module.vpc.public_subnets[0]
  security_group_ids = [module.web_sg.sg_id]
  instance_name      = "terraweek-api"
  tags               = local.common_tags
}

```

#### `outputs.tf` (Root Outputs)

```hcl
output "vpc_id" {
  description = "The ID of the provisioned VPC"
  value       = module.vpc.vpc_id
}

output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = module.web_server.public_ip
}

output "api_server_public_ip" {
  description = "Public IP of the API server"
  value       = module.api_server.public_ip
}

```

---

### ⚙️ Execution & Lifecycle Commands

#### 1. Initialize and Download Modules

```bash
terraform init

```

<img width="1708" height="830" alt="image" src="https://github.com/user-attachments/assets/65ff49c0-5eb5-4179-8fe4-3e0ac38f73aa" />

* > Notice: Terraform creates local symbolic links for `./modules/*` and clones the registry module into the `.terraform/modules/` directory.*

#### 2. Plan and Validate

```bash
terraform validate
terraform plan

```
**Output:**

<img width="1696" height="1234" alt="image" src="https://github.com/user-attachments/assets/172ab772-44e5-4074-85f6-b6fe72203d0d" />

* > Notice how Terraform prefixes the resource with module.api_server.aws_instance.this, confirming that our custom child module is successfully being called by the root orchestrator.

#### 3. Provision Infrastructure

```bash
terraform apply -auto-approve

```

**Output**


<img width="1700" height="662" alt="image" src="https://github.com/user-attachments/assets/58204c52-cae3-4519-835b-3aed63401b62" />

* > Notice how 20 resources were provisioned in just 16 seconds! This highlights the efficiency of combining the official Terraform Registry VPC module (which handles the heavy lifting of route tables and gateways) with our custom EC2 child modules. Additionally, the root module successfully mapped and exposed the IP outputs from the isolated child modules.
---

### 🔍 Verification & Analytical Comparisons

#### 1. Verification Screenshot Placeholder

<img width="2184" height="516" alt="image" src="https://github.com/user-attachments/assets/c30e6800-6550-4d67-b194-3a9966be1b1a" />


#### 2. Where are Registry Modules Stored?

Registry modules are pulled from the internet and cached locally inside:

```bash
ls -la .terraform/modules/

```
<img width="1700" height="364" alt="image" src="https://github.com/user-attachments/assets/68385f29-2969-4e23-a49d-29a28b8c244e" />

Inside `.terraform/modules/modules.json`, Terraform keeps an index pointing each module call to its cached files on disk.

#### 3. Hand-Written VPC vs. Public Registry VPC Module

| Comparison Metric | Hand-Written VPC (Day 62) | Registry Module (`terraform-aws-modules/vpc/aws`) |
| --- | --- | --- |
| **Code Length** | ~70-100 lines of custom `.tf` code | ~15 lines in root `main.tf` |
| **Resources Created** | 4-5 resources (VPC, Subnet, IGW, Route Table) | **14+ resources** automatically configured (Route table associations, default route tables, default network ACLs, DHCP options, DNS hostnames) |
| **Production Readiness** | Requires manual handling of subnet tiers, AZ mappings, and routing loops | Implements battle-tested AWS well-architected networking standards out-of-the-box |
| **Maintenance Burden** | High; team must maintain edge cases and AWS API deprecations | Low; community and HashiCorp-maintained |

---

### 🧹 Task 6: Module State, Upgrades & Clean Up

#### 1. Inspecting Module State

When inspecting state, Terraform uses hierarchical dot notation to map resources to their module owners:

```bash
terraform state list

```

**Output:**

<img width="1700" height="928" alt="image" src="https://github.com/user-attachments/assets/3563a1b6-b2d0-4856-83bd-0e23493cec31" />

#### 2. Upgrading Module Versions

To force Terraform to check for newer versions of your registry modules and providers within your allowed version constraints, run:

```bash
terraform init -upgrade

```
Execution Output:

<img width="1676" height="598" alt="image" src="https://github.com/user-attachments/assets/646e89aa-7939-4c47-b5e5-7a76bfcde9c3" />

**What is happening under the hood:**

  * Local Modules: Terraform instantly re-verifies and links the local file paths for web_sg, api_server, and web_server.

  * Registry Modules: It checks registry.terraform.io for updates to the VPC module. Because you used the pessimistic constraint (~> 5.0), it safely downloads the newer version 5.21.0. Without the -upgrade flag, Terraform would not attempt to fetch this newer version and would simply use whatever was already cached.

  * Provider Plugins: It recalculates provider dependencies. The newly downloaded VPC module strictly requires the AWS provider to be >= 5.79.0. Terraform checks your system, sees you already have v5.100.0 installed, and confirms it satisfies all requirements without needing to download a new provider.

#### 3. Complete Resource Teardown (Avoid AWS Billing)

```bash
terraform destroy -auto-approve

```

---

### 🌟 Five Terraform Module Best Practices for DevOps & SREs

1. **Always Pin Registry Versions:** Never consume unpinned external modules. Use the pessimistic constraint operator (e.g., `version = "~> 5.0"`) to accept non-breaking bug fixes while preventing breaking major upgrades from breaking CI/CD pipelines.
2. **Adhere to the Single Responsibility Principle:** Keep child modules focused on one domain concern (e.g., one module for networking, one for compute, one for databases). Avoid monolithic "kitchen sink" modules that attempt to deploy the entire company stack in one call.
3. **Parameterize Everything, Hardcode Nothing:** Ensure child modules do not contain hardcoded values like CIDR blocks, regions, or instance sizes. Expose them through `variables.tf` with sensible defaults and strict type constraints.
4. **Define Comprehensive Outputs:** A module is only as useful as what it exposes. Always return resource IDs, ARNs, and connection strings via `outputs.tf` so upstream modules can dynamically bind to them without hardcoded references.
5. **Treat Modules as Standalone Software Products:** Every custom module should contain a clear `README.md` defining inputs, outputs, prerequisites, and a copy-pasteable usage example. Version-tag internal modules in private Git repositories using semantic tags (e.g., `?ref=v1.2.0`).

---
