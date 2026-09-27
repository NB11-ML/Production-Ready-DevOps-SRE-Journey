# 🚀 Day 68 Cheat Sheet: Ansible & Terraform SRE Lab Workflow

A quick reference guide for provisioning AWS infrastructure via Terraform, configuring an Ansible Control Node, executing ad-hoc commands, and cleanly tearing down resources.

## 1. Infrastructure as Code (Terraform)
Run these commands from the `Terra-Ansi-Infra` directory.

*   **Initialize Terraform:** `terraform init`
*   **Validate syntax:** `terraform validate`
*   **Provision infrastructure:** `terraform apply --auto-approve`
*   **Destroy all resources:** `terraform destroy --auto-approve`

## 2. Ansible Control Node Setup (macOS)
Ansible is only installed on the Control Node (your local machine).

*   **Install via Homebrew:** `brew install ansible`
*   **Verify installation:** `ansible --version`

## 3. Ansible Configuration (`ansible-practice` directory)
These files ensure a seamless SSH connection without manual fingerprint prompts.

**`inventory.ini` (Mapping IPs and Authentication):**
```ini
[web]
web-server ansible_host=

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/ansible_lab_key

```

**`ansible.cfg` (Bypassing SSH Prompts & Warnings):**

```ini
[defaults]
host_key_checking = False
interpreter_python = auto_silent
deprecation_warnings = False

```

## 4. Ansible Ad-Hoc Commands

Run these from the directory containing `inventory.ini` and `ansible.cfg`.
*Note: The `-o` flag condenses the JSON output to a single, readable line.*

* **Ping all servers:**
`ansible all -i inventory.ini -m ping -o`
* **Copy a local file to all servers:**
`ansible all -i inventory.ini -m copy -a "src=hello.txt dest=/tmp/hello.txt"`
* **Execute a standard Linux command:**
`ansible all -i inventory.ini -m command -a "cat /tmp/hello.txt" -o`

## 5. AWS CLI Resource Verification

Use these commands after a Terraform destroy to ensure zero orphaned resources are left behind in `us-east-1`.

* **Verify no running EC2 instances:**
  
`aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name}" --output table --region us-east-1`

* **Verify custom VPC deletion:**

`aws ec2 describe-vpcs --query "Vpcs[*].{VpcId:VpcId,Name:Tags[?Key=='Name']|[0].Value}" --output table --region us-east-1`

---
