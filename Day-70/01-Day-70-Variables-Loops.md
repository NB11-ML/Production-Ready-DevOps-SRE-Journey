# ⚙️ Day 70: Variables, Facts, Conditionals and Loops

---

Static playbooks are great for basic tasks, but real-world infrastructure requires dynamic automation. Web servers need different configurations than database servers, and production environments differ from development. Today, we transition from rigid scripts to smart, adaptable playbooks using Ansible Variables, Facts, Conditionals, and Loops.

---

## 📌 Task 1: Variables in Playbooks

Variables allow you to define values once and reuse them throughout your playbook.

### 1. Create `variables-demo.yml`

```yaml
- name: Variable demo
  hosts: all
  become: true

  vars:
    app_name: terraweek-app
    app_port: 8080
    app_dir: "/opt/{{ app_name }}"
    packages:
      - git
      - curl
      - wget

  tasks:
    - name: Print app details
      debug:
        msg: "Deploying {{ app_name }} on port {{ app_port }} to {{ app_dir }}"

    - name: Create application directory
      file:
        path: "{{ app_dir }}"
        state: directory
        mode: '0755'

    - name: Install required packages
      apt:
        name: "{{ packages }}"
        state: present
        update_cache: true

```

### 2. Execution & Verification

Run the playbook:

```bash
ansible-playbook -i inventory.ini variables-demo.yml

```
<img width="1702" height="1468" alt="image" src="https://github.com/user-attachments/assets/b57c8c20-a00f-44e1-af17-7b37a42c2289" />

Now, override variables directly from the command line using `-e` (Extra Vars):

```bash
ansible-playbook -i inventory.ini variables-demo.yml -e "app_name=my-custom-app app_port=9090"

```
<img width="2056" height="1292" alt="image" src="https://github.com/user-attachments/assets/c677099d-8af3-4902-9520-2e605aafe41e" />


**Observation:** The CLI `-e` flag successfully overrides the playbook variables. The application directory created on the servers will be `/opt/my-custom-app` instead of `/opt/terraweek-app`.

<img width="2618" height="828" alt="image" src="https://github.com/user-attachments/assets/810a5637-aacf-4609-a42d-a1b948bd7bbd" />

---

## 📌 Task 2: group_vars and host_vars

To keep playbooks clean and reusable, variables should not live inside the playbooks. They should be decoupled and stored in dedicated inventory files.

### 1. Directory Structure

Create this structure in your working directory:

```text
ansible-practice/Day-70/
├── inventory.ini
├── ansible.cfg
├── group_vars/
│   ├── all.yml
│   ├── web.yml
│   └── db.yml
├── host_vars/
│   └── web-server.yml
└── playbooks/
    └── site.yml

```
<img width="1648" height="588" alt="image" src="https://github.com/user-attachments/assets/056e9f81-efd4-43a0-aafe-9e704ffb7a52" />


### 2. Variable Files

**group_vars/all.yml** (Applies to every host)

```yaml
ntp_server: pool.ntp.org
app_env: development
common_packages:
  - vim
  - htop
  - tree

```

**group_vars/web.yml** (Applies only to the `web` group)

```yaml
http_port: 80
max_connections: 1000
web_packages:
  - nginx

```

**group_vars/db.yml** (Applies only to the `db` group)

```yaml
db_port: 3306
db_packages:
  - mysql-server

```

**host_vars/web-server.yml** (Applies ONLY to this specific host)

```yaml
max_connections: 2000
custom_message: "This is the primary web server"

```

### 3. Create `site.yml`

Write a playbook that utilizes these newly created inventory variables:

```yaml
- name: Apply common config
  hosts: all
  become: true
  tasks:
    - name: Install common packages
      apt:
        name: "{{ common_packages }}"
        state: present
        update_cache: true
    - name: Show environment
      debug:
        msg: "Environment: {{ app_env }}"

- name: Configure web servers
  hosts: web
  become: true
  tasks:
    - name: Show web config
      debug:
        msg: "HTTP port: {{ http_port }}, Max connections: {{ max_connections }}"
    - name: Show host-specific message
      debug:
        msg: "{{ custom_message | default('Standard web server') }}"

```

### 🧠 Variable Precedence Documented

Ansible applies variables based on a strict hierarchy. If the same variable name exists in multiple places, the one with higher precedence wins.

<img width="2026" height="1660" alt="image" src="https://github.com/user-attachments/assets/96f68e82-3ddd-4626-b2b8-2a07bb6e05f4" />


**Order (Lowest to Highest):**

1. Role Defaults
2. `group_vars/all`
3. `group_vars/`
4. `host_vars/` *(This is why `web-server` gets 2000 max connections, overriding the group var's 1000)*
5. Playbook `vars`
6. Command line extra vars (`-e` overrides everything)

---


## 📌 Task 3: Ansible Facts — Gathering System Information

Ansible automatically collects "facts" about each managed node (OS, IP, memory, CPU, disks) before executing tasks.

### 1. Filter specific facts via CLI

See all facts for a host, or filter for exactly what you need:

```bash
ansible web-server -i inventory.ini -m setup -a "filter=ansible_os_family"
ansible web-server -i inventory.ini -m setup -a "filter=ansible_distribution*"
ansible web-server -i inventory.ini -m setup -a "filter=ansible_memtotal_mb"
ansible web-server -i inventory.ini -m setup -a "filter=ansible_default_ipv4"

```

<img width="2266" height="1324" alt="image" src="https://github.com/user-attachments/assets/bde14c89-9123-45e6-92dd-653ceb05afcf" />


### 2. Create `facts-demo.yml`

```yaml
- name: Facts demo
  hosts: all
  tasks:
    - name: Show OS info
      debug:
        msg: >
          Hostname: {{ ansible_hostname }},
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }},
          RAM: {{ ansible_memtotal_mb }}MB,
          IP: {{ ansible_default_ipv4.address }}

    - name: Show all network interfaces
      debug:
        var: ansible_interfaces

```

<img width="2784" height="1692" alt="image" src="https://github.com/user-attachments/assets/b17321eb-d59f-492a-9ac6-5efbe438e3e6" />


### 🧠 5 Useful Ansible Facts for Real-World Playbooks

1. **`ansible_distribution`**: Used in conditionals to execute `apt` for Ubuntu or `dnf` for Amazon Linux.
2. **`ansible_memtotal_mb`**: Used to dynamically calculate application memory limits (e.g., MySQL buffer pool sizes).
3. **`ansible_default_ipv4.address`**: Used to dynamically bind services to the correct local network interface.
4. **`ansible_hostname`**: Used to inject the machine's name into configuration files, log streams, or monitoring dashboards.
5. **`ansible_processor_vcpus`**: Used to auto-tune the number of worker processes for web servers like Nginx.

---

## 📌 Task 4: Conditionals with when

Tasks should not always run on every host. Use the `when` keyword to control execution based on facts, variables, or inventory groups.

### 1. Create `conditional-demo.yml`

```yaml
- name: Conditional tasks demo
  hosts: all
  become: true

  tasks:
    - name: Install Nginx (only on web servers)
      apt:
        name: nginx
        state: present
      when: "'web' in group_names"

    - name: Show warning on low memory hosts
      debug:
        msg: "WARNING: This host has less than 1GB RAM"
      when: ansible_memtotal_mb < 1024

    - name: Run only on Amazon Linux
      debug:
        msg: "This is an Amazon Linux machine"
      when: ansible_distribution == "Amazon"

    - name: Run only on Ubuntu
      debug:
        msg: "This is an Ubuntu machine"
      when: ansible_distribution == "Ubuntu"

    - name: Run only in production
      debug:
        msg: "Production settings applied"
      when: app_env == "production"

    - name: Multiple conditions (AND)
      debug:
        msg: "Web server with enough memory"
      when: 
        - "'web' in group_names"
        - ansible_memtotal_mb >= 512

    - name: OR condition
      debug:
        msg: "Either web or app server"
      when: "'web' in group_names or 'app' in group_names"

```

<img width="1744" height="1916" alt="image" src="https://github.com/user-attachments/assets/048e5311-e095-4985-89a3-ced879b7df5d" />


### 🚀 Execution & Verification

Run the playbook.

**Observation:** Tasks evaluate the `when` expression directly (no `{{ }}` brackets needed). If false, Ansible skips the task entirely (marked as `skipping` in cyan) on hosts that don't match the condition, preventing unwanted changes or errors.

---

## 📌 Task 5: Loops

Loops allow you to iterate over a list of items to perform repetitive tasks cleanly, replacing rigid line-by-line task duplication.

### 1. Create `loops-demo.yml`

```yaml
- name: Loops demo
  hosts: all
  become: true

  vars:
    users:
      - name: deploy
        groups: sudo
      - name: monitor
        groups: sudo
      - name: appuser
        groups: users

    directories:
      - /opt/app/logs
      - /opt/app/config
      - /opt/app/data
      - /opt/app/tmp

  tasks:
    - name: Create multiple users
      user:
        name: "{{ item.name }}"
        groups: "{{ item.groups }}"
        state: present
      loop: "{{ users }}"

    - name: Create multiple directories
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop: "{{ directories }}"

    - name: Install multiple packages
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - git
        - curl
        - unzip
        - jq

    - name: Print each user created
      debug:
        msg: "Created user {{ item.name }} in group {{ item.groups }}"
      loop: "{{ users }}"

```
<img width="1758" height="1408" alt="image" src="https://github.com/user-attachments/assets/d6893405-b6cc-47d5-9fe9-5f35ec0bcdf7" />
<img width="1732" height="974" alt="image" src="https://github.com/user-attachments/assets/938a2df3-07b6-4838-92d0-531c1eb83c97" />


### 🧠 `loop` vs. `with_items`

* **`loop`:** The modern, standard syntax introduced in Ansible 2.5. It handles complex data structures easily and is the recommended approach for all new playbooks.
* **`with_items`:** The older legacy syntax that relies on specific lookup plugins. While it remains backwards compatible, `loop` replaces it.

---

## 📌 Task 6: Register, Debug, and Combine Everything

Build a real-world playbook that combines variables, facts, conditionals, and the `register` module (which captures command output).

### 1. Create `server-report.yml`

```yaml
---
- name: Server health report
  hosts: all
  become: true
  gather_facts: true     # Ensures OS, IP, RAM, and Time facts are loaded safely

  tasks:
    - name: Check disk space
      ansible.builtin.command: df -h /
      register: disk_result
    
    - name: check memory
      ansible.builtin.command: free -m
      register: memory_result
    
    - name: check running services
      ansible.builtin.shell: systemctl list-units --type=service --state=running | head -20
      register: services_result
    
    - name: generate report on terminal
      ansible.builtin.debug:
        msg:
          - "========== {{ inventory_hostname }} =========="
          - "OS: {{ ansible_distribution | default('Unknown') }} {{ ansible_distribution_version | default('') }}"
          - "IP: {{ ansible_default_ipv4.address | default('No IP found') }}"
          - "RAM: {{ ansible_memtotal_mb | default('0') }}MB"
          - "Disk: {{ disk_result.stdout_lines.1 | default('N/A') }}"   # Fixed 'defaults' typo here
          - "Running services (first 20): {{ services_result.stdout_lines | length }}"

    - name: Flag if disk is critically low
      ansible.builtin.debug:
        msg: "ALERT: Check disk space on {{ inventory_hostname }}"
      when: "'9[0-9]%' in disk_result.stdout or '100%' in disk_result.stdout"

    - name: Save report to file
      ansible.builtin.copy:
        content: |
          Server: {{ inventory_hostname }}
          OS: {{ ansible_distribution | default('Unknown') }} {{ ansible_distribution_version | default('') }}
          IP: {{ ansible_default_ipv4.address | default('No IP found') }}
          RAM: {{ ansible_memtotal_mb | default('0') }}MB
          Disk: 
          {{ disk_result.stdout }}
          Checked at: {{ ansible_date_time.iso8601 | default('Unknown Time') }}
        dest: "/tmp/server-report-{{ inventory_hostname }}.txt"


```
**NOTE: I have Comment out Ip in terminal output of my code thats why it is not showing in output**

<img width="1712" height="1962" alt="image" src="https://github.com/user-attachments/assets/1d9904e8-1a79-48b7-b78b-26b90cd72055" />



### 🚀 Execution & Verification

Run the playbook and then SSH into a server to verify the report is accurate:

```bash
ansible-playbook -i inventory.ini server-report.yml

# Verify
ssh ubuntu@
cat /tmp/server-report-*.txt

```

<img width="1324" height="310" alt="Screenshot 2026-09-30 at 01 10 17" src="https://github.com/user-attachments/assets/04e0d73a-d1ad-4a9b-8d79-569369f093db" />

