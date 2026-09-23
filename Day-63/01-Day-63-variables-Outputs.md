# 🌍 Day 63: Variables, Outputs, Data Sources, and Expressions

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)

Today focuses on transforming static, hardcoded infrastructure into dynamic, environment-aware, and reusable configurations. By parameterizing the environment, we can deploy to Development, Staging, or Production using the exact same codebase.

---

## 🛠️ Task 1: Extract Variables

Hardcoded values create rigid infrastructure. We extracted all fixed values into `variables.tf` and updated `main.tf` to reference them using `var.<name>`.

### `variables.tf`
```hcl
variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t2.micro"
}

variable "project_name" {
  description = "Name of the project (Required)"
  type        = string
  # No default - forces user input
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "allowed_ports" {
  description = "List of allowed ingress ports"
  type        = list(number)
  default     = [22, 80, 443]
}

variable "extra_tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

```

### 📝 The Five Variable Types in Terraform

* **string**: A sequence of characters (e.g., `"t2.micro"`).
* **number**: Numeric values (e.g., `80`, `10`).
* **bool**: Boolean values representing true/false.
* **list**: An ordered sequence of values of the same type (e.g., `["us-east-1a", "us-east-1b"]`).
* **map**: A collection of key-value pairs (e.g., `{ Environment = "dev", Team = "backend" }`).

### 📝 What to change in `main.tf` (Replacing Hardcoded Values)

You need to replace the raw CIDR strings with references to the variables you defined in `variables.tf`. For the Security Group, to use the `var.allowed_ports` list, you must use a `dynamic` block to loop through the ports.

```hcl
# ❌ BEFORE (Day 62)
resource "aws_vpc" "terraformvpc" {
  cidr_block = "10.0.0.0/16"
}

# ✅ AFTER (Day 63)
resource "aws_vpc" "terraformvpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "terraformsubnet" {
  vpc_id                  = aws_vpc.terraformvpc.id
  cidr_block              = var.subnet_cidr
  # ...
}

# Dynamic Block for Security Group Ingress
  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

```

### 💻 Execution: Testing the Missing Variable Prompt

Before you create your `.tfvars` files, run a plan. Because `project_name` has no default value, Terraform will stop and force you to enter it interactively.

```bash
terraform plan
# Terraform will prompt: 
# var.project_name
#   Name of the project (Required)
#   Enter a value: 

```
#### Project Name and Ec2 instance Type:

<img width="849" height="761" alt="Day-63-Task-1" src="https://github.com/user-attachments/assets/df216d73-4cc0-4d07-a11d-62c149dc9cd2" />

#### Ingress Ports:

<img width="1686" height="1696" alt="image" src="https://github.com/user-attachments/assets/17467b16-4508-4543-8698-361901246852" />

#### Subnet and VPC CIDR:

<img width="1692" height="1608" alt="image" src="https://github.com/user-attachments/assets/80507591-1702-46f1-8d0e-56b72cb06b0f" />


---

## 🏗️ Task 2: Variable Files and Precedence

We created separate variable definitions to manage different environments seamlessly.

### `terraform.tfvars` (Default / Dev Environment)

```hcl
project_name  = "terraweek"
environment   = "dev"
instance_type = "t2.micro"

```

### `prod.tfvars` (Production Environment)

```hcl
project_name  = "terraweek"
environment   = "prod"
instance_type = "t3.small"
vpc_cidr      = "10.1.0.0/16"
subnet_cidr   = "10.1.1.0/24"

```

### ⚖️ Variable Precedence (Lowest to Highest Priority)

If a variable is defined in multiple places, Terraform applies this strict override order:

1. **Environment Variables** (`TF_VAR_environment="staging"`)
2. **`terraform.tfvars`** (Loaded automatically)
3. **`*.auto.tfvars`** (Loaded automatically)
4. **`-var-file` Flag** (`terraform plan -var-file="prod.tfvars"`)
5. **`-var` CLI Flag** (`terraform plan -var="instance_type=t2.nano"`) *(Highest priority)*

### 💻 Execution: Testing Variable Precedence & Environments

Test how Terraform switches environments and changes configurations dynamically based on the file or flag provided.

```bash
# 1. Run the Default (Dev) Environment 
# Automatically uses terraform.tfvars. Deploys a t2.micro.
terraform plan 

# 2. Run the Production Environment
# Forces Terraform to use prod.tfvars. Notice the instance changes to t3.small!
terraform plan -var-file="prod.tfvars"

# 3. Test CLI Override (Highest Priority)
# Overrides both files and forces a nano instance.
terraform plan -var="instance_type=t2.nano"

```
**terraform plan : Automatically uses terraform.tfvars.** 

**Deploys a t2.micro.**
<img width="1706" height="1362" alt="image" src="https://github.com/user-attachments/assets/b73e8769-01a9-4153-b46c-9ffd8f516026" />

**terraform plan -var-file="prod.tfvars" : Forces Terraform to use prod.tfvars.**

**Notice the instance changes to t3.small!**
<img width="1696" height="1376" alt="image" src="https://github.com/user-attachments/assets/86c77007-c934-4de4-9660-348c40909afb" />
<img width="1690" height="1386" alt="image" src="https://github.com/user-attachments/assets/8960989a-3174-4026-a9f2-97c028997596" />

**terraform plan -var="instance_type=t2.nano" : Overrides both files and forces a nano instance.**

<img width="1692" height="1362" alt="image" src="https://github.com/user-attachments/assets/36e3ab0d-a5f6-4a86-93a0-30e9ab1c85da" />


---

## 📤 Task 3: Add Outputs

Instead of logging into the AWS Console to find IP addresses, we use `outputs.tf` to print critical infrastructure details to the terminal.

### `outputs.tf`

```hcl
output "vpc_id" {
  value = aws_vpc.terraformvpc.id
}

output "subnet_id" {
  value = aws_subnet.terraformsubnet.id
}

output "instance_id" {
  value = aws_instance.terraformec2.id
}

output "instance_public_ip" {
  value = aws_instance.terraformec2.public_ip
}

output "instance_public_dns" {
  value = aws_instance.terraformec2.public_dns
}

output "security_group_id" {
  value = aws_security_group.terraformsg.id
}

```

### 💻 Execution: Applying and Verifying Outputs

Apply the configuration and verify the outputs are printed at the end of the run.

```bash
terraform apply -auto-approve

# Verify your outputs printed to the screen, then test these commands:
terraform output                          # Shows all outputs
terraform output instance_public_ip       # Shows just the IP
terraform output -json                    # Great for CI/CD scripting!

```
**terraform apply**
<img width="1704" height="488" alt="image" src="https://github.com/user-attachments/assets/c40ac9a3-0244-4384-8983-a2d4c0448b0f" />

**terraform output's**
<img width="1698" height="442" alt="image" src="https://github.com/user-attachments/assets/ddbbc63c-5f32-4472-9cdb-9bfbe0e0e87c" />
<img width="1692" height="1308" alt="image" src="https://github.com/user-attachments/assets/9f7c668f-453b-48bd-b4dc-1455cedb483a" />

---

## 📡 Task 4: Data Sources vs. Resources

Hardcoding AMIs causes deployment failures when switching regions. We use a **Data Source** to dynamically query AWS for the latest Amazon Linux 2 AMI and available Availability Zones.

### 🔍 Resource vs. Data Source

* **Resource (`resource`)**: Creates, updates, or deletes infrastructure (e.g., building an EC2 instance).
* **Data Source (`data`)**: Performs read-only queries against existing infrastructure or APIs. It fetches information but never modifies it.

### 📝 What to change in `main.tf` (Dynamic AMIs & AZs)

Remove the hardcoded `ami` ID and the hardcoded `us-east-1a` availability zone. Add the `data` blocks at the top of your file to fetch these automatically.

```hcl
# Add these at the top of main.tf
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
}

data "aws_availability_zones" "available" {}

# ❌ BEFORE (Day 62)
resource "aws_instance" "terraformec2" {
  ami               = "ami-0fef201115eefe936"
  availability_zone = "us-east-1a"
}

# ✅ AFTER (Day 63)
resource "aws_instance" "terraformec2" {
  ami               = data.aws_ami.amazon_linux.id
  availability_zone = data.aws_availability_zones.available.names[0]
}

```

---

## 🧩 Task 5: Locals for Dynamic Tagging

`locals` allow us to evaluate expressions once and reuse them globally, enforcing naming conventions and consistent tagging.

### 📝 What to change in `main.tf` (Consistent Tagging)

Add a `locals` block at the top of the file to establish a consistent naming convention. Then, wrap all of your `tags = {}` blocks in the `merge()` function to combine your standard tags with the specific resource names.

```hcl
# Add this at the top of main.tf
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ❌ BEFORE (Day 62)
tags = {
  Name = "TerraWeek-VPC"
}

# ✅ AFTER (Day 63)
tags = merge(local.common_tags, {
  Name = "${local.name_prefix}-vpc"
})

```

<img width="1690" height="1102" alt="image" src="https://github.com/user-attachments/assets/d75bca2a-ad9a-44d3-b820-9bcc45f9405f" />
<img width="1688" height="518" alt="image" src="https://github.com/user-attachments/assets/9ea7648c-7b8c-453b-8ca0-11204b033f74" />

---

## 🧮 Task 6: Conditional Expressions and Built-in Functions

Terraform includes built-in functions to manipulate strings, arrays, and networks dynamically. We also implemented a conditional expression for our instance type.

### 🛠️ 5 Most Useful Terraform Functions

1. **`merge(map1, map2)`**: Combines multiple maps into a single map. Invaluable for merging standard organizational tags with resource-specific tags.
2. **`lookup(map, key, default)`**: Retrieves the value of a single element from a map. If the key isn't found, it returns the fallback default value.
3. **`length(list/string)`**: Determines the number of items in a list or the number of characters in a string. Crucial for looping with `count`.
4. **`cidrsubnet(prefix, newbits, netnum)`**: Calculates a subnet CIDR block dynamically from a base VPC CIDR, removing the need to manually calculate IP math.
5. **`join(separator, list)`**: Combines a list of strings into a single string, separated by a delimiter (e.g., joining an array of names with a hyphen).

### 📝 What to change in `main.tf` (Conditional Expressions)

Modify the `instance_type` inside your `aws_instance` block to use a ternary operator (`condition ? true_val : false_val`) instead of a static variable.

```hcl
# ❌ BEFORE (Day 62)
instance_type = var.instance_type

# ✅ AFTER (Day 63)
# If environment is prod, deploy t3.small, otherwise default to t2.micro
instance_type = var.environment == "prod" ? "t3.small" : "t2.micro"

```

<img width="851" height="575" alt="Screenshot 2026-09-23 at 17 28 40" src="https://github.com/user-attachments/assets/bbad4276-6916-4f0f-9159-58f720256663" />


### 💻 Execution: Practicing Built-in Functions in the Console

Use the interactive shell to test functions without deploying anything.

```bash
terraform console

# Try typing these directly into the console prompt:
> upper("terraweek")
# "TERRAWEEK"

> join("-", ["terra", "week", "2026"])
# "terra-week-2026"

> length(["a", "b", "c"])
# 3

> exit

```

<img width="1696" height="522" alt="image" src="https://github.com/user-attachments/assets/5cbeef1b-566a-4714-ad1c-f378f7c65c7c" />


---

## 🚀 The Final Refactored `main.tf`

Here is the complete configuration reflecting all changes across the Day 63 tasks.

```hcl
# ==========================================
# Data Sources & Locals
# ==========================================
data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ==========================================
# Networking Infrastructure
# ==========================================
resource "aws_vpc" "terraformvpc" {
  cidr_block = var.vpc_cidr
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_subnet" "terraformsubnet" {
  vpc_id                  = aws_vpc.terraformvpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet"
  })
}

resource "aws_internet_gateway" "terraformgateway" {
  vpc_id = aws_vpc.terraformvpc.id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_route_table" "terraformroute" {
  vpc_id = aws_vpc.terraformvpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraformgateway.id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rtb"
  })
}

resource "aws_route_table_association" "terraform_route_table" {
  route_table_id = aws_route_table.terraformroute.id
  subnet_id      = aws_subnet.terraformsubnet.id
}

# ==========================================
# Security & Compute
# ==========================================
resource "aws_security_group" "terraformsg" {
  name        = "${local.name_prefix}-sg"
  description = "Controls ingress and egress ports"
  vpc_id      = aws_vpc.terraformvpc.id

  # Dynamic block to loop through var.allowed_ports list
  dynamic "ingress" {
    for_each = var.allowed_ports
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

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg"
  })
}

resource "aws_instance" "terraformec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.environment == "prod" ? "t3.small" : "t2.micro"
  subnet_id                   = aws_subnet.terraformsubnet.id
  vpc_security_group_ids      = [aws_security_group.terraformsg.id]
  associate_public_ip_address = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-server"
  })
}

```

### 🧹 Final Cleanup

Once all verification steps are complete, destroy the infrastructure to avoid AWS charges.

```bash
terraform destroy -auto-approve

```
