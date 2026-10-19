# 🚀 Production-Ready DevOps & SRE Journey (2026 Edition)

![Status](https://img.shields.io/badge/90DaysOfDevOps-90%2F90%20Completed-brightgreen?style=for-the-badge&logo=checkmarx)
![Cloud](https://img.shields.io/badge/Cloud-AWS%20%7C%20EKS-FF9900?style=for-the-badge&logo=amazonaws)
![IaC](https://img.shields.io/badge/IaC-Terraform%20%7C%20Ansible-7B42BC?style=for-the-badge&logo=terraform)
![Containers](https://img.shields.io/badge/Orchestration-Kubernetes%20%7C%20Docker%20%7C%20Helm-326CE5?style=for-the-badge&logo=kubernetes)
![GitOps](https://img.shields.io/badge/GitOps-Argo%20CD%20%7C%20GitHub%20Actions-EF7B4D?style=for-the-badge&logo=argo)
![AIOps](https://img.shields.io/badge/AIOps-Temporal%20%7C%20MCP%20%7C%20Claude-000000?style=for-the-badge&logo=anthropic)

Welcome to my **90-day structured engineering portfolio** focused on production-grade DevOps, Site Reliability Engineering (SRE), Cloud-Native GitOps, and Agentic AI Operations (AIOps).

This repository documents the end-to-end transition from "using tools" to **engineering resilient, self-healing, and observable distributed systems**. Every milestone contains core architectural concepts, production runbooks, Infrastructure as Code (IaC) manifests, and real-world troubleshooting scenarios.

---

## 🎯 The Engineering Mission

The goal of this journey—inspired by the **#90DaysOfDevOps** initiative—is to build production-grade proficiency across six pillars:
- 🚀 **Production-Focused DevOps:** Moving beyond local sandboxes to highly available, secure, multi-environment architectures.
- 🏗️ **Infrastructure as Code (IaC):** Provisioning reproducible cloud infrastructure with **Terraform** (remote state locking, custom modules) and automating configuration management with **Ansible**.
- 📦 **Container Orchestration & Packaging:** Deep diving into **Docker**, **Kubernetes (EKS)**, stateful storage (PV/PVC, EBS CSI), Gateway API, and **Helm** packaging.
- 🔄 **CI/CD & GitOps Mastery:** Building event-driven pipelines with **GitHub Actions** (DevSecOps scans, matrix builds) and declarative pull-based delivery with **Argo CD**.
- 🚨 **SRE & Full-Stack Observability:** Instrumenting metrics, logs, and traces using **Prometheus**, **Grafana**, **Loki**, **Promtail**, and **OpenTelemetry (OTEL)** to drive down MTTR.
- 🤖 **Agentic AI & AIOps:** Engineering autonomous ReAct agents, **Model Context Protocol (MCP)** tool servers, and crash-resilient self-healing Kubernetes workflows with **Temporal** and **LLMs**.

---

## 🏆 Featured Capstone Projects

Throughout the 90 days, individual skills were integrated into four production-grade reference architectures:

| Capstone Project | Days | Core Stack | Architectural Highlights |
| :--- | :--- | :--- | :--- |
| **📊 Full-Stack Observability** | Days 73–77 | Prometheus, Grafana, Loki, Promtail, cAdvisor, OTEL | Multi-container telemetry pipeline tracking golden signals, container resource saturation, centralized log aggregation, and alerting rules. |
| **🏦 AI-BankApp End-to-End GitOps** | Days 78–86 | AWS EKS, Terraform, Helm, GitHub Actions, Argo CD | Production deployment of a Spring Boot + MySQL + Ollama AI banking platform using modular Terraform EKS provisioning, custom Helm charts, and automated Argo CD syncs. |
| **🧠 Multi-Tool DevOps AI Agent & MCP** | Days 87–88 | Python, LangChain, Ollama, MCP, Docker, K8s, GitHub CLI | Autonomous diagnostic agent leveraging the Reason + Act (ReAct) loop and standardized MCP tool servers to investigate container, cluster, and CI/CD pipeline failures. |
| **🛡️ KubeHealer (Self-Healing AIOps)** | Day 89 | Temporal, Claude Sonnet 4, Python, Kubernetes (`kubectl`) | Crash-resilient AIOps orchestrator with durable execution, blast-radius scope limits, strategic deployment patching, and human-in-the-loop escalation paths. |

---

## 🛠️ Production Tech Stack

| Category | Technologies & Tools |
| :--- | :--- |
| **Cloud & Infrastructure** | AWS (VPC, EC2, EKS, IAM, S3, DynamoDB, EBS CSI) |
| **Infrastructure as Code (IaC)** | Terraform (Modules, Workspaces, Remote Backends), Ansible (Playbooks, Roles, Vault, Jinja2) |
| **Containers & Orchestration** | Docker, Docker Compose, Kubernetes (Kind, Amazon EKS), Helm, Kubernetes Gateway API |
| **CI/CD & GitOps** | GitHub Actions (Matrix Builds, Self-Hosted Runners, DevSecOps), Argo CD |
| **Observability & SRE** | Prometheus, Grafana, Loki, Promtail, Node Exporter, cAdvisor, OpenTelemetry (OTEL) |
| **Agentic AI & AIOps** | Temporal (Durable Execution), Claude Sonnet / Ollama, LangChain, Model Context Protocol (MCP) |
| **OS, Scripting & VCS** | Linux (systemd, LVM, Process/Memory Diagnostics), Bash Scripting, Python, Git, GitHub CLI (`gh`) |

---

## 🗺️ Phase-by-Phase Curriculum Summary

* **Phase 1: Systems, Networking & Scripting Foundations (Days 01–28)** — Linux kernel & `systemd`, resource troubleshooting runbooks, LVM storage, TCP/IP & DNS diagnostics, Bash automation & log analyzers, and advanced Git workflows.
* **Phase 2: Containerization & CI/CD Pipelines (Days 29–49)** — Multi-stage Dockerfiles, non-root containers, Docker Compose 3-tier stacks, GitHub Actions workflows, reusable actions, and DevSecOps pipeline gates.
* **Phase 3: Orchestration, IaC & Configuration Management (Days 50–72)** — Kubernetes workloads (Deployments, StatefulSets, HPA, Probes), modular AWS Terraform provisioning, and idempotent Ansible automation.
* **Phase 4: Observability, Amazon EKS & GitOps (Days 73–86)** — Prometheus/Grafana/Loki observability stack, custom Helm chart engineering, production AWS EKS deployments, and Argo CD GitOps reconciliation.
* **Phase 5: Agentic AI for DevOps & AIOps (Days 87–90)** — Local LLM ReAct loops, MCP servers for infrastructure tooling, and KubeHealer durable self-healing Kubernetes automation.

---

## 🗓️ Complete 90-Day Roadmap & Progress Tracker

| Day | Module | Topic | Status | Key Highlights & Deliverables |
| :--- | :--- | :--- | :--- | :--- |
| **Day 01** | Linux Fundamentals | Introduction to DevOps and Cloud | ✅ Completed | DevOps lifecycle, culture, CI/CD & SRE fundamentals |
| **Day 02** | Linux Fundamentals | Linux Architecture, Processes, and systemd | ✅ Completed | Kernel vs User space, init systems, `systemctl` service management |
| **Day 03** | Linux Fundamentals | Linux Commands Practice | ✅ Completed | Essential CLI navigation, file manipulation, and system inspection |
| **Day 04** | Linux Fundamentals | Linux Practice: Processes and Services | ✅ Completed | Process states, signals (`kill`), background jobs, and daemon control |
| **Day 05** | Linux Fundamentals | Linux Troubleshooting Drill: CPU, Memory, and Logs | ✅ Completed | Incident runbook using `top`, `vmstat`, `free`, `journalctl`, and `dmesg` |
| **Day 06** | Linux Fundamentals | Linux Fundamentals: Read and Write Text Files | ✅ Completed | Standard streams (`stdin`, `stdout`, `stderr`), redirection, `grep`, `awk`, `sed` |
| **Day 07** | Linux Fundamentals | Linux File System Hierarchy and Scenario-Based Practice | ✅ Completed | FHS navigation (`/etc`, `/var`, `/proc`), `df`, `du`, and inode exhaustion |
| **Day 08** | Linux Fundamentals | Cloud Server Setup: Docker, Nginx and Web Deployment | ✅ Completed | EC2 provisioning, SSH hardening, Nginx reverse proxy & Docker setup |
| **Day 09** | Linux Fundamentals | Linux User and Group Management Challenge | ✅ Completed | `useradd`, `usermod`, `/etc/passwd`, `/etc/sudoers`, least-privilege access |
| **Day 10** | Linux Fundamentals | File Permissions and File Operations Challenge | ✅ Completed | Octal/symbolic `chmod`, SUID/SGID/Sticky Bit, and access control |
| **Day 11** | Linux Fundamentals | File Ownership Challenge (chown and chgrp) | ✅ Completed | Multi-team directory ownership and shared group collaboration |
| **Day 12** | Linux Fundamentals | Breather and Revision (Days 01–11) | ✅ Completed | Consolidated Linux administration and troubleshooting runbooks |
| **Day 13** | Linux Fundamentals | Linux Volume Management (LVM) | ✅ Completed | Physical volumes (PV), Volume Groups (VG), Logical Volumes (LV), online resizing |
| **Day 14** | Networking | Networking Fundamentals and Hands-on Checks | ✅ Completed | OSI/TCP-IP models, `ip`, `ss`, `netstat`, `ping`, `traceroute`, `curl` |
| **Day 15** | Networking | Networking Concepts: DNS, IP, Subnets and Ports | ✅ Completed | CIDR subnetting, `dig`/`nslookup`, routing tables, and firewall rules |
| **Day 16** | Shell Scripting | Shell Scripting Basics | ✅ Completed | Shebang, variables, user input, exit codes, and script execution |
| **Day 17** | Shell Scripting | Shell Scripting: Loops, Arguments and Error Handling | ✅ Completed | `for`/`while` loops, positional parameters, `set -euo pipefail` |
| **Day 18** | Shell Scripting | Shell Scripting: Functions and Intermediate Concepts | ✅ Completed | Modular Bash functions, local scopes, and reusable logging libraries |
| **Day 19** | Shell Scripting | Shell Scripting Project: Log Rotation, Backup and Crontab | ✅ Completed | Automated compressed backups, retention pruning, and `cron` scheduling |
| **Day 20** | Shell Scripting | Bash Scripting Challenge: Log Analyzer and Report Generator | ✅ Completed | Automated parsing of error patterns, HTTP status codes, and summary reports |
| **Day 21** | Shell Scripting | Shell Scripting Cheat Sheet: Build Your Own Reference Guide | ✅ Completed | Production Bash scripting quick-reference and defensive coding guide |
| **Day 22** | Git and GitHub | Introduction to Git: Your First Repository | ✅ Completed | Git internals, staging area, commit hygiene, and remote tracking |
| **Day 23** | Git and GitHub | Git Branching and Working with GitHub | ✅ Completed | Feature branching, Pull Requests, code reviews, and conflict resolution |
| **Day 24** | Git and GitHub | Advanced Git: Merge, Rebase, Stash and Cherry Pick | ✅ Completed | Linear commit history, interactive rebase, stashing, and targeted backports |
| **Day 25** | Git and GitHub | Git Reset vs Revert and Branching Strategies | ✅ Completed | Safe production rollbacks (`revert`) vs local history rewriting (`reset`), GitFlow |
| **Day 26** | Git and GitHub | GitHub CLI: Manage GitHub from Your Terminal | ✅ Completed | Automating PRs, issues, releases, and workflow runs via `gh` CLI |
| **Day 27** | Git and GitHub | GitHub Profile Makeover: Build Your Developer Identity | ✅ Completed | Portfolio structuring, documentation standards, and repository curation |
| **Day 28** | Git and GitHub | Revision Day: Everything from Day 1 to Day 27 | ✅ Completed | End-to-end review of Linux, Networking, Bash, and Git workflows |
| **Day 29** | Docker | Introduction to Docker | ✅ Completed | Container vs VM architecture, namespaces, cgroups, and Docker Engine |
| **Day 30** | Docker | Docker Images and Container Lifecycle | ✅ Completed | Image layers, union filesystems, container states, `docker inspect` & `logs` |
| **Day 31** | Docker | Dockerfile: Build Your Own Images | ✅ Completed | Layer caching optimization, `.dockerignore`, `ENTRYPOINT` vs `CMD` |
| **Day 32** | Docker | Docker Volumes and Networking | ✅ Completed | Persistent bind mounts/volumes, custom bridge networks, container DNS |
| **Day 33** | Docker | Docker Compose: Multi-Container Basics | ✅ Completed | Declarative `docker-compose.yml`, service dependencies, and healthchecks |
| **Day 34** | Docker | Docker Compose: Real-World Multi-Container Apps | ✅ Completed | 3-tier MERN application with Nginx proxy, Node.js API, and persistent MongoDB |
| **Day 35** | Docker | Multi-Stage Builds and Docker Hub | ✅ Completed | Distroless/Alpine slimming, non-root execution, and registry publishing |
| **Day 36** | Docker | Docker Project: Dockerize a Full Application | ✅ Completed | End-to-end production containerization with health checks and env isolation |
| **Day 37** | Docker | Docker Revision and Cheat Sheet | ✅ Completed | Complete Docker CLI, Dockerfile, and Compose troubleshooting guide |
| **Day 38** | CI/CD & GitHub Actions | YAML Basics | ✅ Completed | Complex YAML structures, anchors, multi-line blocks, and schema validation |
| **Day 39** | CI/CD & GitHub Actions | What is CI/CD? | ✅ Completed | Continuous Integration, Delivery vs Deployment, and pipeline architecture |
| **Day 40** | CI/CD & GitHub Actions | Your First GitHub Actions Workflow | ✅ Completed | Events, jobs, runners, steps, and marketplace actions |
| **Day 41** | CI/CD & GitHub Actions | Triggers and Matrix Builds | ✅ Completed | Multi-OS/multi-version parallel testing strategies and path filters |
| **Day 42** | CI/CD & GitHub Actions | Runners: GitHub-Hosted and Self-Hosted | ✅ Completed | Configuring custom self-hosted Linux runners for private infrastructure |
| **Day 43** | CI/CD & GitHub Actions | Jobs, Steps, Env Vars and Conditionals | ✅ Completed | Job dependencies (`needs`), custom environment scopes, and `if` expressions |
| **Day 44** | CI/CD & GitHub Actions | Secrets, Artifacts and Running Real Tests in CI | ✅ Completed | Encrypted secrets, build artifact sharing, and automated unit/integration tests |
| **Day 45** | CI/CD & GitHub Actions | Docker Build and Push in GitHub Actions | ✅ Completed | Automated image tagging, layer caching, and pushing to Docker Hub / ECR |
| **Day 46** | CI/CD & GitHub Actions | Reusable Workflows and Composite Actions | ✅ Completed | DRY pipeline engineering across multi-repo organizations |
| **Day 47** | CI/CD & GitHub Actions | Advanced Triggers: PR Events, Cron Schedules & Event-Driven Pipelines | ✅ Completed | Scheduled security audits, `workflow_dispatch`, and ChatOps hooks |
| **Day 48** | CI/CD & GitHub Actions | GitHub Actions Project: End-to-End CI/CD Pipeline | ✅ Completed | Automated build, test, containerize, and deployment workflow |
| **Day 49** | CI/CD & GitHub Actions | DevSecOps: Add Security to Your CI/CD Pipeline | ✅ Completed | Trivy image scanning, SAST, secret detection, and vulnerability gates |
| **Day 50** | Kubernetes | Kubernetes Architecture and Cluster Setup | ✅ Completed | Control plane (API Server, etcd, Scheduler, Controller Manager) & Node components |
| **Day 51** | Kubernetes | Kubernetes Manifests and Your First Pods | ✅ Completed | Declarative YAML specs, multi-container pods, labels, and selectors |
| **Day 52** | Kubernetes | Kubernetes Namespaces and Deployments | ✅ Completed | Resource isolation, ReplicaSets, rolling updates, and instant rollbacks |
| **Day 53** | Kubernetes | Kubernetes Services | ✅ Completed | `ClusterIP`, `NodePort`, `LoadBalancer`, `kube-proxy`, and CoreDNS discovery |
| **Day 54** | Kubernetes | Kubernetes ConfigMaps and Secrets | ✅ Completed | Decoupling configuration and sensitive credentials via env vars and volume mounts |
| **Day 55** | Kubernetes | Persistent Volumes (PV) and Persistent Volume Claims (PVC) | ✅ Completed | StorageClasses, dynamic provisioning, and stateful workload lifecycle |
| **Day 56** | Kubernetes | Kubernetes StatefulSets | ✅ Completed | Stable network identities, ordered deployment/scaling, and headless services |
| **Day 57** | Kubernetes | Resource Requests, Limits, and Probes | ✅ Completed | QoS classes, CPU throttling/OOM protection, Liveness, Readiness & Startup probes |
| **Day 58** | Kubernetes | Metrics Server and Horizontal Pod Autoscaler (HPA) | ✅ Completed | Dynamic pod autoscaling based on real-time CPU/memory utilization |
| **Day 59** | Kubernetes | Helm — Kubernetes Package Manager | ✅ Completed | Templating Kubernetes manifests, chart repositories, and release upgrades |
| **Day 60** | Kubernetes | Capstone: Deploy WordPress + MySQL on Kubernetes | ✅ Completed | Full stateful + stateless stack with PVCs, Secrets, and Service exposure |
| **Day 61** | TerraWeek (Terraform) | Introduction to Terraform and Your First AWS Infrastructure | ✅ Completed | Providers, HCL syntax, `init`/`plan`/`apply`/`destroy` lifecycle |
| **Day 62** | TerraWeek (Terraform) | Providers, Resources and Dependencies | ✅ Completed | Implicit vs explicit dependencies (`depends_on`), custom VPC & EC2 provisioning |
| **Day 63** | TerraWeek (Terraform) | Variables, Outputs, Data Sources and Expressions | ✅ Completed | Dynamic AMI lookups, input validation, `locals`, and output exports |
| **Day 64** | TerraWeek (Terraform) | Terraform State Management and Remote Backends | ✅ Completed | Remote state in AWS S3 with DynamoDB state locking and drift remediation |
| **Day 65** | TerraWeek (Terraform) | Terraform Modules: Build Reusable Infrastructure | ✅ Completed | Composable VPC, networking, and compute modules |
| **Day 66** | TerraWeek (Terraform) | Provision an EKS Cluster with Terraform Modules | ✅ Completed | Automated Amazon EKS control plane, managed node groups, and IAM OIDC |
| **Day 67** | TerraWeek (Terraform) | TerraWeek Capstone: Multi-Environment Infrastructure | ✅ Completed | Managing `dev`, `staging`, and `prod` environments using Workspaces & Modules |
| **Day 68** | Ansible | Introduction to Ansible and Inventory Setup | ✅ Completed | Agentless SSH architecture, static/dynamic inventories, and ad-hoc commands |
| **Day 69** | Ansible | Ansible Playbooks and Modules | ✅ Completed | Idempotent YAML playbooks managing packages, services, users, and files |
| **Day 70** | Ansible | Variables, Facts, Conditionals and Loops | ✅ Completed | OS-aware tasks using `ansible_facts`, `when` clauses, and `loop` iterations |
| **Day 71** | Ansible | Roles, Galaxy, Templates and Vault | ✅ Completed | Role directory structures, dynamic Jinja2 configs, and secret encryption |
| **Day 72** | Ansible | Ansible Project: Automate Docker and Nginx Deployment | ✅ Completed | Provisioned AWS VPC/EC2 via Terraform and automated Nginx/Docker via Ansible |
| **Day 73** | Observability | Introduction to Observability and Prometheus | ✅ Completed | Metrics vs Logs vs Traces, PromQL fundamentals, and scrape configurations |
| **Day 74** | Observability | Node Exporter, cAdvisor, and Grafana Dashboards | ✅ Completed | Host and container telemetry visualization with custom Grafana dashboards |
| **Day 75** | Observability | Log Management with Loki and Promtail | ✅ Completed | Centralized log shipping, LogQL querying, and log-to-metric correlation |
| **Day 76** | Observability | OpenTelemetry and Alerting | ✅ Completed | Unified OTEL collector pipelines and Alertmanager routing rules |
| **Day 77** | Observability | Observability Project: Full Stack with Docker Compose | ✅ Completed | Complete `observability-for-devops` stack monitoring live microservices |
| **Day 78** | Helm | Introduction to Helm and Chart Basics | ✅ Completed | Chart structure (`Chart.yaml`, `values.yaml`, `templates/`) for `AI-BankApp` |
| **Day 79** | Helm | Creating a Custom Helm Chart for AI-BankApp | ✅ Completed | Parameterizing Deployments, StatefulSets, Services, and ConfigMaps |
| **Day 80** | Helm | Helm Project: Multi-Environment Deployment and CI/CD | ✅ Completed | Environment-specific overrides (`values-dev.yaml`, `values-prod.yaml`) in CI |
| **Day 81** | Amazon EKS | Introduction to Amazon EKS with Terraform | ✅ Completed | Provisioning production EKS cluster and configuring `aws eks update-kubeconfig` |
| **Day 82** | Amazon EKS | EKS Networking with Gateway API and Persistent Storage | ✅ Completed | Kubernetes Gateway API routing and AWS EBS CSI driver dynamic PVCs |
| **Day 83** | Amazon EKS | EKS Project: Production Deployment of AI-BankApp | ✅ Completed | Live cloud deployment of Spring Boot + MySQL + Ollama AI on Amazon EKS |
| **Day 84** | Argo CD & GitOps | Introduction to GitOps and Argo CD | ✅ Completed | Declarative GitOps principles, installing Argo CD on K8s, and Application CRDs |
| **Day 85** | Argo CD & GitOps | Argo CD Deep Dive: Sync Strategies, Rollbacks & Multi-App | ✅ Completed | Automated self-healing, prune policies, sync waves, and App-of-Apps pattern |
| **Day 86** | Argo CD & GitOps | GitOps Project: End-to-End CI/CD Pipeline with AI-BankApp | ✅ Completed | GitHub Actions CI building images + updating Helm tags -> Argo CD auto-syncing EKS |
| **Day 87** | Agentic AI for DevOps | Introduction to Agentic AI for DevOps | ✅ Completed | Local LLMs (Ollama), ReAct (Reason + Act) loop, and autonomous Docker debugging |
| **Day 88** | Agentic AI for DevOps | Multi-Tool Agents, MCP, and CI/CD Analyzer | ✅ Completed | Model Context Protocol (MCP) server integrating Docker, K8s, and GitHub Actions tools |
| **Day 89** | Agentic AI for DevOps | Production AI Agents: KubeHealer and AIOps | ✅ Completed | Durable self-healing K8s agent with Temporal, Claude Sonnet 4, and safety guardrails |
| **Day 90** | Grand Finale | Grand Finale: The Complete DevOps Journey | ✅ Completed | Full-stack architecture synthesis, capstone portfolio, and SRE retrospective |

---

## 📂 Repository Organization

The repository is structured chronologically so every concept builds upon the previous phase:
```text
Production-Ready-DevOps-SRE-Journey/
├── 2026/
│   ├── day-01/ to day-13/   # Linux Fundamentals & Troubleshooting Runbooks
│   ├── day-14/ to day-15/   # Networking Diagnostics & Subnetting
│   ├── day-16/ to day-21/   # Bash Scripting & Log Automation Projects
│   ├── day-22/ to day-28/   # Git, GitHub Flow & GitHub CLI
│   ├── day-29/ to day-37/   # Docker & Multi-Container Compose Stacks
│   ├── day-38/ to day-49/   # GitHub Actions CI/CD & DevSecOps Pipelines
│   ├── day-50/ to day-60/   # Kubernetes Architecture, Workloads & Capstone
│   ├── day-61/ to day-67/   # TerraWeek: Modular AWS & EKS Terraform IaC
│   ├── day-68/ to day-72/   # Ansible Configuration Management & Roles
│   ├── day-73/ to day-77/   # Full-Stack Observability (Prometheus, Grafana, Loki, OTEL)
│   ├── day-78/ to day-80/   # Custom Helm Chart Engineering
│   ├── day-81/ to day-83/   # Amazon EKS Production Deployments & Gateway API
│   ├── day-84/ to day-86/   # Argo CD & End-to-End GitOps Pipelines
│   ├── day-87/ to day-89/   # Agentic AI, MCP Servers & KubeHealer AIOps
│   └── day-90/              # Grand Finale & Complete Architecture Synthesis
└── README.md
```

---

## 🔗 Connect With Me

I practice a **"Learn in Public"** engineering philosophy—sharing daily architectural breakdowns, troubleshooting runbooks, and hands-on lab notes with the community. Let's connect and talk about Cloud Infrastructure, Kubernetes, GitOps, or Site Reliability Engineering!

- **Author:** Neeraj Bali
- **GitHub:** [@NB11-ML](https://github.com/NB11-ML)
- **LinkedIn:** [LinkedIn Profile Neeraj Bali](https://www.linkedin.com/in/neeraj-bali-bbbb4597)
- **Hashtag:** `#90DaysOfDevOps`

---

## 💡 Note for Peers & Hiring Managers

This repository is built not just as a personal log, but as a practical, battle-tested reference for fellow engineers. Every lab was executed hands-on—including resolving real-world failure modes (OOMKills, ImagePullBackOffs, Terraform state locks, and Temporal worker crash recovery). If you have questions about any architecture or runbook in this repo, feel free to reach out!

### 🙏 Special Thanks
A special thanks to **Shubham Londhe**, the **TrainWithShubham** and SRE/DevOps community for continuous guidance and structuring this hands-on challenge!

```
