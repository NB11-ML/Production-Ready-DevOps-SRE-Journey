# ⚡ DevOps & Cloud Deployment (AWS EC2) — Quick Reference Cheatsheet

A concise, single-page reference for cloud compute concepts, essential terminal commands, Nginx management, and troubleshooting.

---

## 📌 1. Core Cloud Concepts

| Term | Category | Key Concept |
| --- | --- | --- |
| **IaaS** | Cloud Model | Infrastructure as a Service — Full control over virtual machines, OS, and networking (e.g., AWS EC2, Azure VMs). |
| **PaaS** | Cloud Model | Platform as a Service — Managed platform where you only manage code and data (e.g., AWS Elastic Beanstalk, Heroku). |
| **SaaS** | Cloud Model | Software as a Service — On-demand, fully managed web applications (e.g., Google Workspace, Microsoft 365). |
| **AMI** | AWS Compute | Amazon Machine Image — Pre-configured OS/software template used to boot instances. |
| **Security Group** | AWS Security | Stateful virtual firewall controlling inbound/outbound traffic at the instance level. |
| **Key Pair** | Authentication | Asymmetric SSH key pair (`.pem` / `.ppk`) used for secure, passwordless server access. |

---

## 💻 2. Server Administration & SSH Commands

### SSH Access

```bash
# Set required restrictive permissions for private key
chmod 400 devops-day08-key.pem

# SSH into an Ubuntu EC2 instance
ssh -i devops-day08-key.pem ubuntu@<EC2_PUBLIC_IP>

# SSH into an Amazon Linux / RHEL instance
ssh -i devops-day08-key.pem ec2-user@<EC2_PUBLIC_IP>

```

### Package Management (Ubuntu/Debian)

```bash
# Update local repository indexes
sudo apt update -y

# Upgrade installed system packages
sudo apt upgrade -y

# Install key tools (Nginx, Curl, Git)
sudo apt install nginx curl git -y

```

### Systemd Service Commands

```bash
# Check service status
sudo systemctl status nginx

# Start / Stop / Restart service
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# Enable service to auto-start on system boot
sudo systemctl enable nginx

```

---

## 🌐 3. Nginx Cheat Sheet

```bash
# Test Nginx configuration for syntax errors
sudo nginx -t

# Reload configuration without dropping active connections
sudo systemctl reload nginx

# Web Root Directory (Static Files)
/var/www/html/index.html

# Primary Nginx Configuration File
/etc/nginx/nginx.conf

```

---

## 🔐 4. Firewall & Port Reference

| Port | Protocol | Default Service | Recommended Inbound Source |
| --- | --- | --- | --- |
| **22** | TCP | SSH Access | `My IP` (`<YOUR_IP>/32`) |
| **80** | TCP | HTTP Web Traffic | `0.0.0.0/0` (Public) |
| **443** | TCP | HTTPS (SSL/TLS) | `0.0.0.0/0` (Public) |

---

## 🚨 5. Rapid Troubleshooting

* **`Permission denied (publickey)`**
* *Fix:* Run `chmod 400 key.pem` and verify the username (`ubuntu` for Ubuntu, `ec2-user` for Amazon Linux).


* **SSH Connection Times Out (`Operation timed out`)**
* *Fix:* Open AWS Console -> Security Groups -> Add an **Inbound Rule** for **SSH (Port 22)** pointing to your IP.


* **Browser Error `ERR_CONNECTION_REFUSED**`
* *Fix:* Ensure HTTP Port 80 is allowed in your Security Group and verify Nginx is running (`sudo systemctl status nginx`).
