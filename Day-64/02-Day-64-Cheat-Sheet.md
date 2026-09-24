
<div align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/0/04/Terraform_Logo.svg" alt="Terraform Logo" width="80"/>
  <h1>🚀 Day 64 Cheat Sheet: Terraform State & Drift Management</h1>
  <p><i>Mastering Remote Backends, State Locking, and Infrastructure Consistency</i></p>
</div>

### 🔐 1. Remote Backend Architecture
In a team environment, storing `terraform.tfstate` locally leads to corruption and conflicts. We solve this by moving state to the cloud.

* **AWS S3 (Storage):** Acts as the centralized vault for the `.tfstate` file. 
  * *Critical Config:* **Versioning must be enabled** to recover from accidental state deletion or corruption.
* **Amazon DynamoDB (State Locking):** Prevents race conditions. If Engineer A and Engineer B run `terraform apply` simultaneously, DynamoDB grants a lock to the first request and blocks the second with a `ConditionalCheckFailedException`. 
  * *Critical Config:* The table must have a primary key strictly named **`LockID`**.

### 💻 2. Core State CLI Commands
| Command | SRE / DevOps Use Case |
| :--- | :--- |
| `terraform init` | Run this when configuring or migrating to a new S3 backend. It downloads providers and copies local state to the cloud. |
| `terraform plan` | Compares the `.tf` code against the real-world cloud environment. **Used for Drift Detection.** |
| `terraform apply` | Executes the plan. **Used for Reconciling Drift** (forcing AWS back to the coded configuration). |
| `terraform state list` | Outputs a list of all resources Terraform is actively tracking in the state file. |
| `terraform state show <resource>` | Displays the exact metadata and attributes of a specific tracked resource. |

### 🕵️ 3. Managing Infrastructure Drift
Drift occurs when resources are manually modified (e.g., via the AWS Management Console) outside of the automated Terraform workflow.

* **Detect Drift:** Run `terraform plan`. Look for the `~` symbol (update in-place), which flags that Terraform caught the unauthorized manual change and wants to revert it.
* **Fix Drift:** Run `terraform apply` to overwrite the manual GUI changes, enforcing the `.tf` configuration as the single source of truth.
* **Prevent Drift:** 
  1. Restrict engineering access to **read-only** in the AWS Console via IAM.
  2. Restrict provisioning power exclusively to the **CI/CD pipeline**.

### 🏗️ 4. Importing Legacy Infrastructure
Used when infrastructure was created manually *before* Terraform was introduced, and you need to bring it under version control without destroying it.

1. **Placeholder:** Create an empty resource block in `main.tf` (e.g., `resource "aws_s3_bucket" "imported" {}`).
2. **Execute Import:** Run `terraform import aws_s3_bucket.imported <actual_aws_bucket_name>`.
3. **Verify:** Run `terraform plan` to ensure Terraform successfully downloaded the resource metadata and linked it to your state file.
