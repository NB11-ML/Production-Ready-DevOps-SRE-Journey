# Day 68: Ansible Introduction & AWS Infrastructure Provisioning

This directory contains the code and documentation for Day 68 of the `#90DaysOfDevOps` journey. The objective of this lab is to provision a production-grade AWS environment using Terraform and configure it dynamically using Ansible from a macOS Control Node.

## 🏗️ Architecture & Objectives
Instead of relying on local virtual machines or a default AWS VPC, this lab embraces SRE best practices by provisioning a complete, isolated network (Custom VPC, Subnet, Internet Gateway) and deploying three Ubuntu 24.04 EC2 instances (`web`, `app`, `db`) to serve as Ansible managed nodes. 

## 📂 Directory Structure
To maintain a professional repository layout, Infrastructure as Code (IaC) is strictly separated from Configuration Management.

```text
Prod-Ansible/
├── Terra-Ansi-Infra/          # Terraform code for AWS provisioning
│   └── main.tf                # VPC, Security Groups, EC2 instances, Outputs
├── ansible-practice/          # Ansible configuration and inventory
│   ├── ansible.cfg            # SSH and Python interpreter overrides
│   └── inventory.ini          # Dynamic IP mapping and auth variables
├── day-68-ansible-intro.md    # Detailed step-by-step documentation
├── day-68-cheatsheet.md       # Quick reference for TF/Ansible commands
└── cleanup.md                 # Teardown and AWS CLI verification runbook

```

## ⚙️ Prerequisites

* **Control Node:** macOS with Ansible installed (`brew install ansible`).
* **Infrastructure Tools:** Terraform (`>= 1.0`) and the AWS CLI configured with active credentials.
* **Authentication:** An Ed25519 SSH key generated specifically for this lab:
```bash
ssh-keygen -t ed25519 -C "ansible-lab" -f ~/.ssh/ansible_lab_key

```



## 🚀 Execution Workflow

### 1. Provision Infrastructure

Navigate to the Terraform directory to spin up the custom VPC, Security Groups (allowing port 22), and the EC2 instances.

```bash
cd Terra-Ansi-Infra
terraform init
terraform apply --auto-approve

```

*Note the outputted public IP addresses for the `web-server`, `app-server`, and `db-server`.*

### 2. Configure Ansible Inventory

Navigate to the configuration directory and populate `inventory.ini` with the Terraform IP outputs.

```bash
cd ../ansible-practice

```

*The `ansible.cfg` file in this directory is pre-configured with `host_key_checking = False` to bypass manual SSH fingerprint prompts for these ephemeral instances.*

### 3. Validate Connectivity

Execute ad-hoc Ansible commands using the one-line output flag (`-o`) to ensure the Control Node can orchestrate the AWS instances successfully.

```bash
# Verify SSH and Python interpreter
ansible all -i inventory.ini -m ping -o

# Test file distribution
echo "Hello from Ansible" > hello.txt
ansible all -i inventory.ini -m copy -a "src=hello.txt dest=/tmp/hello.txt"

# Verify execution on remote nodes
ansible all -i inventory.ini -m command -a "cat /tmp/hello.txt" -o

```

### 4. Clean Teardown

To prevent unwanted AWS charges, destroy all infrastructure once the lab is complete.

```bash
cd ../Terra-Ansi-Infra
terraform destroy --auto-approve

```

*Refer to `cleanup.md` for the AWS CLI verification commands used to confirm zero orphaned resources remain.*

---
