# 🌍 Day 63: Terraform Variables, Outputs, Data Sources, and Expressions

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)

This module focuses on transforming static, hardcoded AWS infrastructure into dynamic, environment-aware, and reusable Terraform configurations. By parameterizing the environment and utilizing data sources, this codebase can be seamlessly deployed across Development, Staging, or Production environments.

## 🎯 Objectives
* **Extract Hardcoded Values:** Move fixed strings and numbers into `variables.tf` utilizing types like strings, numbers, lists, and maps.
* **Environment Parameterization:** Implement `terraform.tfvars` (Dev) and `prod.tfvars` (Prod) to demonstrate variable precedence and multi-environment deployments.
* **Dynamic Queries:** Replace static AMI IDs and Availability Zones with dynamic Terraform `data` sources.
* **Consistent Tagging:** Utilize `locals` and the `merge()` function to enforce a standardized naming convention across all resources.
* **Conditional Logic:** Apply ternary operators to dynamically scale compute resources based on the target environment (e.g., `t2.micro` for Dev vs `t3.small` for Prod).
* **Resource Visibility:** Map critical infrastructure details to terminal outputs using `outputs.tf`.

## 📂 Project Structure


```text
📦 day-63
 ┣ 📂 manifest                       # Directory containing the core Terraform configuration files (main.tf, variables.tf, outputs.tf, etc.)[cite: 2]
 ┣ 📜 .gitignore                     # Git ignore file to prevent committing local state and secrets[cite: 2]
 ┣ 📜 01-Day-63-variables-Outputs.md # Detailed execution guide and task breakdown[cite: 2]
 ┣ 📜 02-Day-63-Cheat-Sheat.md       # Cheat sheet for Terraform variables, data sources, and expressions[cite: 2]
 ┗ 📜 README.md                      # Master project documentation and overview[cite: 2]

```

## 🚀 Execution Guide

### 1. Initialize the Workspace

Download the required AWS provider plugins.

```bash
terraform init

```

### 2. Plan the Environments

Test the configuration against different environment variables. Terraform strict precedence rules apply here.

**Development Environment (Default):**

```bash
terraform plan

```

**Production Environment (Override):**

```bash
terraform plan -var-file="prod.tfvars"

```

### 3. Deploy the Infrastructure

Apply the configuration. This will provision the AWS VPC, Subnet, Internet Gateway, Route Tables, Security Group, and EC2 instance.

```bash
terraform apply -auto-approve

```

### 4. Verify Outputs

Once the deployment succeeds, retrieve the dynamic infrastructure attributes.

```bash
terraform output
terraform output instance_public_ip
terraform output -json

```

### 5. Clean Up

Destroy all resources to prevent ongoing AWS billing charges.

```bash
terraform destroy -auto-approve

```

## 🧠 Key Concepts Explored

| Concept | Purpose | Implementation in this Module |
| --- | --- | --- |
| **Variables** | Accepts input to customize the module. | `vpc_cidr`, `instance_type`, `allowed_ports` |
| **Locals** | Internal expressions evaluated once for reuse. | `name_prefix` and `common_tags` |
| **Outputs** | Exposes resource attributes to the terminal. | `instance_public_ip`, `vpc_id` |
| **Data Sources** | Queries read-only data from AWS API. | `aws_ami`, `aws_availability_zones` |
| **Expressions** | Conditional logic and functions. | `var.environment == "prod" ? "t3.small" : "t2.micro"` |

---
