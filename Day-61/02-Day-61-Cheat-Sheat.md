# 🌍 Day 61 Cheat Sheet: Terraform & IaC Basics

## ⚡ The Core Terraform Lifecycle
```bash
# 1. Initialize the working directory (downloads providers)
terraform init

# 2. Format code to HashiCorp standard spacing
terraform fmt

# 3. Validate syntax without calling cloud APIs
terraform validate

# 4. Dry-run: preview changes against current state
terraform plan

# 5. Execute the plan to provision resources
terraform apply

# 6. Tear down all managed infrastructure
terraform destroy

```

## 🔍 State Management Commands

```bash
# Human-readable output of the current state
terraform show

# List all resources tracked by Terraform
terraform state list

# View detailed attributes of a specific tracked resource
terraform state show aws_instance.app_server

```

## 🗺️ Execution Plan Symbols

When running `terraform plan`, Terraform uses diff-style symbols to indicate required actions:

* **`+` (Create):** Resource does not exist and will be provisioned.
* **`-` (Destroy):** Resource exists in state but is removed from code (or requires recreation).
* **`~` (Update in-place):** Resource exists, and attributes will be modified without destroying it.
* **`-/+` (Replace):** Resource exists but changes force a destroy-and-recreate action.

## 📄 HCL Quick Reference (AWS Provider)

```hcl
# 1. Terraform Block: Define required providers and versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 2. Provider Block: Configure cloud authentication/region
provider "aws" {
  region = "ap-south-1"
}

# 3. Resource Block: [provider_type] [local_reference_name]
resource "aws_s3_bucket" "my_bucket" {
  bucket = "terraweek-sre-bucket-09212026" # Must be globally unique!
}

resource "aws_instance" "app_server" {
  ami           = "ami-0f5ee92e2d63afc18" 
  instance_type = "t2.micro"
  tags = {
    Name = "TerraWeek-Day1"
  }
}

```

## 🚨 SRE State File Best Practices (`terraform.tfstate`)

1. **Never edit it manually:** The JSON state file maps your HCL to actual cloud IDs. Manual edits will corrupt this mapping and cause Terraform to lose track of infrastructure.
2. **Never commit it to Git:** State files contain plain-text secrets, API keys, and sensitive database passwords.
3. **Always `.gitignore` it:** Ensure `*.tfstate`, `*.tfstate.backup`, and the `.terraform/` directory are explicitly ignored in your repository.

---

## 🎤 Interview Spotlight: Declarative vs. Imperative

* **Interview Question:** *"How does Terraform differ from writing a Bash script using the AWS CLI to create an EC2 instance?"*
* **The SRE Answer:** "A Bash script is *imperative*; you must define the exact step-by-step commands to create, check, or delete the instance. Terraform is *declarative*. I simply declare the desired end-state (e.g., 'I want one t2.micro instance'). Terraform's engine automatically checks the current state, calculates the delta, and executes the necessary API calls to achieve that state. If I run an imperative script twice, I might accidentally create two instances. If I run Terraform apply twice, it recognizes the instance already exists and does nothing, making it idempotent and safer for production."

---
