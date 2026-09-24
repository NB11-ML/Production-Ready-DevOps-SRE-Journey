# <img src="https://upload.wikimedia.org/wikipedia/commons/0/04/Terraform_Logo.svg" width="24" height="24" align="absmiddle" /> Day 64: Terraform State Management and Remote Backends

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white) ![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)

The state file (`terraform.tfstate`) is the single most important component in Terraform. It acts as the source of truth, mapping your `.tf` configuration files to the actual resources provisioned in the cloud. Today focuses on managing state securely and professionally—moving from local state to a secure remote backend, locking state to prevent team conflicts, importing existing resources, and handling state drift.

---

### 🛠️ Task 1: Inspect Your Current State

Before moving to a remote backend, it is crucial to understand what Terraform is currently tracking locally. We applied our baseline configuration and explored the state.

**Execution Commands**
```bash
terraform show                                    # Displays full state in a human-readable format
terraform state list                              # Lists all resources currently tracked
terraform state show aws_instance.terraformec2    # Displays every attribute of the specific instance
terraform state show aws_vpc.terraformvpc         # Displays every attribute of the specific VPC

```

<img width="1686" height="1152" alt="image" src="https://github.com/user-attachments/assets/ac2e5681-6f5c-43b5-9a89-7966abe9de3f" />
<img width="1686" height="1236" alt="image" src="https://github.com/user-attachments/assets/2d1899a0-3cf9-47bf-a50b-e14fc4e41313" />
<img width="1706" height="1166" alt="image" src="https://github.com/user-attachments/assets/7f7220b7-7b03-4230-8e57-aabd59fb3297" />


**Observations & Answers**

* **How many resources does Terraform track?** Terraform tracks 8 resources based on our previous module (VPC, Subnet, IGW, Route Table, Route Table Association, Security Group, EC2 Instance, and the EC2 running state).
* **What attributes does the state store for an EC2 instance?** The state stores significantly more than what is defined in the `.tf` file, including AWS-assigned data such as `arn`, `public_ip`, `private_ip`, `mac_address`, `cpu_core_count`, and `security_groups`.
* **What does the `serial` number represent?** Found inside `terraform.tfstate`, the `serial` number is an integer that increments with every state modification. It prevents older state files from accidentally overwriting newer ones.

---

### 🛠️ Task 2: Setting Up Remote State Management (S3 & DynamoDB)

To securely store our Terraform state file and prevent concurrent modification conflicts, we need to configure a remote backend using AWS S3 for storage and DynamoDB for state locking.

Here are the exact AWS CLI commands used to provision this infrastructure.

#### 1. Create the S3 Bucket

We created a globally unique S3 bucket to store the `terraform.tfstate` file.

> **Note on `us-east-1` Routing:** When creating a bucket in the `us-east-1` (N. Virginia) region via the AWS CLI, you must omit the `--create-bucket-configuration LocationConstraint` parameter. Passing a location constraint for `us-east-1` will result in an `InvalidLocationConstraint` error, as it is the legacy default region for the S3 API.

```bash
aws s3api create-bucket \
  --bucket terraweek-state-nb11ml \
  --region us-east-1

```

#### 2. Enable Bucket Versioning

Versioning is critical for state files. If the state file is ever corrupted or accidentally deleted, versioning allows us to roll back to a previous, stable state.

```bash
aws s3api put-bucket-versioning \
  --bucket terraweek-state-nb11ml \
  --versioning-configuration Status=Enabled

```

#### 3. Create the DynamoDB Table for State Locking

To prevent multiple team members (or automated CI/CD pipelines) from running `terraform apply` at the exact same time and corrupting the state file, we use a DynamoDB table to handle state locking. Terraform requires the primary key to be named `LockID`.

```bash
aws dynamodb create-table \
  --table-name terraweek-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

```

*(Note: When the AWS CLI outputs the table creation confirmation, it may open in a pager. Simply press `q` to exit back to the terminal prompt).*

---

<img width="1666" height="1160" alt="image" src="https://github.com/user-attachments/assets/3354617a-d05f-42e9-a2dd-1f2b48adbc9e" />


**main.tf (Backend Block)**

```hcl
terraform {
  backend "s3" {
    bucket         = "terraweek-state-nb11ml"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraweek-state-lock"
    encrypt        = true
  }
}

```

**2. Migrate the State**

```bash
terraform init

```

<img width="1694" height="1246" alt="image" src="https://github.com/user-attachments/assets/068ab0e4-83f1-444d-b635-b7f059b4e410" />


*Terraform prompts: "Do you want to copy existing state to the new backend?" — Typed `yes`. Local `terraform.tfstate` is now empty, and running `terraform plan` shows no changes.*

<img width="1716" height="1956" alt="image" src="https://github.com/user-attachments/assets/6f98830d-78c0-417e-b729-86a617b4a3cf" />

---
### 🛠️ Task 3: Test State Locking

State locking prevents two engineers from running `terraform apply` simultaneously, which would corrupt the state file. We simulated this using two terminal windows.

**Execution Commands**

```bash
# Terminal 1:
terraform apply

# Terminal 2 (Run while Terminal 1 is waiting for confirmation):
terraform plan

```

**Only terraform apply :**
<img width="851" height="707" alt="Screenshot 2026-09-24 at 18 33 57" src="https://github.com/user-attachments/assets/2d54c907-f4df-4107-a6e2-15d220e8044c" />

**Terraform apply and terraform plan at same time:**
<img width="3398" height="1406" alt="image" src="https://github.com/user-attachments/assets/1c4897a5-ddd6-4b25-a53a-ed95b90572fc" />


**Observations & Answers**

* **Error Message:** Terminal 2 threw an `Error acquiring the state lock` message, referencing a `ConditionalCheckFailedException` from DynamoDB and displaying a specific `Lock ID`.
* **Why is locking critical?** In team environments, concurrent writes to the state file can lead to race conditions, orphaned cloud resources, or complete state corruption. DynamoDB ensures atomic operations (only one process holds the lock at a time).

---
### 🛠️ Task 4: Import an Existing Resource

Often, infrastructure exists in AWS before Terraform is introduced (for example, if a developer manually created a resource via the AWS Console). In a real-world SRE scenario, we need to bring these "rogue" resources under version control. We simulated this by creating a bucket manually via the AWS CLI and using `terraform import` to adopt it without destroying it.

**1. Simulate Manual Creation (AWS CLI)**
First, we created a bucket directly in AWS, bypassing Terraform entirely:
```bash
aws s3api create-bucket \
  --bucket terraweek-import-state-nb11ml \
  --region us-east-1

```

**2. Update Configuration (`main.tf`)**
We added an empty resource block to act as the placeholder for our existing bucket:

```hcl
resource "aws_s3_bucket" "imported" {
  bucket = "terraweek-import-state-nb11ml"
}

```

**3. Execution Commands**
We mapped the live AWS resource to the logical code in our state file, then ran a plan to verify they were perfectly synced.

```bash
# Import the manually created bucket into the state file
terraform import aws_s3_bucket.imported terraweek-import-state-nb11ml

# Verify the import matches the configuration
terraform plan

```

**terraform import:**

<img width="1700" height="1518" alt="image" src="https://github.com/user-attachments/assets/498c73ff-0289-4cab-b4ee-0797bd494aba" />

**terraform plan:**

<img width="1690" height="1088" alt="image" src="https://github.com/user-attachments/assets/f0a198e1-e12f-48aa-a72e-0296ace76088" />

**Observations & Answers**

* **Difference between Import and Creating from Scratch:** Creating from scratch tells Terraform to hit the AWS API to provision a net-new resource. `terraform import` merely downloads the metadata of an existing AWS resource and maps it to a logical name in your state file without creating or modifying the cloud resource.

---

### 🛠️ Task 5: State Surgery — mv and rm

State surgery commands manipulate the state file directly without impacting the real-world AWS infrastructure.

**Execution Commands**

```bash
# 1. Renaming a Resource (State Move)
terraform state mv aws_s3_bucket.imported aws_s3_bucket.logs_bucket

# 2. Removing a Resource (State Remove)
terraform state rm aws_s3_bucket.logs_bucket

```
<img width="1714" height="1040" alt="image" src="https://github.com/user-attachments/assets/89565f55-5e77-40a3-87ae-3d97114efd83" />
<img width="2180" height="744" alt="image" src="https://github.com/user-attachments/assets/78808afe-8e07-4f5e-93ba-b1f897aeb1fd" />

**Observations & Answers**

* **When to use `state mv`:** Used for refactoring code. If you rename a module or resource block in your `.tf` file, Terraform defaults to destroying the old resource and recreating the new one. `state mv` updates the mapping, preventing production downtime.
* **When to use `state rm`:** Used when you want Terraform to stop managing a resource, but you want the resource to remain active in AWS (e.g., passing control of a database to another team's Terraform workspace).

---

### 🛠️ Task 6: Simulate and Fix State Drift

State drift occurs when infrastructure is modified manually (e.g., via the AWS Console) outside of the Terraform workflow.

**Execution Workflow**

1. Applied the full Terraform configuration to ensure the state was synced.
2. **Simulated Drift:** Manually changed the `Name` tag of the EC2 instance to `ManuallyChanged` via the AWS Console.
3. **Detected Drift:** Ran a plan. Terraform automatically refreshed the state, detected the out-of-band change, and flagged it for correction.

```bash
terraform plan
# Output displays an '~ update in-place' indicating it will revert the tag

```
<img width="2832" height="830" alt="image" src="https://github.com/user-attachments/assets/3665b9da-739c-4d6e-a864-397e91f0b921" />
<img width="1710" height="1522" alt="image" src="https://github.com/user-attachments/assets/d1185f5c-e166-471d-b107-cf3b68d63f17" />


4. **Reconciled Drift:** Ran an apply to overwrite the manual console change and force the real-world infrastructure back to strictly match the `.tf` configuration code.

```bash
terraform apply -auto-approve

```

<img width="1552" height="176" alt="image" src="https://github.com/user-attachments/assets/4a192246-5ac3-4760-92e4-4397185691ba" />
<img width="2828" height="460" alt="image" src="https://github.com/user-attachments/assets/c922f07e-c1d7-46b0-9e91-d1b56aec1c2b" />


**Observations & Answers**

* **How do teams prevent state drift in production?**
* **IAM Restrictions:** Restrict engineering access to read-only permissions in the AWS Management Console.
* **CI/CD Exclusivity:** Ensure that only the automated CI/CD pipeline has the IAM roles required to provision or modify infrastructure.
* **Drift Detection:** Run scheduled `terraform plan` pipelines nightly to detect and alert on unauthorized manual changes.



---
