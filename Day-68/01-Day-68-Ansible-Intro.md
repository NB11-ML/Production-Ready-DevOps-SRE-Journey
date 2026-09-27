# ⚙️ Day 68: Introduction to Ansible and Inventory Setup


## 📝 Task 1: Understanding Ansible

### What is Configuration Management?
Configuration management is the process of automating, maintaining, and managing the desired state of infrastructure and software systems. 
* **Why we need it:** When managing hundreds of servers, manually installing packages, editing config files, and creating users is impossible to scale and highly prone to human error (configuration drift). Configuration management tools allow us to define our infrastructure as code (IaC), ensuring consistency, rapid provisioning, and version control.

### How Ansible differs from Chef, Puppet, and Salt
* **Chef & Puppet:** Primarily operate on a **Pull** mechanism and are **Agent-based**. This means a background software daemon (agent) must be installed on every target server to pull configurations from a master server. They also rely heavily on Ruby.
* **Ansible:** Operates on a **Push** mechanism and is completely **Agentless**. It uses standard YAML for configuration (Playbooks), making it incredibly easy to read and adopt.

### What does "Agentless" mean?
"Agentless" means Ansible does not require any proprietary background service, daemon, or agent to be installed on the managed nodes. 
* **How it connects:** Ansible simply connects to target machines using standard **SSH** (for Linux) or WinRM (for Windows). Once connected, it pushes temporary Python scripts to the node, executes them to achieve the desired state, and then removes them.

### Ansible Architecture
* **Control Node:** The central machine where Ansible is installed and executed (e.g., your laptop, or a dedicated EC2 jump server).
* **Managed Nodes:** The target servers that Ansible is configuring (e.g., the web, app, and db EC2 instances).
* **Inventory:** A file (`ini` or `yaml` format) containing the list, IP addresses, and groupings of the managed nodes.
* **Modules:** Standalone, reusable scripts that Ansible executes on the managed nodes to perform specific tasks (e.g., `yum`, `apt`, `copy`, `service`).
* **Playbooks:** YAML files that contain a blueprint of multiple tasks and roles, defining the desired state of the managed nodes in a repeatable way.

---

## 🛠️ Task 2: Lab Environment Setup

To continue practicing Infrastructure as Code (IaC), I utilized Terraform to provision my lab environment instead of doing it manually.

## 📋 Pre-Requisites & Lab Infrastructure Provisioning

To mirror a production-grade automated workflow, I avoided manual console setups. Instead, I combined **Terraform Infrastructure as Code (IaC)** with modern **Ed25519 cryptographic keys** to provision the lab environment.

### Step 1: Project Directory Structure
Created a dedicated infrastructure subdirectory inside the project repository to house the Terraform files:
```bash
mkdir -p ../Prod-Ansible/Terra-Ansi-Infra
cd ../Prod-Ansible/Terra-Ansi-Infra

```

### Step 2: Generate an Ed25519 SSH Key Pair

On the control node, generated a high-security, modern Ed25519 SSH key pair without a passphrase to allow seamless authentication for Ansible:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/ansible_lab_key -N ""

```

*Permissions safeguard:*

```bash
chmod 600 ~/.ssh/ansible_lab_key

```

### Step 3: Provision Infrastructure via Terraform (`main.tf`)

Created the `main.tf` configuration inside the `Terra-Ansi-Infra` folder utilizing AWS Provider `~> 6.0` to automate the following:

1. Registered the local Ed25519 public key (`~/.ssh/ansible_lab_key.pub`) as an AWS Key Pair resource (`aws_key_pair`).
2. Configured a strict network Security Group permitting inbound SSH (Port 22).
3. Used a Terraform `for_each` loop over a local map structure to spin up three distinct `t3.micro` instances (`web-server`, `app-server`, `db-server`) running Ubuntu 22.04 LTS.
4. Added structured AWS Tags (`Name` and `Role`) to prepare for future dynamic inventory management.

**`main.tf` Configuration:**

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Create a Custom VPC
resource "aws_vpc"  "ansible_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ansible-lab-vpc"
  }
}

# 2. Create an Internet Gateway so instances have internet access
resource "aws_internet_gateway" "ansible_igw" {
  vpc_id = aws_vpc.ansible_vpc.id

  tags = {
    Name = "ansible-lab-igw"
  }
}

# 3. Create a Public Subnet
resource "aws_subnet" "ansible_subnet" {
  vpc_id                  = aws_vpc.ansible_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Automatically give instances public IPs

  tags = {
    Name = "ansible-lab-subnet"
  }
}

# 4. Create a Route Table and route traffic to the Internet Gateway
resource "aws_route_table" "ansible_rt" {
  vpc_id = aws_vpc.ansible_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ansible_igw.id
  }

  tags = {
    Name = "ansible-lab-rt"
  }
}

# 5. Associate Route Table with the Subnet
resource "aws_route_table_association" "ansible_rta" {
  subnet_id      = aws_subnet.ansible_subnet.id
  route_table_id = aws_route_table.ansible_rt.id
}

# 6. Create the AWS Key Pair using your local Ed25519 public key
resource "aws_key_pair" "ansible_key" {
  key_name   = "ansible_lab_key"
  public_key = file("~/.ssh/ansible_lab_key.pub")
}

# 7. Security Group allowing SSH (Tied to custom VPC)
resource "aws_security_group" "ansible_sg" {
  name        = "ansible-lab-sg"
  description = "Allow SSH for Ansible control node"
  vpc_id      = aws_vpc.ansible_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 8. Define the instances needed for the Ansible lab
locals {
  servers = {
    "web-server" = "web"
    "app-server" = "app"
    "db-server"  = "db"
  }
}

# 9. Provision the EC2 Instances
resource "aws_instance" "ansible_nodes" {
  for_each      = local.servers
  ami           = "ami-0f8a61b66d1accaee"
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.ansible_subnet.id
  key_name               = aws_key_pair.ansible_key.key_name
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]

  tags = {
    Name = each.key
    Role = each.value
  }
}

# 10. Output the IPs for your Ansible inventory.ini
output "ansible_inventory_ips" {
  value = { for k, v in aws_instance.ansible_nodes : k => v.public_ip }
}

```

### Step 4: Execution Workflow

Executed the Terraform workflow to provision the infrastructure:

```bash
terraform init
terraform apply --auto-approve

```

<img width="1712" height="908" alt="image" src="https://github.com/user-attachments/assets/4b5516d8-5f9b-405e-aa87-c00a7a740e9a" />
<img width="2086" height="450" alt="image" src="https://github.com/user-attachments/assets/809040cd-c469-4a48-b286-c25c328a5dcd" />


Captured the output IP addresses from the terminal to feed directly into the upcoming `inventory.ini` configuration.


**Infrastructure Provisioned:**

* 3x AWS EC2 Instances (`t3.micro`) running Ubuntu 22.04 / Amazon Linux 2.
* Configured a Security Group allowing inbound SSH (Port 22) from my IP.
* Attached a shared SSH Key Pair (`your-key.pem`) for access.

**Mental Mapping:**

* `Instance 1` -> Web Server
* `Instance 2` -> App Server
* `Instance 3` -> DB Server

*Verified connectivity via SSH from the control node before proceeding with Ansible.*

---

## 💻 Task 3: Installing Ansible

Ansible was installed directly on my primary Control Node (my local machine/jump server).

Since your control node is your local **macOS** machine, using `apt` won't work because it is a Debian/Ubuntu package manager. On macOS, the standard and cleanest way to install Ansible is using **Homebrew** (`brew`), or via Python's package manager (`pipx` / `pip3`).

Here is the corrected section for **Task 3** in your documentation tailored specifically for macOS:

---

### Task 3: Install Ansible

Ansible was installed directly on my primary Control Node (my local macOS machine).

**Installation (macOS via Homebrew):**

```bash
brew install ansible

```

*(Alternatively, via Python pipx/pip3 if Homebrew is not preferred)*:

```bash
pip3 install ansible

```

**Verification:**

```bash
ansible --version

```



**Installation (Ubuntu/Debian example):**

```bash
sudo apt update
sudo apt install ansible -y

```

**Verification:**

```bash
ansible --version

```

**Documentation Note:**
Ansible is **only** needed on the Control Node (macOS) because it acts as the orchestrator, pushing commands out via SSH. The managed nodes (the AWS EC2 instances running Ubuntu) do not need Ansible installed at all—they only need Python and a standard SSH server, which come pre-configured by default.

---

## 🗂️ Task 4: Creating the Inventory File

Created a project directory and initialized the inventory file to group the servers.

```bash
mkdir ansible-practice && cd ansible-practice
nano inventory.ini

```

**`inventory.ini`:**

```ini
[web]
web-server ansible_host=

[app]
app-server ansible_host=

[db]
db-server ansible_host=

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/your-key.pem

```
Configure Ansible Defaults:

To streamline automation and prevent SSH fingerprint prompts during the initial connection to dynamic cloud instances, I created an ansible.cfg file in the same directory:

**`ansible.cfg`:**

```bash
[defaults]
host_key_checking = False
interpreter_python = auto_silent
deprecation_warnings = False
```

Note: Disabling host_key_checking is standard practice for ephemeral EC2 instances, and silencing the Python interpreter warnings keeps the operational output clean.

---

## ⚡ Task 5: Running Ad-Hoc Commands

Ad-hoc commands are perfect for quick, one-off tasks without writing a full playbook.

**1. Ping all servers to verify connectivity:**

```bash
ansible all -i inventory.ini -m ping

```

<img width="2412" height="492" alt="image" src="https://github.com/user-attachments/assets/d08a6a87-b90e-4442-8541-54a9b9ffcf9e" />


*(Result: Green `SUCCESS` output with `"ping": "pong"` for all three servers).*

**2. Check uptime on all servers:**

```bash
ansible all -i inventory.ini -m command -a "uptime"

```

<img width="1804" height="390" alt="image" src="https://github.com/user-attachments/assets/a14d18d6-e23b-4b58-8e57-db5f63071ff3" />

**3. Check free memory on web servers only:**

```bash
ansible web -i inventory.ini -m command -a "free -h"

```
<img width="1792" height="214" alt="image" src="https://github.com/user-attachments/assets/93567f00-e1b1-4d1e-99ca-5807cce69734" />


**4. Check disk space on all servers:**

```bash
ansible all -i inventory.ini -m command -a "df -h"

```
<img width="1788" height="1130" alt="image" src="https://github.com/user-attachments/assets/bec5c057-161e-460c-88ec-80d73530ca42" />


**5. Install a package (Git) on the web group:**

```bash
ansible web -i inventory.ini -m apt -a "name=git state=present" --become

```

* **What does `--become` do?** It tells Ansible to escalate privileges to root (similar to running `sudo`). This is absolutely required when executing administrative tasks like installing packages, managing system services, or modifying restricted files.

  <img width="2068" height="510" alt="image" src="https://github.com/user-attachments/assets/30c06b9d-55ae-4bd8-923f-57e58f8ccef9" />
 

**6. Copy a file to all servers:**

```bash
echo "Hello from Ansible" > hello.txt
ansible all -i inventory.ini -m copy -a "src=hello.txt dest=/tmp/hello.txt"

```

<img width="1944" height="320" alt="image" src="https://github.com/user-attachments/assets/6d5b1666-aea3-4098-8d3a-82d85660bef9" />


### Module Differences: `command` vs `shell`

* **`command` module:** Executes tasks directly without routing through the node's shell. It is more secure and predictable but does **not** support shell variables (`$HOME`), redirects (`>`, `<`), or pipes (`|`).
* **`shell` module:** Executes the task through `/bin/sh`. This should be used when you explicitly need shell features like piping outputs or chaining commands together.

---

## 🎯 Task 6: Exploring Inventory Groups and Patterns

**Group of Groups Configuration:**
Added the following to the bottom of `inventory.ini` to nest groups:

```ini
[application:children]
web
app

[all_servers:children]
application
db

```

**Testing Patterns:**

```bash
# Target web AND app servers
ansible application -i inventory.ini -m ping     

# Target ONLY db servers
ansible db -i inventory.ini -m ping               

# Target everything EXCEPT db
ansible 'all:!db' -i inventory.ini -m ping        

```

<img width="2444" height="480" alt="image" src="https://github.com/user-attachments/assets/9124d09d-777e-4ded-ab50-a1fc939d13fa" />


---

**Creating `ansible.cfg` for ease of use:**
To avoid typing `-i inventory.ini` for every single command, I created a local configuration file.

```bash
nano ansible.cfg

```

```ini
[defaults]
inventory = inventory.ini
host_key_checking = False
remote_user = ubuntu
private_key_file = ~/your-key

```

**Final Verification:**

```bash
ansible all -m ping

```

<img width="2312" height="332" alt="image" src="https://github.com/user-attachments/assets/2e232b9c-1eb9-4c0c-bdbf-e2eb0b08321e" />

*Result: Command executed successfully against all grouped targets purely relying on the local `ansible.cfg`.*

---
