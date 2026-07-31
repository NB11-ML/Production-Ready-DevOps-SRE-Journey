# 🐧 Day 09: Linux User Management & Security

Part of the **[Production-Ready DevOps & SRE Journey](https://github.com)** core curriculum.

---

### 📂 Directory Architecture

```text
Production-Ready-DevOps-SRE-Journey/
└── Day-09/
    ├── 📄 01-Day-09-user-management.md    # Core Architecture Manual
    ├── 📝 02-Day09-CheatSheet.md          # Terminal Quick Reference Sheet
    └── 📖 README.md                       # Module Navigator (This File)
```
---

### 🛠️ Core Learning Objectives

* **Account Identity Lifecycle:** Mastering isolated user environments through programmatic creation (`useradd`), modification (`usermod`), and sanitation deletion routines (`userdel`).
* **Privilege Separation Boundary:** Implementing administrative security context escalation rules securely using the `visudo` editor parser.
* **Access Control Matrices:** Extending standard POSIX permission patterns into advanced network filesystem Access Control Lists (`getfacl` / `setfacl`).

---

### 🚀 Production Deployment Snippets

#### 1. Isolated Group & User Provisioning
Initialize a structured operational engineering group and map a clean automated workflow deployment profile:
```bash
# Create the secure infrastructure target group
sudo groupadd DevOpsEngineers

# Deploy the deployment actor profile with an isolated home space and bash access
sudo useradd -m -s /bin/bash deploy_user

# Bind the user context to your supplementary engineering team matrix
sudo usermod -aG DevOpsEngineers deploy_user
```

#### 2. Non-Interactive Pipeline Execution Escalation
To safely grant passwordless automation runtime bounds to your deployment instance, configure the system policy space:
```bash
# Securely open the system sudoers matrix profile via the system validator
sudo visudo
```
*Append the following security string directive at the bottom of the config workspace:*
```text
deploy_user ALL=(ALL) NOPASSWD: ALL
```

---

### 🎯 Structured Practical Lab

1. **Workspace Setup:** Create an absolute shared team assets hub path at `/data/shared_ops`.
2. **Standard Lockdown Layer:** Deny ambient system readable parameters across untrusted guest tiers:
   ```bash
   sudo chmod 770 /data/shared_ops
   ```
3. **Advanced ACL Application:** Inject explicit execution footprints tracking down your active target profiles cleanly without corrupting parent baseline directory groups:
   ```bash
   sudo setfacl -m u:deploy_user:rwx /data/shared_ops
   ```
