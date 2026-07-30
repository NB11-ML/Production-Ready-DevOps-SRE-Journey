# Day 08: Cloud Deployment Essentials & Web Application Setup

Welcome to **Day 08** of the [Production-Ready DevOps & SRE Journey](https://github.com/NB11-ML/Production-Ready-DevOps-SRE-Journey)! In this module, we transition local applications to cloud infrastructure—covering virtual machine provisioning, network security, SSH authentication, and web server deployment.

---

## 📂 Module Directory Structure

```text
Day-08/
├── README.md
├── day-08-cloud-deployment.md
└── day-08-cloud-deployment-cheatsheet.md

```

---

## 📌 Module Contents

| File | Description |
| --- | --- |
| **`README.md`** | Overview, quick start guide, architectural concepts, and learning checklist. |
| **`day-08-cloud-deployment.md`** | Complete step-by-step hands-on tutorial for deploying on AWS EC2. |
| **`day-08-cloud-deployment-cheatsheet.md`** | Quick reference guide for commands, Nginx config, and troubleshooting. |

---

## 🏗️ Core Architectural Concepts

* **Infrastructure as a Service (IaaS):** Full administrative control over virtual compute, operating systems, and runtimes (AWS EC2).
* **Amazon Machine Image (AMI):** Pre-configured template containing the OS (Ubuntu 24.04 LTS) and system dependencies.
* **Security Group:** A stateful virtual firewall regulating inbound (ingress) and outbound (egress) network traffic.
* **Key Pair:** Asymmetric SSH key pair (`.pem`) for secure, passwordless server authentication.

---

## 🚀 Quick Start Guide

### 1. Connect via SSH

Set strict key permissions and log into your AWS EC2 instance:

```bash
chmod 400 devops-day08-key.pem
ssh -i "devops-day08-key.pem" ubuntu@<YOUR_EC2_PUBLIC_IP>

```

### 2. Install & Start Nginx

```bash
sudo apt update -y && sudo apt install nginx -y
sudo systemctl enable --now nginx

```

### 3. Deploy Application Page

```bash
cat << 'EOF' | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>DevOps & SRE Journey | Day 08</title>
    <style>
        body { font-family: sans-serif; background-color: #0f172a; color: #f8fafc; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
        .card { background: #1e293b; padding: 40px; border-radius: 12px; border: 1px solid #334155; text-align: center; max-width: 480px; }
        h1 { color: #38bdf8; }
        p { color: #94a3b8; }
    </style>
</head>
<body>
    <div class="card">
        <h1>🚀 Application Live on AWS EC2!</h1>
        <p>Day 08 | Production-Ready DevOps & SRE Journey</p>
    </div>
</body>
</html>
EOF

```

---

## 🔐 Security & Firewall Setup

Configure the **Inbound Rules** in your AWS Security Group:

| Port | Protocol | Source | Purpose |
| --- | --- | --- | --- |
| **22** | TCP | `My IP` (`<YOUR_IP>/32`) | Secure SSH Management |
| **80** | TCP | `0.0.0.0/0` | Public Web Traffic (HTTP) |
| **443** | TCP | `0.0.0.0/0` | Secure Web Traffic (HTTPS) |

> ⚠️ **Important:** Add `*.pem` to your `.gitignore` file. Never commit SSH private keys or cloud credentials.

---

## ⚡ Quick Troubleshooting

* **`Permission denied (publickey)`:** Ensure key permissions are set (`chmod 400 key.pem`) and the username is `ubuntu`.
* **SSH Connection Timeout:** Check AWS Security Group to ensure Port **22** is open for your IP address.
* **Web Page Unreachable:** Verify Port **80** is open in the Security Group and Nginx is running (`sudo systemctl status nginx`).

---

## ✅ Learning Checklist

* [x] Provision an AWS EC2 instance (Ubuntu 24.04 LTS)
* [x] Configure Security Group rules for SSH and HTTP
* [x] Connect securely over SSH using asymmetric key pair
* [x] Install and configure Nginx web server
* [x] Deploy custom application page and verify via public IP

```

```
