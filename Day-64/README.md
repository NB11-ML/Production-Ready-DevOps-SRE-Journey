
<div align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/0/04/Terraform_Logo.svg" alt="Terraform Logo" width="100"/>
  <h1>Terraform State Management & Remote Backends</h1>
  <p><i>Day 64 of the #90DaysOfDevOps & TerraWeek Challenge</i></p>
</div>

## 🚀 Project Overview

This documentation outlines production-grade Terraform state management practices essential for Site Reliability Engineering (SRE) and DevOps environments. Moving beyond local `.tfstate` files, this configuration provisions a secure, remote AWS backend to ensure infrastructure consistency, prevent concurrent deployment conflicts, and manage legacy cloud resources.

## 🧠 Key Concepts Covered

* **Remote State Backends:** Transitioning state storage from local file systems to **Amazon S3** (`terraweek-state-nb11ml`) with versioning enabled to prevent state corruption and data loss.
* **State Locking:** Utilizing **Amazon DynamoDB** (`terraweek-state-lock` via the `LockID` primary key) to enforce atomic operations, preventing race conditions when multiple engineers or CI/CD pipelines run `terraform apply` simultaneously.
* **Resource Importing:** Leveraging `terraform import` to bring pre-existing, manually provisioned AWS infrastructure under version control without destructive recreation.
* **State Drift Management:** Detecting and reconciling unauthorized out-of-band changes (e.g., manual AWS Console modifications) using `terraform plan` and `terraform apply` to enforce the codebase as the single source of truth.

## 📋 Prerequisites

* **Terraform** (v1.0+)
* **AWS CLI** configured with appropriate IAM credentials (S3, DynamoDB, and EC2 permissions).
* An AWS account operating primarily in the `us-east-1` region.

## 🛠️ Execution Workflow

**1. Initialize the Remote Backend**
Initializes the working directory, downloads the AWS provider, and migrates any existing local state to the S3 bucket.
```bash
terraform init

```

**2. Validate and Plan**
Verifies the configuration syntax and generates an execution plan, comparing the `.tf` code against the live AWS environment to detect state drift.

```bash
terraform fmt
terraform validate
terraform plan

```

**3. Apply Configuration**
Executes the plan to provision the baseline compute infrastructure (`t3.small` on Amazon Linux 2023) or reconcile any detected drift, strictly adhering to the DynamoDB state lock.

```bash
terraform apply

```

**4. Import Legacy Infrastructure**
Brings existing, manually created AWS resources into the remote state file for centralized management.

```bash
terraform import aws_s3_bucket.imported <existing-bucket-name>

```

---
