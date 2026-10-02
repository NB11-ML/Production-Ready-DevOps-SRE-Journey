# ⚙️ Day 72 Complete Ansible Project – Automating Docker & Nginx Reverse Proxy

Welcome to Day 72! Over the past five days, we’ve covered every foundational pillar of Ansible. Today, we bring everything together into a single production-style project: provisioning a clean server, installing common baseline utilities, setting up Docker, deploying a containerized application, configuring Nginx as a reverse proxy, and securing credentials using Ansible Vault—all executed with a single master playbook command.

## 📐 System Architecture

This runbook deploys the following infrastructure topology using an idempotent master playbook:

```text
+-----------------------+              +-----------------------------------------+
|  Ansible Control Node |              |         Target Server (web-server)      |
|  (Local Environment)  | ===(SSH)===> |                                         |
|                       |              |  [ Nginx Reverse Proxy ] (Port 80)      |
|  - site.yml           |              |           |                             |
|  - Ansible Vault      |              |      (Proxy Pass)                       |
|  - Ansible Roles      |              |           v                             |
+-----------------------+              |  [ Docker Container ] (Port 8080)       |
                                       |  - target_app (nginx:latest)            |
                                       +-----------------------------------------+

```

---

### 🏗️ Project Directory Structure

You can quickly scaffold this exact professional directory layout using a combination of standard Linux commands for the top-level files and `ansible-galaxy` to automatically generate the role directories.

**Run these commands to generate the workspace:**

```bash
# 1. Create the top-level project and variables directories
mkdir -p ansible-docker-project/group_vars/web
mkdir -p ansible-docker-project/roles
cd ansible-docker-project

# 2. Create the empty root configuration files
touch ansible.cfg inventory.ini site.yml .vault_pass
touch group_vars/all.yml group_vars/web/vars.yml

# 3. Use Ansible Galaxy to automatically scaffold the role folders
ansible-galaxy init roles/common
ansible-galaxy init roles/docker
ansible-galaxy init roles/nginx

```

**The resulting structure will look like this:**

```text
ansible-docker-project/
├── ansible.cfg
├── inventory.ini
├── site.yml
├── .vault_pass
├── group_vars/
│   ├── all.yml
│   └── web/
│       ├── vars.yml
│       └── vault.yml
└── roles/
    ├── common/          # (Scaffolded by Ansible Galaxy)
    │   └── tasks/
    │       └── main.yml
    ├── docker/          # (Scaffolded by Ansible Galaxy)
    │   ├── defaults/
    │   │   └── main.yml
    │   ├── handlers/
    │   │   └── main.yml
    │   └── tasks/
    │       └── main.yml
    └── nginx/           # (Scaffolded by Ansible Galaxy)
        ├── defaults/
        │   └── main.yml
        ├── handlers/
        │   └── main.yml
        ├── tasks/
        │   └── main.yml
        └── templates/
            ├── nginx.conf.j2
            └── app-proxy.conf.j2

```

## 📌 Task 1: Configuration & Global Variables

**1. Ansible Configuration (ansible.cfg)**

```ini

[defaults]
inventory = inventory.ini
host_key_checking = False
vault_password_file = .vault_pass
retry_files_enabled = False

```

**2. Inventory (inventory.ini)**

```ini

[web]
web-server ansible_host=10.0.1.167 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

```

**3. Global Variables (group_vars/all.yml)**

```yaml

timezone: "Asia/Kolkata"
project_name: "devops-app"
app_env: "development"
common_packages:
  - vim
  - curl
  - wget
  - git
  - htop
  - tree
  - jq
  - unzip

```

## 📌 Task 2: Build the Common Role

**Role Tasks (roles/common/tasks/main.yml)**

```yaml

- name: Update package cache (Ubuntu)
  apt:
    update_cache: yes
    cache_valid_time: 3600
  tags: common

- name: Install common baseline packages
  apt:
    name: "{{ item }}"
    state: present
  loop: "{{ common_packages }}"
  tags: common

- name: Set system hostname
  hostname:
    name: "{{ inventory_hostname }}"
  tags: common

- name: Set system timezone
  timezone:
    name: "{{ timezone }}"
  tags: common

- name: Create dedicated deploy user
  user:
    name: deploy
    shell: /bin/bash
    state: present
  tags: common

```

## 📌 Task 3: Build the Docker Role

**1. Role Variable Defaults (roles/docker/defaults/main.yml)**

```yaml

docker_app_image: "nginx"
docker_app_tag: "latest"
docker_app_name: "myapp"
docker_app_port: 8080
docker_container_port: 80

```

**2. Role Tasks (roles/docker/tasks/main.yml)**

```yaml

- name: Install prerequisite packages for Docker
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
    state: present
  tags: docker

- name: Create keyrings directory
  file:
    path: /etc/apt/keyrings
    state: directory
    mode: '0755'
  tags: docker

- name: Add Docker official GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present
  tags: docker

- name: Set up Docker stable repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present
  tags: docker

- name: Install Docker Engine
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-compose-plugin
    state: present
    update_cache: yes
  tags: docker

- name: Ensure Docker service is started and enabled
  service:
    name: docker
    state: started
    enabled: true
  tags: docker

- name: Add deploy user to docker group
  user:
    name: deploy
    groups: docker
    append: true
  tags: docker

- name: Log in to Docker Hub using encrypted Vault credentials
  community.docker.docker_login:
    username: "{{ vault_docker_username }}"
    password: "{{ vault_docker_password }}"
  become_user: deploy
  when: vault_docker_username is defined
  tags: docker

- name: Pull target application image
  community.docker.docker_image:
    name: "{{ docker_app_image }}"
    tag: "{{ docker_app_tag }}"
    source: pull
  tags: docker

- name: Run containerized application
  community.docker.docker_container:
    name: "{{ docker_app_name }}"
    image: "{{ docker_app_image }}:{{ docker_app_tag }}"
    state: started
    restart_policy: always
    ports:
      - "{{ docker_app_port }}:{{ docker_container_port }}"
  tags: docker

- name: Perform local health check on container port
  uri:
    url: "http://localhost:{{ docker_app_port }}"
    status_code: 200
  retries: 5
  delay: 3
  register: health_check
  until: health_check.status == 200
  tags: docker

```

**3. Role Handlers (roles/docker/handlers/main.yml)**

```yaml

- name: Restart Docker
  service:
    name: docker
    state: restarted

```

## 📌 Task 4: Build the Nginx Role

**1. Role Variable Defaults (roles/nginx/defaults/main.yml)**

```yaml

nginx_http_port: 80
nginx_upstream_port: 8080
nginx_server_name: "_"

```

**2. Role Tasks (roles/nginx/tasks/main.yml)**

```yaml

- name: Install Nginx web server
  apt:
    name: nginx
    state: present
  tags: nginx

- name: Remove default Ubuntu Nginx site configuration
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify: Reload Nginx
  tags: nginx

- name: Deploy Nginx reverse proxy configuration template
  template:
    src: app-proxy.conf.j2
    dest: /etc/nginx/conf.d/{{ project_name }}-proxy.conf
    owner: root
    group: root
    mode: '0644'
  notify: Reload Nginx
  tags: nginx

- name: Test Nginx configuration syntax
  command: nginx -t
  changed_when: false
  tags: nginx

- name: Ensure Nginx service is running and enabled
  service:
    name: nginx
    state: started
    enabled: true
  tags: nginx

```

**3. Role Handlers (roles/nginx/handlers/main.yml)**

```yaml

- name: Reload Nginx
  service:
    name: nginx
    state: reloaded

- name: Restart Nginx
  service:
    name: nginx
    state: restarted

```

**4. Role Templates (roles/nginx/templates/app-proxy.conf.j2)**

```nginx

# Reverse Proxy to Docker Container -- Managed by Ansible
upstream docker_app {
    server 127.0.0.1:{{ nginx_upstream_port }};
}

server {
    listen {{ nginx_http_port }};
    server_name {{ nginx_server_name }};

    location / {
        proxy_pass http://docker_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        access_log off;
        return 200 'OK';
        add_header Content-Type text/plain;
    }

{% if app_env == 'production' %}
    access_log /var/log/nginx/{{ project_name }}_access.log;
    error_log /var/log/nginx/{{ project_name }}_error.log;
{% else %}
    access_log /var/log/nginx/{{ project_name }}_access.log;
    error_log /var/log/nginx/{{ project_name }}_error.log debug;
{% endif %}
}

```

## 📌 Task 5: Encrypt Docker Hub Credentials with Vault

1. Create the vault configuration file:

```bash

ansible-vault create group_vars/web/vault.yml

```

2. Store encrypted values inside:

```yaml

vault_docker_username: "your-dockerhub-username"
vault_docker_password: "your-dockerhub-token"

```

3. Automate vault decryption using a local password file `.vault_pass` secured with `chmod 600` permissions.

## 📌 Task 6: Write the Master Playbook and Deploy

**Master Playbook (site.yml)**

```yaml

- name: Apply common infrastructure baseline configuration
  hosts: all
  become: true
  roles:
    - common
  tags: common

- name: Install Docker and run target containers
  hosts: web
  become: true
  roles:
    - docker
  tags: docker

- name: Configure Nginx reverse proxy layer
  hosts: web
  become: true
  roles:
    - nginx
  tags: nginx

```

## 🚀 Execution & Verification

**Dry Run (Syntax & Change Validation)**
Always execute a dry-run with diff output preview before deploying changes to a live target:

```bash

ansible-playbook site.yml --check --diff

```

**Full Deployment**
Execute the complete automation stack:

```bash

ansible-playbook site.yml

```
<img width="3038" height="1890" alt="image" src="https://github.com/user-attachments/assets/dbaafdb9-958d-4134-b05f-71e8d0ccf64f" />


**Selective Execution via Tags**

```bash

# Run only Docker orchestration
ansible-playbook site.yml --tags docker

# Update Nginx layer independently
ansible-playbook site.yml --tags nginx

```

<img width="1642" height="1472" alt="image" src="https://github.com/user-attachments/assets/6b9637b0-f1e1-4f45-8533-34c42c944a92" />

<img width="1714" height="988" alt="image" src="https://github.com/user-attachments/assets/fa43631e-484e-4a18-9e01-eb6805f075d2" />


**Verification Commands on the Target Node**

```bash

# Verify container runtime status via Docker
sudo docker ps

# Direct connection test to upstream container port
curl http://localhost:8080

# End-to-end proxy validation through Nginx port 80
curl http://localhost

```

## 📊 Project Reflection & Concept Breakdown

This project bridges 11 years of infrastructure engineering experience with modern SRE practices by combining the following automation concepts:

| Timeline | Core Concept Learned | Application in Day 72 Project |
| --- | --- | --- |
| **Day 68** | Inventory, Ad-hoc Commands, SSH | Configured `inventory.ini` and passwordless SSH authentication to establish the control plane. |
| **Day 69** | Playbooks, Modules, Handlers | Defined idempotent state management tasks and Nginx service reload notifications. |
| **Day 70** | Variables, Facts, Conditionals, Loops | Leveraged `group_vars/all.yml` and conditional Jinja2 logging logic based on `app_env`. |
| **Day 71** | Roles, Templates, Galaxy, Vault | Structured project into reusable roles, dynamic proxy templates, and encrypted secrets. |
| **Day 72** | **End-to-End Execution** | Combined all modular components into a single, automated production deployment pipeline. |

---

```
