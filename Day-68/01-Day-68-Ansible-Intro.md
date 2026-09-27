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

**Infrastructure Provisioned:**

* 3x AWS EC2 Instances (`t2.micro`) running Ubuntu 22.04 / Amazon Linux 2.
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

**Installation (Ubuntu/Debian example):**

```bash
sudo apt update
sudo apt install ansible -y

```

**Verification:**

```bash
ansible --version

```

*Note: Ansible is **only** needed on the Control Node because it pushes commands out via SSH. The managed nodes only need Python installed (which comes pre-installed on most modern Linux distributions).*

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
ansible_user=ubuntu  # Use ec2-user if using Amazon Linux
ansible_ssh_private_key_file=~/your-key.pem

```

---

## ⚡ Task 5: Running Ad-Hoc Commands

Ad-hoc commands are perfect for quick, one-off tasks without writing a full playbook.

**1. Ping all servers to verify connectivity:**

```bash
ansible all -i inventory.ini -m ping

```

*(Result: Green `SUCCESS` output with `"ping": "pong"` for all three servers).*

**2. Check uptime on all servers:**

```bash
ansible all -i inventory.ini -m command -a "uptime"

```

**3. Check free memory on web servers only:**

```bash
ansible web -i inventory.ini -m command -a "free -h"

```

**4. Check disk space on all servers:**

```bash
ansible all -i inventory.ini -m command -a "df -h"

```

**5. Install a package (Git) on the web group:**

```bash
ansible web -i inventory.ini -m apt -a "name=git state=present" --become

```

* **What does `--become` do?** It tells Ansible to escalate privileges to root (similar to running `sudo`). This is absolutely required when executing administrative tasks like installing packages, managing system services, or modifying restricted files.

**6. Copy a file to all servers:**

```bash
echo "Hello from Ansible" > hello.txt
ansible all -i inventory.ini -m copy -a "src=hello.txt dest=/tmp/hello.txt"

```

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
private_key_file = ~/your-key.pem

```

**Final Verification:**

```bash
ansible all -m ping

```

*Result: Command executed successfully against all grouped targets purely relying on the local `ansible.cfg`.*

---
