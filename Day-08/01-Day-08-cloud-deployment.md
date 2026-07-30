# :cloud: Day 08: Cloud Deployment Essentials & Hands-on App Deployment

Welcome to **Day 8** of the #90DaysOfDevOps Challenge! Today, we bridge local development with the cloud. Cloud deployment is a core skill for any DevOps engineer, transforming local applications into globally accessible, highly available, scalable, and resilient services.

---

## 📌 Table of Contents
1. [Cloud Service & Deployment Models](#1-cloud-service--deployment-models)
2. [Deep Dive: Core AWS Infrastructure Components](#2-deep-dive-core-aws-infrastructure-components)
3. [Step-by-Step Practical Lab: Deploying a Web Application](#3-step-by-step-practical-lab-deploying-a-web-application)
    * [Step 1: Launch an AWS EC2 Instance](#step-1-launch-an-aws-ec2-instance)
    * [Step 2: Configure Networking & Security Groups](#step-2-configure-networking--security-groups)
    * [Step 3: Establish SSH Connection](#step-3-establish-ssh-connection)
    * [Step 4: Provision Web Server & Deploy Code](#step-4-provision-web-server--deploy-code)
    * [Step 5: Verify & Validate Deployment](#step-5-verify--validate-deployment)
4. [Production Best Practices & Security Guidelines](#4-production-best-practices--security-guidelines)
5. [Troubleshooting Common Issues](#5-troubleshooting-common-issues)
6. [Day 08 Tasks & Submissions](#6-day-08-tasks--submissions)

---

## 1. Cloud Service & Deployment Models

Understanding where and how your workload runs is the fundamental starting point for cloud architecture.

### Cloud Service Models


```

+-------------------------------------------------------+
|                     SaaS / Serverless                 |  (Software/Function Level)
+-------------------------------------------------------+
|                         PaaS                          |  (Platform Level - Code Only)
+-------------------------------------------------------+
|                         IaaS                          |  (Infrastructure Level - OS & VM)
+-------------------------------------------------------+

```

| Model | Full Name | Management Scope | Ideal Use Case | Industry Examples |
| :--- | :--- | :--- | :--- | :--- |
| **IaaS** | Infrastructure as a Service | Provider manages physical hardware/virtualization; **You manage OS, runtime, data, and apps.** | Complete control over OS configuration, legacy app migrations, custom networking setup. | AWS EC2, Azure Virtual Machines, GCP Compute Engine |
| **PaaS** | Platform as a Service | Provider manages OS, database engine, runtime environment; **You manage code and data.** | Rapid deployment, microservices, developers focusing purely on writing business logic. | AWS Elastic Beanstalk, Heroku, Google App Engine |
| **SaaS** | Software as a Service | Provider manages entire stack; **You manage configurations and end users.** | Ready-to-use business software accessible via browser or API. | Microsoft 365, Salesforce, Google Workspace |

### Cloud Deployment Strategies

* **Public Cloud:** Multi-tenant infrastructure operated by cloud service providers over the public internet (e.g., AWS, GCP, Azure). Offers high scalability and pay-as-you-go pricing.
* **Private Cloud:** Dedicated cloud infrastructure strictly used by a single enterprise (e.g., OpenStack, VMware Cloud Foundation). Common in strict compliance environments.
* **Hybrid Cloud:** Integrates private and public cloud infrastructure to allow data and app sharing based on privacy and compliance needs.
* **Multi-Cloud:** Combining services across two or more public cloud vendors to avoid vendor lock-in and leverage specific feature strengths.

---

## 2. Deep Dive: Core AWS Infrastructure Components

Before provisioning cloud compute resources, let's dissect the core foundational primitives involved in launching a cloud virtual server:

* **AMI (Amazon Machine Image):** A pre-packaged, read-only template containing an Operating System (e.g., Ubuntu, Amazon Linux, RHEL), application server, and pre-configured software packages needed to boot an instance.
* **Instance Type:** Defines the hardware capabilities of the host server allocated to your Virtual Machine. 
  * *Example:* `t2.micro` provides 1 vCPU and 1 GiB RAM (ideal for light workloads and Free Tier).
* **Key Pair:** Uses asymmetric cryptography (Public/Private keys) to authorize SSH connections. The public key is stored inside `~/.ssh/authorized_keys` on the remote instance, while you keep the private `.pem` file locally.
* **Security Group:** A stateful virtual firewall controlling inbound (ingress) and outbound (egress) network traffic at the instance interface level.
* **VPC (Virtual Private Cloud):** An isolated virtual network dedicated to your cloud resources, defining IP address ranges (CIDR blocks), subnets, and routing tables.

---

## 3. Step-by-Step Practical Lab: Deploying a Web Application

In this lab, we will launch an AWS EC2 instance running **Ubuntu 24.04 LTS**, configure network firewalls, securely authenticate via SSH, install an **Nginx** web server, and deploy a responsive static web application.

---

### Step 1: Launch an AWS EC2 Instance

1. Log into your **AWS Management Console**.
2. In the top search bar, type `EC2` and navigate to the **EC2 Dashboard**.
3. Click the **Launch Instance** button.
4. Configure the basic settings:
   * **Name:** `DevOps-Day08-Server`
   * **Application and OS Images (AMI):** Select **Ubuntu** -> **Ubuntu Server 24.04 LTS (HVM), SSD Volume Type** (Free Tier Eligible).
   * **Instance Type:** Choose `t2.micro` or `t3.micro`.
   * **Key Pair (login):**
     * Click **Create new key pair**.
     * **Key pair name:** `devops-day08-key`
     * **Key pair type:** `RSA`
     * **Private key file format:** `.pem` (for SSH on OpenSSH terminal) or `.ppk` (if using PuTTY on Windows).
     * Click **Create Key Pair** and save the file securely on your computer.

---

### Step 2: Configure Networking & Security Groups

Under the **Network settings** panel on the instance launch page:

1. Ensure **Auto-assign public IP** is set to **Enable**.
2. Select **Create security group**.
3. Configure the following Inbound Security Group Rules:

| Type | Protocol | Port Range | Source Type | Source / CIDR | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **SSH** | TCP | `22` | My IP | `<YOUR_LOCAL_IP>/32` | Administrative SSH Access |
| **HTTP** | TCP | `80` | Anywhere | `0.0.0.0/0` | Public Web Traffic Access |
| **HTTPS** | TCP | `443` | Anywhere | `0.0.0.0/0` | Secure SSL/TLS Traffic |

4. Under **Configure Storage**, keep the default **8 GiB gp3/gp2 Root Volume**.
5. Click **Launch Instance**.

---

### Step 3: Establish SSH Connection

1. Open your terminal (macOS/Linux Terminal, Git Bash, or WSL on Windows).
2. Navigate to the folder where your private key (`.pem`) was downloaded:

```bash
   cd ~/Downloads

```

3. Update the key permissions to ensure it is not publicly viewable (required by SSH clients):
```bash
chmod 400 devops-day08-key.pem

```


4. Obtain the **Public IPv4 address** of your server from the EC2 instance list.
5. Connect to the EC2 instance:
```bash
ssh -i "devops-day08-key.pem" ubuntu@<YOUR_EC2_PUBLIC_IP>

```


6. Type `yes` when prompted to verify the host authenticity.

---

### Step 4: Provision Web Server & Deploy Code

Once connected via SSH, run the following automated provisioning steps:

#### 1. System Package Updates

```bash
# Refresh package indexes and upgrade installed software
sudo apt update -y && sudo apt upgrade -y

```

#### 2. Install and Start Nginx

```bash
# Install Nginx web server
sudo apt install nginx -y

# Verify Nginx service status
sudo systemctl status nginx --no-pager

# Ensure Nginx starts automatically on server reboot
sudo systemctl enable nginx
sudo systemctl start nginx

# Logs:

sudo cat /var/log/nginx/* | head -n 20: Viewing the first 20 lines of nginx access and error logs.
sudo cat /var/log/nginx/access.log > ~/nginx-logs.txt: Saving the Nginx access log file to a local directory on the server.
scp: Secure Copy for transferring files between machines.

```

#### 3. Deploy the Sample Web Application

Create a custom web landing page inside `/var/www/html/`:

```bash
cat << 'EOF' | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Day 08 - DevOps Cloud Deployment</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0f172a; color: #f8fafc; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        .card { background: #1e293b; padding: 40px; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; text-align: center; max-width: 500px; }
        .badge { background: #0284c7; color: #fff; font-size: 0.85rem; padding: 6px 12px; border-radius: 20px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
        h1 { margin-top: 20px; font-size: 1.8rem; color: #38bdf8; }
        p { margin-top: 15px; color: #94a3b8; line-height: 1.6; }
        .footer { margin-top: 25px; font-size: 0.8rem; color: #64748b; border-top: 1px solid #334155; padding-top: 15px; }
    </style>
</head>
<body>
    <div class="card">
        <span class="badge">Success</span>
        <h1>🚀 App Live on AWS EC2!</h1>
        <p>Congratulations! You have successfully launched, configured, and deployed a cloud-hosted web application on Ubuntu using Nginx.</p>
        <div class="footer">
            Day 08 | #90DaysOfDevOps Challenge
        </div>
    </div>
</body>
</html>
EOF

```

---

### Step 5: Verify & Validate Deployment

1. Copy your EC2 Instance's **Public IPv4 Address**.
2. Open any web browser and enter the address using the `http://` protocol:
```text
http://<YOUR_EC2_PUBLIC_IP>

```


3. You should see the newly deployed web page rendering in your browser.

---

## 4. Production Best Practices & Security Guidelines

> ⚠️ **DevOps & Cloud Security Directives:**
> 1. **Never Commit Secrets or Private Keys:** Add `*.pem`, `*.ppk`, `.env`, and credential files to your `.gitignore` repository file.
> 2. **Restrict SSH Inbound Access:** Always restrict Port `22` access in your Security Group to your specific IP address (`/32`), never leaving it exposed to `0.0.0.0/0`.
> 3. **Implement Least Privilege (IAM):** Avoid using account root credentials for automated deployments. Create IAM Users/Roles with minimal required policy permissions.
> 4. **Instance Lifecycle & Cost Management:** Always **Stop** or **Terminate** instances when testing is completed to avoid unexpected AWS usage charges.
> 
> 

---

## 5. Troubleshooting Common Issues

### Issue 1: SSH Connection Timeout (`Operation timed out`)

* **Cause:** The Security Group inbound rule for port `22` is missing, misconfigured, or blocking your current public IP address.
* **Fix:** Go to **EC2 Console -> Security Groups -> Edit Inbound Rules**, update SSH (Port 22) source to **My IP**, and save rules.

### Issue 2: Web Application Not Loading in Browser (`ERR_CONNECTION_REFUSED` / Timeout)

* **Cause:** Nginx service is stopped, or HTTP Port `80` is not open in the Security Group.
* **Fix:**
1. Ensure HTTP Port `80` is added to Inbound Rules for `0.0.0.0/0`.
2. Run `sudo systemctl restart nginx` via SSH to confirm the web service is active.



### Issue 3: `Permission denied (publickey)`

* **Cause:** Incorrect `.pem` file specified, bad permissions on the `.pem` file, or incorrect remote SSH user (e.g., using `root` instead of `ubuntu`).
* **Fix:**
* Run `chmod 400 devops-day08-key.pem`.
* Ensure user is specified as `ubuntu@<IP>` for Ubuntu instances.



---

## 6. Day 08 Tasks & Submissions

* [ ] Provision a cloud VM (AWS EC2 / Azure VM / GCP Compute Instance).
* [ ] Establish SSH access using private key authentication.
* [ ] Configure security group/firewall rules to permit HTTP (Port 80) traffic.
* [ ] Install and configure Nginx web server.
* [ ] Deploy custom HTML content to `/var/www/html/`.
* [ ] Capture terminal connection logs and web browser verification screenshots.
* [ ] Post your progress on LinkedIn/Twitter/Hashnode using `#90DaysOfDevOps`.

```
