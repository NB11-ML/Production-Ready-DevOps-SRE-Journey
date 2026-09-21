# 🌍 Day 61: TerraWeek Begins — Introduction to Infrastructure as Code

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![SRE](https://img.shields.io/badge/SRE-FF4F00?style=for-the-badge&logo=opsgenie&logoColor=white)

Welcome to Day 61 of the **Production-Ready DevOps & SRE Journey**, and the official kickoff for **TerraWeek**!

Up until now, we have focused on orchestrating application workloads using Kubernetes. But where do the underlying nodes, networks, and storage actually come from? Today, we stop relying on manual "ClickOps" in the AWS Console and transition to **Infrastructure as Code (IaC)**. 

By writing declarative code using HashiCorp Configuration Language (HCL), we can provision, update, and destroy entire cloud environments safely, reproducibly, and automatically.

---

## 📖 The SRE Syllabus

### 1. Infrastructure as Code (IaC) vs. ClickOps
We explored why manual infrastructure provisioning is an SRE anti-pattern. IaC enables version control, peer-reviewed infrastructure changes, and instant disaster recovery. We compared Terraform (declarative and cloud-agnostic) against procedural tools (like Bash/Ansible) and provider-locked tools (like CloudFormation).

### 2. The Core Terraform Lifecycle
We executed the fundamental workflow required to build cloud infrastructure safely:
*   `terraform init`: Bootstrapping the AWS provider.
*   `terraform fmt` & `validate`: Standardizing and checking HCL syntax.
*   `terraform plan`: Generating a deterministic dry-run of resource changes.
*   `terraform apply`: Physically provisioning an S3 Bucket and EC2 Instance.
*   `terraform destroy`: Cleaning up resources to prevent runaway cloud billing.

### 3. State File Security (`terraform.tfstate`)
We analyzed the local database Terraform uses to map code to real AWS IDs. Because the state file contains plain-text secrets and exact infrastructure topology, we enforced the golden SRE rule: **Never manually edit the state file, and never commit it to Git.**

---

## 📂 Repository Directory Map

```text
Day-61/
├── README.md                           # The master syllabus and directory map
├── 01-Day-61-Terraform-Intro.md        # Core challenge documentation and execution steps
├── 02-Day-61-Cheat-Sheet.md            # Terraform lifecycle commands and interview prep
├── main.tf                             # Our first HCL declarative AWS configuration
└── .gitignore                          # Security configs to ignore state files and binaries

```

---

### 👨‍🏫 Final Takeaway

Terraform shifts our infrastructure mindset from *imperative* commands ("create this server, then do this") to *declarative* architecture ("make the cloud match this blueprint"). This idempotency is the foundation of modern Site Reliability Engineering, ensuring our infrastructure always matches our version-controlled intent.
