# ⚙️ Day 71: Roles, Galaxy, Templates and Vault

**Date:** October 1, 2026

---

Your playbooks are getting bigger. Tasks, variables, handlers, files -- all living in one YAML file that grows longer every day. In real projects, you manage dozens of servers with different roles -- web servers, databases, monitoring agents, load balancers. You need a way to organize, reuse, and share automation.

Today you learn Ansible Roles (the standard way to structure automation), Jinja2 Templates (dynamic config files), Ansible Galaxy (the community marketplace), and Ansible Vault (secrets management).

---

## 📌 Day 71 Directory Structure Reference

Here is the complete folder and file hierarchy you will build throughout today's tasks.

```text
ansible-practice/Day-71/
├── inventory.ini                  # Your server IPs
├── ansible.cfg                    # Ansible config (for vault_password_file)
├── .vault_pass                    # (Task 5) Vault password file (Add to .gitignore!)
├── requirements.yml               # (Task 4) Ansible Galaxy dependencies
│
├── template-demo.yml              # (Task 1) Standalone playbook for templates
├── docker-setup.yml               # (Task 4) Playbook using Galaxy role
├── db-setup.yml                   # (Task 5) Playbook testing vault secrets
├── site.yml                       # (Task 3 & 6) Master playbook calling roles
│
├── group_vars/                    
│   └── db/
│       └── vault.yml              # (Task 5) Encrypted secrets for the DB servers
│
├── templates/                     # 📂 PLAYBOOK-LEVEL TEMPLATES
│   ├── nginx-vhost.conf.j2        # (Task 1) Used by template-demo.yml
│   └── db-config.j2               # (Task 6) Used by site.yml
│
└── roles/
    └── webserver/                 # 📂 YOUR CUSTOM ROLE
        ├── tasks/
        │   └── main.yml           # (Task 3) Role tasks
        ├── handlers/
        │   └── main.yml           # (Task 3) Role handlers
        ├── defaults/
        │   └── main.yml           # (Task 3) Role variables
        └── templates/             # 📂 ROLE-LEVEL TEMPLATES
            ├── index.html.j2      # (Task 3)
            ├── nginx.conf.j2      # (Task 3) 
            └── vhost.conf.j2      # (Task 3)

```

---
## 📌 Task 1: Jinja2 Templates

Templates let you generate config files dynamically using variables and facts.

### 1. Create `templates/nginx-vhost.conf.j2`

```jinja2

# Managed by Ansible -- do not edit manually
server {
    listen {{ http_port | default(80) }};
    server_name {{ ansible_hostname }};

    root /var/www/{{ app_name }};
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/{{ app_name }}_access.log;
    error_log /var/log/nginx/{{ app_name }}_error.log;
}

```

### 2. Create a playbook `template-demo.yml`

```yaml

- name: Deploy Nginx with template
  hosts: web
  become: true
  vars:
    app_name: terraweek-app
    http_port: 80

  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present
        update_cache: true

    - name: Create web root
      file:
        path: "/var/www/{{ app_name }}"
        state: directory
        mode: '0755'

    - name: Deploy vhost config from template
      template:
        src: templates/nginx-vhost.conf.j2
        dest: "/etc/nginx/conf.d/{{ app_name }}.conf"
        owner: root
        mode: '0644'
      notify: Restart Nginx

    - name: Deploy index page
      copy:
        content: "<h1>{{ app_name }}</h1><p>Host: {{ ansible_hostname }} | IP: {{ ansible_default_ipv4.address }}</p>"
        dest: "/var/www/{{ app_name }}/index.html"
  handlers:
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted

```

### 🚀 Execution & Verification

Run it with `--diff` to see the rendered template changes:

```bash
ansible-playbook -i inventory.ini template-demo.yml --diff

```

<img width="3040" height="2060" alt="image" src="https://github.com/user-attachments/assets/65a37b54-df1c-4685-bb52-91d2af4353f2" />


**Observation:** SSH into the web server and read the generated config. You will see that variables like `{{ app_name }}` and `{{ ansible_hostname }}` are completely replaced with actual values.

<img width="3412" height="1036" alt="image" src="https://github.com/user-attachments/assets/9eb9dc2d-08f8-4202-a314-9d0aff6ac3cb" />

---

## 📌 Task 2: Understand the Role Structure

An Ansible role has a fixed directory structure. Each directory has a specific purpose.

### 1. Directory Structure

```text
roles/
  webserver/
    tasks/
      main.yml         # The main task list
    handlers/
      main.yml         # Handlers (restart services, etc.)
    templates/
      nginx.conf.j2    # Jinja2 templates
    files/
      index.html       # Static files to copy
    vars/
      main.yml         # Role variables (high priority)
    defaults/
      main.yml         # Default variables (low priority, easily overridden)
    meta/
      main.yml         # Role metadata and dependencies

```

Every directory contains a `main.yml` that Ansible loads automatically. You only create the directories you need.

### 2. Generate Skeleton

Generate a skeleton with:

```bash
ansible-galaxy init roles/webserver

```

<img width="1686" height="850" alt="image" src="https://github.com/user-attachments/assets/2ce8148b-be2b-410b-a801-68447162f586" />


### 🧠 `vars/main.yml` vs. `defaults/main.yml`

* **`defaults/main.yml`**: Default variables with low priority; easily overridden by callers.
* **`vars/main.yml`**: Role variables with high priority; intended to remain constant and hard to override.

---

### 📌 Task 3: Build a Custom Webserver Role

Build a complete webserver role from scratch:

### 1. Role Variable Defaults (`roles/webserver/defaults/main.yml`)

```yaml

http_port: 80
app_name: myapp
max_connections: 512

```

### 2. Role Tasks (`roles/webserver/tasks/main.yml`)

```yaml

- name: Install Nginx
  apt:
    name: nginx
    state: present
    update_cache: true

- name: Deploy Nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    mode: '0644'
  notify: Restart Nginx

- name: Deploy vhost config
  template:
    src: vhost.conf.j2
    dest: "/etc/nginx/conf.d/{{ app_name }}.conf"
    owner: root
    mode: '0644'
  notify: Restart Nginx

- name: Create web root
  file:
    path: "/var/www/{{ app_name }}"
    state: directory
    mode: '0755'

- name: Deploy index page
  template:
    src: index.html.j2
    dest: "/var/www/{{ app_name }}/index.html"
    mode: '0644'

- name: Start and enable Nginx
  service:
    name: nginx
    state: started
    enabled: true

```

### 3. Role Handlers (`roles/webserver/handlers/main.yml`)

```yaml

- name: Restart Nginx
  service:
    name: nginx
    state: restarted

```

### 4. Role Templates

**`roles/webserver/templates/index.html.j2`**

```text

Welcome to {{ app_name }}
Server: {{ ansible_hostname }}
IP: {{ ansible_default_ipv4.address }}
Environment: {{ app_env | default('development') }}
Managed by Ansible

```

**`roles/webserver/templates/vhost.conf.j2`**

```jinja2

server {
    listen {{ http_port | default(80) }};
    server_name {{ ansible_hostname }};

    root /var/www/{{ app_name }};
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/{{ app_name }}_access.log;
    error_log /var/log/nginx/{{ app_name }}_error.log;
}

```

**`roles/webserver/templates/nginx.conf.j2`**

```jinja2

user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections {{ max_connections | default(512) }};
}

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    include /etc/nginx/conf.d/*.conf;
}

```

### 5. Call the Role from Playbook (`site.yml`)

Now call the role from a playbook `site.yml`:

```yaml

- name: Configure web servers
  hosts: web
  become: true
  roles:
    - role: webserver
      vars:
        app_name: terraweek
        http_port: 80

```

### 🚀 Execution & Verification

Run it:

```bash
ansible-playbook -i inventory.ini site.yml

```

<img width="3054" height="1986" alt="image" src="https://github.com/user-attachments/assets/1801067d-fd2e-4de1-ab40-88172cfc1717" />

<img width="1300" height="418" alt="image" src="https://github.com/user-attachments/assets/e6708f27-9985-434f-9198-df8d446c762b" />


**Verify:** Curl the web server to ensure the custom page loads correctly.

---

## 📌 Task 4: Ansible Galaxy -- Use Community Roles

Ansible Galaxy is a marketplace of pre-built roles.

### 1. Search for roles:

```bash
ansible-galaxy search nginx --platforms EL
ansible-galaxy search mysql

```

### 2. Install a role from Galaxy:

```bash
ansible-galaxy install geerlingguy.docker

```

### 3. Check where it was installed:

```bash
ansible-galaxy list

```

### 4. Use the installed role

Create `docker-setup.yml`:

```yaml
---
- name: Install Docker using Galaxy role
  hosts: app
  become: true
  roles:
    - geerlingguy.docker

```

Run it -- Docker gets installed with a single role call.

### 5. Use a requirements file for managing multiple roles

Create `requirements.yml`:

```yaml
---
roles:
  - name: geerlingguy.docker
    version: "7.4.1"
  - name: geerlingguy.ntp

```

Install all at once:

```bash
ansible-galaxy install -r requirements.yml

```

<img width="2088" height="828" alt="image" src="https://github.com/user-attachments/assets/bf50aa69-ba7a-4061-9420-b255f4ec537b" />


### 🧠 Why use `requirements.yml`?

It locks down exact version numbers across environments, ensures reproducible deployments, and allows automated build pipelines to pull required packages seamlessly without manual installation steps.

---

## 📌 Task 5: Ansible Vault -- Encrypt Secrets

Never put passwords, API keys, or tokens in plain text. Ansible Vault encrypts sensitive data.

### 1. Create an encrypted file:

```bash
ansible-vault create group_vars/db/vault.yml

```

It will ask for a vault password, then open an editor. Add:

```yaml

vault_db_password: <Password>
vault_db_root_password: <Password>
vault_api_key: <Password>

```

Save and exit. Open the file with `cat` -- it is fully encrypted.

### 2. Edit an encrypted file:

```bash
ansible-vault edit group_vars/db/vault.yml

```

### 3. View without editing:

```bash
ansible-vault view group_vars/db/vault.yml

```

### 4. Encrypt an existing file:

First, create a normal, plain-text file to act as our existing file:

```bash
echo "backup_token: abc-123-xyz" > group_vars/db/secrets.yml

```

Then, encrypt that existing file (it will prompt you for a password):

```bash
ansible-vault encrypt group_vars/db/secrets.yml

```

You can verify it worked by reading the file. You will see an `$ANSIBLE_VAULT` header instead of the plain text:

```bash
cat group_vars/db/secrets.yml

```
<img width="1262" height="1228" alt="image" src="https://github.com/user-attachments/assets/596917ec-05ed-4e84-bb65-dd7e736db94d" />


### 5. Use vault variables in a playbook

Create `db-setup.yml`:

```yaml

- name: Configure database
  hosts: db
  become: true

  tasks:
    - name: Show DB password (never do this in production)
      debug:
        msg: "DB password is set: {{ vault_db_password | length > 0 }}"

```

Run with the vault password:

```bash
ansible-playbook -i inventory.ini db-setup.yml --ask-vault-pass

```

<img width="1954" height="634" alt="image" src="https://github.com/user-attachments/assets/06be5ee0-5599-4d38-b691-fcdd372ca1e5" />


### 6. Use a password file (better for CI/CD):

```bash
echo "YourVaultPassword" > .vault_pass
chmod 600 .vault_pass
echo ".vault_pass" >> .gitignore
```

```
ansible-playbook -i inventory.ini db-setup.yml --vault-password-file .vault_pass
```

Or set it in `ansible.cfg`:

```ini
[defaults]
vault_password_file = .vault_pass

```

### 🧠 Why is `--vault-password-file` better than `--ask-vault-pass` for automated pipelines?

It allows headless execution in CI/CD pipelines where manual interaction (prompting for a password) is impossible.

---

## 📌 Task 6: Combine Roles, Templates, and Vault

Write a complete `site.yml` that uses everything you learned today:

### 1. Create `site.yml`

```yaml

- name: Configure web servers
  hosts: web
  become: true
  roles:
    - role: webserver
      vars:
        app_name: terraweek
        http_port: 80

- name: Configure app servers with Docker
  hosts: app
  become: true
  roles:
    - geerlingguy.docker

- name: Configure database servers
  hosts: db
  become: true
  vars_files:
    - group_vars/db/vault.yml
  tasks:
    - name: Create DB config with secrets
      template:
        src: templates/db-config.j2
        dest: /etc/db-config.env
        owner: root
        mode: '0600'

```

### 2. Create `templates/db-config.j2`:

```jinja2
# Database Configuration -- Managed by Ansible
DB_HOST={{ ansible_default_ipv4.address }}
DB_PORT={{ db_port | default(3306) }}
DB_PASSWORD={{ vault_db_password }}
DB_ROOT_PASSWORD={{ vault_db_root_password }}

```

### 🚀 Execution & Verification

Run the playbook:

```bash
ansible-playbook -i inventory.ini site.yml --ask-vault-pass
```

<img width="3412" height="536" alt="image" src="https://github.com/user-attachments/assets/9e22ab6f-f202-4552-bc26-d8021d300944" />

**Verify:** SSH into the db server and check `/etc/db-config.env`. Are the secrets rendered correctly? Is the file permission `600`?

---
