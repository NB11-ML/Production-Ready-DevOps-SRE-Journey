# ⚙️ Day 69: Ansible Playbooks and Modules

**Date:** September 29, 2026

---

## 📋 Prerequisites & Inventory Setup

Before running these playbooks, ensure your `inventory.ini` is correctly mapped to the infrastructure provisioned via Terraform. Since the nodes are running Ubuntu 22.04 LTS, the default SSH user is `ubuntu`.

**`inventory.ini`**

```ini
[web]
web-server ansible_host=

[app]
app-server ansible_host=

[db]
db-server ansible_host=

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/ansible_lab_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

```

---

## 📌 Task 1: Your First Playbook

Playbooks turn ad-hoc commands into repeatable, version-controlled infrastructure as code.

### 1. Create `install-nginx.yml`

*(Using the `apt` module for Ubuntu)*

```yaml

- name: Install and start Nginx on web servers
  hosts: web
  become: true

  tasks:
    - name: Update apt cache and install Nginx
      apt:
        name: nginx
        state: present
        update_cache: true

    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: true

    - name: Create a custom index page
      copy:
        content: |
          Deployed by Ansible - TerraWeek Server
        dest: /var/www/html/index.html

```

### 2. Execution & Idempotency

Run the playbook:

```bash
ansible-playbook -i inventory.ini install-nginx.yml

```

<img width="2012" height="788" alt="image" src="https://github.com/user-attachments/assets/f76a716a-0fdb-43fe-8e42-2ebfe4e65ac3" />

**Observation 1 (First Run):** Tasks show `changed` in yellow. Ansible updated the apt cache, downloaded the package, started the service, and created the file.


<img width="2164" height="800" alt="image" src="https://github.com/user-attachments/assets/8900a897-8a3d-4887-997a-a78c367e2bf1" />

**Observation 2 (Second Run):** Run the exact same command again. Tasks show `ok` in green. This is **Idempotency**—Ansible checks the current state against the desired state and does nothing if the target is already compliant.

**Verification:**

```bash
# Ensure Port 80 is open in your AWS Security Group!
curl http://
# Output: 
# Deployed by Ansible - TerraWeek Server

```

<img width="1730" height="222" alt="image" src="https://github.com/user-attachments/assets/98ef3412-3967-4d3f-bb02-979c47aeea05" />

<img width="1210" height="228" alt="image" src="https://github.com/user-attachments/assets/71cbf3d6-82c2-4551-9b55-59ed50eebce2" />


---

## 📌 Task 2: Playbook Structure & Anatomy

Here is the annotated structure of an Ansible playbook:

```yaml
- name: Play name                      # PLAY -- Describes the goal of this section
  hosts: web                           # Which inventory group to target
  become: true                         # Privilege escalation (run as sudo/root)

  tasks:                               # List of TASKS in this play
    - name: Task name                  # TASK -- A single unit of work
      module_name:                     # MODULE -- The tool Ansible uses to do the work
        key: value                     # Module arguments/parameters

```

### 🧠 Core Concept Questions

* **What is the difference between a play and a task?**
A **play** maps a specific group of hosts to a defined set of roles and tasks. A **task** is a single, specific action executed on those hosts using a module (like installing a package or copying a file).
* **Can you have multiple plays in one playbook?**
Yes. A playbook is fundamentally a YAML list of plays. You can configure web servers in Play 1, and database servers in Play 2, all within the same file.
* **What does `become: true` do at the play level vs the task level?**
At the **play level**, it runs *every* task in that play with elevated (root) privileges. At the **task level**, it elevates privileges only for that specific, individual task.
* **What happens if a task fails?**
By default, Ansible immediately stops executing the remaining tasks for the specific host that failed. Other hosts that succeeded will continue executing.


---

## 📌 Task 3: Essential Modules

Create `essential-modules.yml` to practice the most heavily used automation modules in the industry.

```yaml
- name: Demonstrate essential Ansible modules
  hosts: all
  become: true

  tasks:
    # 1. Package Management
    - name: Install multiple packages
      apt:
        name:
          - git
          - curl
          - wget
          - tree
        state: present
        update_cache: true

    # 2. Service Management
    - name: Ensure Nginx is running (Only on web group to prevent errors on app/db)
      service:
        name: nginx
        state: started
        enabled: true
      when: "'web' in group_names"

    # 3. File Copy (Requires creating files/app.conf locally first)
    - name: Copy config file
      copy:
        src: files/app.conf
        dest: /etc/app.conf
        owner: root
        group: root
        mode: '0644'

    # 4. File & Directory Management
    - name: Create application directory
      file:
        path: /opt/myapp
        state: directory
        owner: ubuntu
        mode: '0755'

    # 5. Raw Command Execution
    - name: Check disk space
      command: df -h
      register: disk_output

    - name: Print disk space
      debug:
        var: disk_output.stdout_lines

    # 6. Shell Execution
    - name: Count running processes
      shell: ps aux | wc -l
      register: process_count

    - name: Show process count
      debug:
        msg: "Total processes: {{ process_count.stdout }}"

    # 7. Line Injection
    - name: Set timezone in environment
      lineinfile:
        path: /etc/environment
        line: 'TZ=Asia/Kolkata'
        create: true

```

### 🚀 Execution & Verification

Run the essential modules playbook against your infrastructure:

```bash
ansible-playbook -i inventory.ini essential-modules.yml
```
<img width="1768" height="1252" alt="image" src="https://github.com/user-attachments/assets/0177ee5f-074a-4261-b52b-4e125ebf6a53" />
<img width="1744" height="1486" alt="image" src="https://github.com/user-attachments/assets/da1642e9-1bb8-41d5-9698-72599bc80efb" />
<img width="1772" height="1098" alt="image" src="https://github.com/user-attachments/assets/be1f4570-4de0-489c-9bca-870c667230ae" />


### 🧠 `command` vs. `shell`

* **`command`:** Executes the command directly on the host without going through a shell environment. It is safer, more predictable, and prevents shell injection, but it **cannot** process shell operators like pipes (`|`), redirects (`>`), or environment variables (`$HOME`).
* **`shell`:** Runs the command through `/bin/sh`. You **must** use this if your command relies on pipes, redirects, or stringing multiple commands together. It should be used sparingly due to potential security risks if passing unsanitized variables.

### 🧠 Core Concepts & Module Breakdown

Task 3 introduces the most frequently used operational modules in enterprise automation:

* **Package Management (`apt`):** Automates installation, updates, and removal of OS packages. Setting `update_cache: true` acts like running `apt-get update` before installing packages.
* **Service Management (`service`):** Ensures system daemons are running or stopped. We used the conditional expression `when: "'web' in group_names"` to target *only* the web group, preventing service errors on app or database nodes.
* **File Copy (`copy`):** Pushing configuration files from your local control machine to a remote destination with explicit permissions (`owner`, `group`, `mode`).
* **Directory Management (`file`):** Used to create directories, set permissions, or manage symlinks on the remote target.
* **Command vs. Shell Execution (`command` vs. `shell`):** The `command` module runs raw commands safely without a shell environment, while `shell` runs commands through `/bin/sh` to allow pipe operations (`|`) and redirects.
* **Data Registration (`register`):** Captures the standard output of a command into an internal variable (e.g., `register: disk_output`) so subsequent tasks can process or print it using the `debug` module.
* **Line Injection (`lineinfile`):** Ensures a specific line exists in a configuration file (like `/etc/environment`), adding it or modifying it safely without rewriting the entire file.



---

## 📌 Task 4: Handlers — Triggered Actions

Handlers are special tasks that only execute when notified by another task that resulted in a `changed` state. This prevents unnecessary service restarts.

### 1. Create the Local Configuration File

Before running the playbook, ensure you have a local configuration source file prepared[cite: 5]:

```bash
mkdir -p files
nano files/nginx.conf
```
**files/nginx.conf**

```conf
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name localhost;

        location / {
            root /var/www/html;
            index index.html index.htm;
        }
    }
}

```
### 2. Create your local Nginx config

Create `nginx-config.yml`:

```yaml
- name: Configure Nginx with a custom config
  hosts: web
  become: true

  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Deploy Nginx config
      copy:
        src: files/nginx.conf
        dest: /etc/nginx/nginx.conf
        owner: root
        mode: '0644'
      notify: Restart Nginx   # <--- Trigger

    - name: Deploy custom index page
      copy:
        content: |
          # Managed by Ansible
          
          Server: {{ inventory_hostname }}
        dest: /var/www/html/index.html

    - name: Ensure Nginx is running
      service:
        name: nginx
        state: started
        enabled: true

  handlers:
    - name: Restart Nginx       # <--- Receiver
      service:
        name: nginx
        state: restarted

```

### 🚀 Execution & Verification

Run your configuration playbook with handlers enabled:

```bash
ansible-playbook -i inventory.ini nginx-config.yml

```



### 🧠 Core Concepts & Handler Behavior

Handlers are event-driven tasks that solve a critical infrastructure challenge: **preventing unnecessary service restarts.**

* **The Trigger (`notify`):** When a task results in a `changed` state (like updating a configuration file or a template), it fires a notification pointing to the handler's exact name. If the task finishes with `ok` (no changes made), the notification is ignored.
* **Execution Timing:** Handlers **do not** run immediately when notified. Ansible queues them up and executes them *at the very end of the play*. This ensures that even if multiple configuration tasks notify the same handler, the service is only restarted **once** rather than after every individual task.


**Handler Verification:**

1. **First Run:** The `copy` task changes the config file. It notifies the handler. At the end of the play, Nginx restarts.

<img width="2082" height="956" alt="image" src="https://github.com/user-attachments/assets/5a35edab-38fe-4979-b688-ee2a51369cbc" />



2. **Second Run:** The `copy` task sees the file is already correct (`ok`). Because it didn't change, the `notify` trigger is suppressed. The handler **does not run**, saving the service from an unnecessary restart.


<img width="1648" height="386" alt="image" src="https://github.com/user-attachments/assets/04a5fa9f-cbfb-4d14-b534-82f5fb4255a9" />


---

## 📌 Task 5: Dry Run, Diff, and Verbosity

Before applying configuration to production environments, always preview the blast radius.

```bash
# Check Mode (Dry Run) - Simulates execution without making actual system changes
ansible-playbook -i inventory.ini install-nginx.yml --check

# Diff Mode - Displays the exact line-by-line file differences being applied
ansible-playbook -i inventory.ini nginx-config.yml --check --diff

# Verbosity - Increases log detail (useful for debugging SSH or variable issues)
ansible-playbook -i inventory.ini install-nginx.yml -v        # Basic details
ansible-playbook -i inventory.ini install-nginx.yml -vvv      # Connection & SSH debugging

# Limits - Restricts the run to specific hosts or groups inside the playbook
ansible-playbook -i inventory.ini install-nginx.yml --limit web-server

# Discovery - Pre-flight checks to see what will be targeted
ansible-playbook -i inventory.ini install-nginx.yml --list-hosts
ansible-playbook -i inventory.ini install-nginx.yml --list-tasks

```

### 🧠 Why `--check --diff` is Mandatory for Production

Running `--check --diff` is the standard enterprise safety net. `--check` ensures you know exactly which tasks will alter the system state, while `--diff` physically prints the exact text additions, modifications, or deletions about to happen to critical configuration files. This prevents accidental overwrites or syntax errors from bringing down a production service.

---

## 📌 Task 6: Multiple Plays in One Playbook

A single playbook can orchestrate an entire multi-tier architecture by separating tasks into independent plays targeting specific infrastructure groups.

Create `multi-play.yml`:

```yaml
# PLAY 1: Web Tier
- name: Configure web servers
  hosts: web
  become: true

  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present
        update_cache: true
        
    - name: Start Nginx
      service:
        name: nginx
        state: started
        enabled: true

# PLAY 2: Application Tier
- name: Configure app servers
  hosts: app
  become: true

  tasks:
    - name: Install Node.js build dependencies
      apt:
        name: build-essential
        state: present
        update_cache: true
        
    - name: Create app directory
      file:
        path: /opt/app
        state: directory
        owner: ubuntu
        mode: '0755'

# PLAY 3: Database Tier
- name: Configure database servers
  hosts: db
  become: true

  tasks:
    - name: Install MySQL client
      apt:
        name: mysql-client
        state: present
        update_cache: true
        
    - name: Create data directory
      file:
        path: /var/lib/appdata
        state: directory
        owner: ubuntu
        mode: '0700'

```

<img width="2014" height="1504" alt="image" src="https://github.com/user-attachments/assets/fab516f1-2d6b-420d-baa1-2227b300ccb9" />


**Execution Result:**

When you run `ansible-playbook -i inventory.ini multi-play.yml`, you will see Ansible systematically target the `[web]` hosts first, followed by the `[app]` hosts, and finally the `[db]` hosts, isolating the packages exactly where they belong in the architecture.
