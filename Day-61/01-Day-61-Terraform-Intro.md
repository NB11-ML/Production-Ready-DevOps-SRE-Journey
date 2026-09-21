# 🌍 Day 61: Infrastructure as Code — Introduction to Terraform & AWS

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![SRE](https://img.shields.io/badge/SRE-FF4F00?style=for-the-badge&logo=opsgenie&logoColor=white)

Welcome to Day 61 of the **Production-Ready DevOps & SRE Journey**, and Day 1 of TerraWeek! 

You have spent the last several weeks orchestrating workloads on Kubernetes. But where do the underlying servers, networks, and clusters come from? Clicking through the AWS Console manually is slow, error-prone, and impossible to track. Today, we transition to **Infrastructure as Code (IaC)** using Terraform. By the end of this module, you will provision and destroy real AWS cloud infrastructure using nothing but a `.tf` file.

---

## 📖 Task 1: Understanding Infrastructure as Code (IaC)

Before touching the terminal, it is critical to understand the philosophy behind IaC.

*   **What is IaC and why does it matter?** 
    Infrastructure as Code is the practice of managing and provisioning computing environments through machine-readable definition files rather than physical hardware configuration or interactive configuration tools. For an SRE, it matters because it brings infrastructure into the realm of software engineering—enabling version control (Git), peer reviews, auditability, and immediate disaster recovery.
*   **Manual Console vs. IaC:** 
    Clicking through a cloud console leads to "ClickOps"—configuration drift, untracked changes, and human error. IaC solves this by ensuring your infrastructure is 100% reproducible. If a region goes down, you can spin up an exact replica in minutes.
*   **How is Terraform different?**
    *   *CloudFormation:* AWS-only. Terraform is **cloud-agnostic** (works with AWS, GCP, Azure, Kubernetes, etc.).
    *   *Ansible:* Primarily a configuration management tool (procedural). Terraform is an infrastructure provisioning tool (declarative).
    *   *Pulumi:* Uses standard programming languages (Python, Go). Terraform uses its own declarative language (HCL - HashiCorp Configuration Language).
*   **"Declarative" meaning:** 
    You declare the *end state* you want (e.g., "I want 1 S3 bucket and 3 EC2 instances"). You do not write the step-by-step API scripts to create them. Terraform's engine calculates the steps needed to achieve that state.

---

## ⚙️ Task 2: Install Terraform & Configure AWS CLI

Since you are operating on a Linux VM environment, we will install the HashiCorp repository and the Terraform binary, followed by configuring the AWS CLI to allow Terraform to authenticate with your AWS account.

**1. Install Terraform (Linux):**
```bash
wget -O - [https://apt.releases.hashicorp.com/gpg](https://apt.releases.hashicorp.com/gpg) | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] [https://apt.releases.hashicorp.com](https://apt.releases.hashicorp.com) $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y
terraform -version

```

**2. Configure AWS CLI:**

```bash
aws configure
# Enter your Access Key ID
# Enter your Secret Access Key
# Default region: ap-south-1
# Default output format: json

```

**3. Verify Authentication:**

```bash
aws sts get-caller-identity

```

*(You should see your Account ID and IAM ARN returned successfully).*

---

## 🪣 Task 3: Your First Configuration (S3 Bucket)

Let's write our first HCL (HashiCorp Configuration Language) file to provision an Amazon S3 bucket.

**1. Setup the project:**

```bash
mkdir terraform-basics && cd terraform-basics
touch main.tf

```

**2. Write `main.tf`:**

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "my_bucket" {
  # MUST BE GLOBALLY UNIQUE! 
  bucket = "terraweek-sre-bucket-09212026" 
}

```

> 🚨 **SRE Troubleshooting:** If you run into a `409 BucketAlreadyExists` error during the apply phase, it means someone else on AWS has already taken your bucket name. Change the `bucket` attribute to something highly unique (e.g., append your name and the date) and try again!

**3. The Core Terraform Lifecycle:**

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

```

**Documentation Checkpoint:**

* **What did `terraform init` download?** It reached out to the HashiCorp registry and downloaded the official AWS Provider plugin required to translate HCL code into AWS API calls.
* **What is in the `.terraform/` directory?** This hidden directory stores those downloaded provider binaries and modules. (Always add this to your `.gitignore`!).

---

## 💻 Task 4: Add an EC2 Instance

Now, let's update our infrastructure to include a virtual machine.

**1. Update `main.tf` by appending this block:**

```hcl
resource "aws_instance" "app_server" {
  ami           = "ami-0f5ee92e2d63afc18" # Amazon Linux 2 (ap-south-1)
  instance_type = "t2.micro"

  tags = {
    Name = "TerraWeek-Day1"
  }
}

```

**2. Plan and Apply:**

```bash
terraform plan
terraform apply

```

*(Notice the output says `Plan: 1 to add, 0 to change, 0 to destroy`).*

**Documentation Checkpoint:**

* **How does Terraform know the S3 bucket already exists?** Terraform compares your `main.tf` file against a local database it created called the **State File**. Because the state file already has a record of the S3 bucket, Terraform knows it only needs to provision the new EC2 instance.

---

## 🧠 Task 5: Understanding the State File

The `terraform.tfstate` file is the most critical component of Terraform. It acts as the source of truth mapping your HCL code to real-world cloud resources.

**1. Run State Commands:**

```bash
terraform show
terraform state list
terraform state show aws_instance.app_server

```

**Documentation Checkpoint:**

* **What information does it store?** It stores the exact metadata, IDs (like the actual `i-0abcd1234` AWS instance ID), IP addresses, and dependency mappings of the resources it manages.
* **Why never manually edit it?** Editing the JSON manually will corrupt the tracking mechanism. Terraform will lose sync with the real AWS environment, potentially causing catastrophic deletions or duplications.
* **Why should it not be committed to Git?** The state file stores infrastructure data in **plain text**, including highly sensitive secrets like database passwords, private keys, and API tokens. Committing it exposes your cloud environment to severe security risks.

---

## 🔄 Task 6: Modify, Plan, and Destroy

Infrastructure is dynamic. Let's test modifying and decommissioning our environment.

**1. Modify:**
Change the tag in your `main.tf` from `"TerraWeek-Day1"` to `"TerraWeek-Modified"`.

**2. Plan:**

```bash
terraform plan

```

* `+` means **Create**
* `-` means **Destroy**
* `~` means **Update in-place** (Your plan should show a `~` because changing a tag does not require terminating the EC2 server).

**3. Apply the change:**

```bash
terraform apply

```

**4. The SRE Clean Up (Destroy):**
Never leave test infrastructure running. Wipe it completely clean.

```bash
terraform destroy

```

*(Type `yes`. Verify in your AWS Console that both the EC2 instance and S3 bucket are gone).*

---

### 📂 File Management Reminder

Before committing this to GitHub, ensure you create a `.gitignore` file to keep your repository clean and secure:

```text
.terraform/
*.tfstate
*.tfstate.backup

```
