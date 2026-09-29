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

Now, override variables directly from the command line using `-e` (Extra Vars):

```bash
ansible-playbook -i inventory.ini variables-demo.yml -e "app_name=my-custom-app app_port=9090"

```

**Observation:** The CLI `-e` flag successfully overrides the playbook variables. The application directory created on the servers will be `/opt/my-custom-app` instead of `/opt/terraweek-app`.

---

## 📌 Task 2: group_vars and host_vars

To keep playbooks clean and reusable, variables should not live inside the playbooks. They should be decoupled and stored in dedicated inventory files.

### 1. Directory Structure

Create this structure in your working directory:

```text
ansible-practice/
  inventory.ini
  ansible.cfg
  group_vars/
    all.yml
    web.yml
    db.yml
  host_vars/
    web-server.yml
  playbooks/
    site.yml

```

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

### 🧠 `loop` vs. `with_items`

* **`loop`:** The modern, standard syntax introduced in Ansible 2.5. It handles complex data structures easily and is the recommended approach for all new playbooks.
* **`with_items`:** The older legacy syntax that relies on specific lookup plugins. While it remains backwards compatible, `loop` replaces it.

---

## 📌 Task 6: Register, Debug, and Combine Everything

Build a real-world playbook that combines variables, facts, conditionals, and the `register` module (which captures command output).

### 1. Create `server-report.yml`

```yaml
- name: Server Health Report
  hosts: all
  become: true

  tasks:
    - name: Check disk space
      command: df -h /
      register: disk_result

    - name: Check memory
      command: free -m
      register: memory_result

    - name: Check running services
      shell: systemctl list-units --type=service --state=running | head -20
      register: services_result

    - name: Generate report on terminal
      debug:
        msg:
          - "========== {{ inventory_hostname }} =========="
          - "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
          - "IP: {{ ansible_default_ipv4.address }}"
          - "RAM: {{ ansible_memtotal_mb }}MB"
          - "Disk: {{ disk_result.stdout_lines[1] }}"
          - "Running services (first 20): {{ services_result.stdout_lines | length }}"

    - name: Flag if disk is critically low
      debug:
        msg: "ALERT: Check disk space on {{ inventory_hostname }}"
      when: "'9[0-9]%' in disk_result.stdout or '100%' in disk_result.stdout"

    - name: Save report to file
      copy:
        content: |
          Server: {{ inventory_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          IP: {{ ansible_default_ipv4.address }}
          RAM: {{ ansible_memtotal_mb }}MB
          Disk: 
          {{ disk_result.stdout }}
          Checked at: {{ ansible_date_time.iso8601 }}
        dest: "/tmp/server-report-{{ inventory_hostname }}.txt"

```

### 🚀 Execution & Verification

Run the playbook and then SSH into a server to verify the report is accurate:

```bash
ansible-playbook -i inventory.ini server-report.yml

# Verify
ssh ubuntu@
cat /tmp/server-report-*.txt

```
