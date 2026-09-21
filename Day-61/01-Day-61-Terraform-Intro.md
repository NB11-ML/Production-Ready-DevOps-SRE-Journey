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

<img width="1784" height="388" alt="image" src="https://github.com/user-attachments/assets/358e8d3e-d18c-4f8d-9f1c-d4d124ef7c00" />


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
  region = "us-east-1"
}

resource "aws_s3_bucket" "terrabucket" {
  # MUST BE GLOBALLY UNIQUE! 
  bucket = "terrabucketdev" 
}

```
**terraform initialization:**

<img width="1790" height="568" alt="image" src="https://github.com/user-attachments/assets/46d888bd-c46b-4a8d-9148-a3a6fde6bae8" />


**terraform plan:**

<img width="1798" height="1092" alt="image" src="https://github.com/user-attachments/assets/a3e079e9-9308-4ea2-b495-69332ff2c88a" />

**terraform apply:**

<img width="1804" height="584" alt="image" src="https://github.com/user-attachments/assets/bfb5a284-eb7b-4860-bf04-6ba29ecda5b6" />

**Aws S3 Bucket (Web Console):**

<img width="1800" height="678" alt="image" src="https://github.com/user-attachments/assets/4d6f7685-cbaa-471e-a21b-abcda9642297" />

> 🚨**SRE Troubleshooting:** If you run into a `409 BucketAlreadyExists` error during the apply phase, it means someone else on AWS has already taken your bucket name. Change the `bucket` attribute to something highly unique (e.g., append your name and the date) and try again!

<img width="2338" height="284" alt="image" src="https://github.com/user-attachments/assets/67f7b786-d1e1-47c8-920e-d337982ebfa4" />

**3. The Core Terraform Lifecycle:**
Execute these commands in sequence to format, validate, and build your infrastructure:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

```

* **`terraform init`**: Initializes the project workspace and downloads the necessary AWS provider plugins into a hidden `.terraform/` directory.
* **`terraform fmt`**: Automatically formats your HCL code to standardize spacing and indentation (a strict DevOps best practice before committing to Git).
* **`terraform validate`**: Scans your `.tf` files for syntax errors and configuration validity locally, without attempting to connect to AWS.
* **`terraform plan`**: Performs a dry run. It compares your code against the existing state and outputs a detailed blueprint of exactly what will be created, updated, or destroyed.
* **`terraform apply`**: Executes the blueprint and physically provisions the resources in your AWS account (requires a manual `yes` confirmation).


**Documentation Checkpoint:**

* **What did `terraform init` download?** It reached out to the HashiCorp registry and downloaded the official AWS Provider plugin required to translate HCL code into AWS API calls.
* **What is in the `.terraform/` directory?** This hidden directory stores those downloaded provider binaries and modules. (Always add this to your `.gitignore`!).

---

## 💻 Task 4: Add an EC2 Instance

Now, let's update our infrastructure to include a virtual machine.

**1. Update `main.tf` by appending this block:**

```hcl
resource "aws_instance" "terraec2" {
    ami = "ami-0fef201115eefe936"
    instance_type = "t3.micro"
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
**terraform plan:**
<img width="1834" height="1164" alt="image" src="https://github.com/user-attachments/assets/8ea5cbdb-d16a-4e19-a4fd-b174073496aa" />
<img width="1822" height="428" alt="image" src="https://github.com/user-attachments/assets/ede73f69-7635-46f9-9182-d4ba519445c8" />

**terraform apply:**

<img width="1830" height="1138" alt="image" src="https://github.com/user-attachments/assets/ec7d5ad2-adf6-4ce3-a492-cbfa9bfbb7e9" />
<img width="1832" height="650" alt="image" src="https://github.com/user-attachments/assets/6811cef3-b057-4d0c-8e9d-548e1ce5822b" />


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

<img width="1174" height="882" alt="image" src="https://github.com/user-attachments/assets/f11841d0-8a82-4186-a47d-adcf0f08b835" />

<img width="1830" height="1158" alt="image" src="https://github.com/user-attachments/assets/01d475ff-e34d-406c-9d98-a61e862a7afd" />

<img width="2024" height="176" alt="image" src="https://github.com/user-attachments/assets/06575295-e7ae-4776-9848-4c305707ebfc" />

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

<img width="1832" height="1000" alt="image" src="https://github.com/user-attachments/assets/9ce1ef3e-5a28-479b-9ccf-a82798c1d857" />
  
**3. Apply the change:**

```bash
terraform apply

```
<img width="1842" height="458" alt="image" src="https://github.com/user-attachments/assets/b0f3cfc2-9938-4e20-a94a-aabb5402cab4" />
<img width="2094" height="172" alt="image" src="https://github.com/user-attachments/assets/de7b6375-9b09-4c86-95e3-474642d8ce80" />

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
