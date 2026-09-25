# <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/terraform/terraform-original.svg" width="30" height="30" alt="Terraform Logo" />  Day 65: Terraform Modules - Building Reusable Infrastructure

This directory contains the configurations for Day 65 of the #90DaysOfDevOps and TerraWeek challenges, part of the larger `Production-Ready-DevOps-SRE-Journey` repository.

Today's focus is transitioning from monolithic, single-file Terraform configurations into scalable, production-ready **Terraform Modules**.

## 📌 Project Overview

Instead of writing repetitive code for every environment, this project demonstrates how to package infrastructure into reusable child modules. We built custom modules from scratch and integrated them with official public registry modules to provision a fully functional AWS networking and compute stack.

### Key Concepts Applied:

* **Root vs. Child Modules:** Orchestrating deployments from a root directory while keeping resource definitions isolated in child modules.
* **Public Registry Modules:** Leveraging the official `terraform-aws-modules/vpc/aws` to automatically provision a robust, well-architected VPC.
* **Dynamic Blocks:** Using the `dynamic "ingress"` block to iterate over a list of allowed ports to keep security group definitions DRY (Don't Repeat Yourself).
* **Module Outputs:** Passing generated IDs and IPs from child modules back to the root orchestrator.
* **Version Constraints:** Explicitly pinning module versions (e.g., `version = "~> 5.0"`) to prevent breaking changes.

---

## 📂 Directory Structure

```text
terraform-modules/
├── main.tf                    # Root orchestrator calling local & registry modules
├── variables.tf               # Root input variables placeholder
├── outputs.tf                 # Extracts IPs and IDs from child modules
├── providers.tf               # AWS provider configuration and shared locals
└── modules/
    ├── ec2-instance/          # Custom Compute Module
    │   ├── main.tf            
    │   ├── variables.tf       
    │   └── outputs.tf         
    └── security-group/        # Custom Networking/Firewall Module
        ├── main.tf            
        ├── variables.tf       
        └── outputs.tf         

```

---

## 🛠️ Usage Instructions

**1. Clone the repository and navigate to the directory:**

```bash
git clone https://github.com/NB11-ML/Production-Ready-DevOps-SRE-Journey.git
cd Production-Ready-DevOps-SRE-Journey/2026/day-65/terraform-modules

```

**2. Initialize the project:**
Downloads the official VPC registry module into `.terraform/modules/` and creates symlinks for the custom local modules.

```bash
terraform init

```

*(Note: If updating module versions, run `terraform init -upgrade`)*

**3. Preview the infrastructure changes:**

```bash
terraform validate
terraform plan

```

**4. Deploy the infrastructure:**

```bash
terraform apply -auto-approve

```

**5. Clean up to prevent AWS charges:**

```bash
terraform destroy -auto-approve

```

---

## 🌟 SRE & DevOps Best Practices Implemented

1. **Never Hardcode Infrastructure:** Passed dynamic values like AMI IDs, instance types, and subnets via `variables.tf`.
2. **Single Responsibility:** Kept compute (`ec2-instance`) and networking (`security-group`) logically separated.
3. **Immutable Tagging:** Used the `merge()` function to append standard project tags onto dynamically generated instance names.
4. **Security-First Output Handling:** Verified outputs in the terminal but ensured all public IPs were redacted before sharing execution proofs.
