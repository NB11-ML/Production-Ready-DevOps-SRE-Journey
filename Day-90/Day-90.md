# Day 90: Grand Finale — The Complete DevOps & SRE Journey 🚀

We made it! 🎉 Day 90 marks the culmination of a 90-day engineering journey from foundational Linux systems administration to Cloud-Native GitOps, Observability, and Production Agentic AI (AIOps). 

This repository stands as a comprehensive, hands-on playbook of modern DevOps, Site Reliability Engineering (SRE), and Cloud-Native architecture.

---

## Task 1: End-to-End Cloud-Native & AIOps Architecture

Over these 90 days, individual tools were combined into a unified, production-ready ecosystem:

```text
+----------------------------------------------------------------------------------------+
|                        Developer & GitOps Workflow (Days 22-49)                        |
|   [Git / GitHub CLI] ---> [GitHub Actions CI/CD] ---> [DevSecOps Scans & Image Push]   |
+----------------------------------------------------------------------------------------+
                                            |
                                            | Updates Manifests / Helm Charts
                                            v
+----------------------------------------------------------------------------------------+
|                     Infrastructure & GitOps Delivery (Days 61-86)                      |
|   [Terraform (AWS VPC + EKS)] + [Ansible Config] ---> [Argo CD Pull-Based GitOps Sync] |
+----------------------------------------------------------------------------------------+
                                            |
                                            | Deploys & Reconciles
                                            v
+----------------------------------------------------------------------------------------+
|                      Kubernetes Production Runtime (Days 29-60)                        |
|      [Docker Containers] | [Deployments & StatefulSets] | [PV/PVC Storage] | [HPA]     |
+----------------------------------------------------------------------------------------+
                     |                                              ^
                     | Exports Metrics, Logs & Traces               | Applies Safe
                     v                                              | Strategic Patches
+-----------------------------------------+    +-----------------------------------------+
|     Observability Stack (Days 73-77)    |    |     Agentic AI & AIOps (Days 87-89)     |
| - Prometheus & Node Exporter / cAdvisor |--->| - ReAct Agents & MCP Tool Servers       |
| - Grafana Dashboards & Alerting         |    | - KubeHealer (Temporal + Claude Sonnet) |
| - Loki, Promtail & OpenTelemetry (OTEL) |    | - Guardrails, Audit Trail & Escalation  |
+-----------------------------------------+    +-----------------------------------------+
```

---

## Task 2: Reflecting on the 90-Day Evolution

### Phase 1: Systems, Networking & Scripting Foundations (Days 01–28)
* **Linux Fundamentals (Days 01–13):** Mastered Linux OS architecture, process management (`systemd`), CPU/memory/log troubleshooting drills, file permissions (`chmod`, `chown`, `chgrp`), user/group administration, and Logical Volume Management (LVM).
* **Networking (Days 14–15):** Executed hands-on network diagnostics covering DNS resolution, IPv4 subnetting, routing tables, and port inspection.
* **Shell Scripting (Days 16–21):** Automated operational workflows using Bash loops, functions, error handling, crontab scheduling, log rotation, backup scripts, and automated log analyzers.
* **Git & GitHub (Days 22–28):** Established source control discipline using branching strategies, `merge`, `rebase`, `stash`, `cherry-pick`, `reset` vs `revert`, and terminal workflows via GitHub CLI (`gh`).

### Phase 2: Containerization & CI/CD Automation (Days 29–49)
* **Docker (Days 29–37):** Containerized multi-tier applications using custom Dockerfiles, multi-stage builds, custom bridge networks, persistent volumes, and Docker Compose orchestrations.
* **CI/CD & GitHub Actions (Days 38–49):** Built event-driven pipelines featuring matrix builds, self-hosted runners, secrets management, reusable workflows, composite actions, and automated DevSecOps vulnerability scanning.

### Phase 3: Orchestration, IaC & Configuration Management (Days 50–72)
* **Kubernetes (Days 50–60):** Deployed production workloads across Pods, Deployments, StatefulSets, DaemonSets, and Services, complete with ConfigMaps, Secrets, Persistent Volumes (PV/PVC), Liveness/Readiness Probes, and Horizontal Pod Autoscalers (HPA).
* **TerraWeek — Terraform (Days 61–67):** Provisioned multi-environment AWS infrastructure using modular Terraform code, remote S3/DynamoDB state locking, workspaces, and automated Amazon EKS cluster provisioning.
* **Ansible (Days 68–72):** Authored idempotent configuration management playbooks utilizing dynamic inventories, Ansible Roles, Jinja2 templates, and Ansible Vault encryption.

### Phase 4: Observability, EKS & GitOps Delivery (Days 73–86)
* **Observability (Days 73–77):** Built full-stack telemetry pipelines collecting infrastructure and container metrics with Prometheus, Node Exporter, and cAdvisor, visualizing SLIs/SLOs in Grafana, aggregating logs with Loki and Promtail, and tracing via OpenTelemetry.
* **Helm & Amazon EKS (Days 78–83):** Packaged microservices into reusable Helm charts and deployed highly available architectures onto Amazon EKS using the Kubernetes Gateway API and AWS EBS CSI persistent storage.
* **Argo CD & GitOps (Days 84–86):** Transitioned from push-based deployments to declarative, pull-based GitOps using Argo CD, automating drift detection, sync waves, and instant rollbacks.

### Phase 5: Agentic AI for DevOps & AIOps (Days 87–89)
* **Local LLMs & ReAct Agents (Day 87):** Built single-domain container diagnostic agents using the Reason + Act (ReAct) loop.
* **Multi-Tool Agents & MCP (Day 88):** Standardized agent tool definitions across Docker, Kubernetes, and GitHub Actions using the Model Context Protocol (MCP).
* **Production AIOps — KubeHealer (Day 89):** Engineered a crash-resilient, self-healing Kubernetes agent backed by **Temporal** durable execution and **Claude Sonnet 4**, enforcing strict production guardrails (human approval, blast-radius scope limits, strategic patching, and human escalation).

---

## Task 3: The Complete 90-Day Master Index

| Day | Module | Topic |
| :--- | :--- | :--- |
| **Day 01** | Linux Fundamentals | Introduction to DevOps and Cloud |
| **Day 02** | Linux Fundamentals | Linux Architecture, Processes, and systemd |
| **Day 03** | Linux Fundamentals | Linux Commands Practice |
| **Day 04** | Linux Fundamentals | Linux Practice: Processes and Services |
| **Day 05** | Linux Fundamentals | Linux Troubleshooting Drill: CPU, Memory, and Logs |
| **Day 06** | Linux Fundamentals | Linux Fundamentals: Read and Write Text Files |
| **Day 07** | Linux Fundamentals | Linux File System Hierarchy and Scenario-Based Practice |
| **Day 08** | Linux Fundamentals | Cloud Server Setup: Docker, Nginx and Web Deployment |
| **Day 09** | Linux Fundamentals | Linux User and Group Management Challenge |
| **Day 10** | Linux Fundamentals | File Permissions and File Operations Challenge |
| **Day 11** | Linux Fundamentals | File Ownership Challenge (chown and chgrp) |
| **Day 12** | Linux Fundamentals | Breather and Revision (Days 01–11) |
| **Day 13** | Linux Fundamentals | Linux Volume Management (LVM) |
| **Day 14** | Networking | Networking Fundamentals and Hands-on Checks |
| **Day 15** | Networking | Networking Concepts: DNS, IP, Subnets and Ports |
| **Day 16** | Shell Scripting | Shell Scripting Basics |
| **Day 17** | Shell Scripting | Shell Scripting: Loops, Arguments and Error Handling |
| **Day 18** | Shell Scripting | Shell Scripting: Functions and Intermediate Concepts |
| **Day 19** | Shell Scripting | Shell Scripting Project: Log Rotation, Backup and Crontab |
| **Day 20** | Shell Scripting | Bash Scripting Challenge: Log Analyzer and Report Generator |
| **Day 21** | Shell Scripting | Shell Scripting Cheat Sheet: Build Your Own Reference Guide |
| **Day 22** | Git and GitHub | Introduction to Git: Your First Repository |
| **Day 23** | Git and GitHub | Git Branching and Working with GitHub |
| **Day 24** | Git and GitHub | Advanced Git: Merge, Rebase, Stash and Cherry Pick |
| **Day 25** | Git and GitHub | Git Reset vs Revert and Branching Strategies |
| **Day 26** | Git and GitHub | GitHub CLI: Manage GitHub from Your Terminal |
| **Day 27** | Git and GitHub | GitHub Profile Makeover: Build Your Developer Identity |
| **Day 28** | Git and GitHub | Revision Day: Everything from Day 1 to Day 27 |
| **Day 29** | Docker | Introduction to Docker |
| **Day 30** | Docker | Docker Images and Container Lifecycle |
| **Day 31** | Docker | Dockerfile: Build Your Own Images |
| **Day 32** | Docker | Docker Volumes and Networking |
| **Day 33** | Docker | Docker Compose: Multi-Container Basics |
| **Day 34** | Docker | Docker Compose: Real-World Multi-Container Apps |
| **Day 35** | Docker | Multi-Stage Builds and Docker Hub |
| **Day 36** | Docker | Docker Project: Dockerize a Full Application |
| **Day 37** | Docker | Docker Revision and Cheat Sheet |
| **Day 38** | CI/CD & GitHub Actions | YAML Basics |
| **Day 39** | CI/CD & GitHub Actions | What is CI/CD? |
| **Day 40** | CI/CD & GitHub Actions | Your First GitHub Actions Workflow |
| **Day 41** | CI/CD & GitHub Actions | Triggers and Matrix Builds |
| **Day 42** | CI/CD & GitHub Actions | Runners: GitHub-Hosted and Self-Hosted |
| **Day 43** | CI/CD & GitHub Actions | Jobs, Steps, Env Vars and Conditionals |
| **Day 44** | CI/CD & GitHub Actions | Secrets, Artifacts and Running Real Tests in CI |
| **Day 45** | CI/CD & GitHub Actions | Docker Build and Push in GitHub Actions |
| **Day 46** | CI/CD & GitHub Actions | Reusable Workflows and Composite Actions |
| **Day 47** | CI/CD & GitHub Actions | Advanced Triggers: PR Events, Cron Schedules and Event-Driven Pipelines |
| **Day 48** | CI/CD & GitHub Actions | GitHub Actions Project: End-to-End CI/CD Pipeline |
| **Day 49** | CI/CD & GitHub Actions | DevSecOps: Add Security to Your CI/CD Pipeline |
| **Day 50** | Kubernetes | Kubernetes Architecture and Cluster Setup |
| **Day 51** | Kubernetes | Kubernetes Manifests and Your First Pods |
| **Day 52** | Kubernetes | Kubernetes Namespaces and Deployments |
| **Day 53** | Kubernetes | Kubernetes Services |
| **Day 54** | Kubernetes | Kubernetes ConfigMaps and Secrets |
| **Day 55** | Kubernetes | Persistent Volumes (PV) and Persistent Volume Claims (PVC) |
| **Day 56** | Kubernetes | Kubernetes StatefulSets |
| **Day 57** | Kubernetes | Resource Requests, Limits, and Probes |
| **Day 58** | Kubernetes | Metrics Server and Horizontal Pod Autoscaler (HPA) |
| **Day 59** | Kubernetes | Helm — Kubernetes Package Manager |
| **Day 60** | Kubernetes | Capstone: Deploy WordPress + MySQL on Kubernetes |
| **Day 61** | TerraWeek (Terraform) | Introduction to Terraform and Your First AWS Infrastructure |
| **Day 62** | TerraWeek (Terraform) | Providers, Resources and Dependencies |
| **Day 63** | TerraWeek (Terraform) | Variables, Outputs, Data Sources and Expressions |
| **Day 64** | TerraWeek (Terraform) | Terraform State Management and Remote Backends |
| **Day 65** | TerraWeek (Terraform) | Terraform Modules: Build Reusable Infrastructure |
| **Day 66** | TerraWeek (Terraform) | Provision an EKS Cluster with Terraform Modules |
| **Day 67** | TerraWeek (Terraform) | TerraWeek Capstone: Multi-Environment Infrastructure with Workspaces and Modules |
| **Day 68** | Ansible | Introduction to Ansible and Inventory Setup |
| **Day 69** | Ansible | Ansible Playbooks and Modules |
| **Day 70** | Ansible | Variables, Facts, Conditionals and Loops |
| **Day 71** | Ansible | Roles, Galaxy, Templates and Vault |
| **Day 72** | Ansible | Ansible Project: Automate Docker and Nginx Deployment |
| **Day 73** | Observability | Introduction to Observability and Prometheus (`observability-for-devops`) |
| **Day 74** | Observability | Node Exporter, cAdvisor, and Grafana Dashboards |
| **Day 75** | Observability | Log Management with Loki and Promtail |
| **Day 76** | Observability | OpenTelemetry and Alerting |
| **Day 77** | Observability | Observability Project: Full Stack with Docker Compose |
| **Day 78** | Helm | Introduction to Helm and Chart Basics (`AI-BankApp-DevOps`) |
| **Day 79** | Helm | Creating a Custom Helm Chart for AI-BankApp |
| **Day 80** | Helm | Helm Project: Multi-Environment Deployment and CI/CD |
| **Day 81** | Amazon EKS | Introduction to Amazon EKS with Terraform (`AI-BankApp-DevOps`) |
| **Day 82** | Amazon EKS | EKS Networking with Gateway API and Persistent Storage |
| **Day 83** | Amazon EKS | EKS Project: Production Deployment of AI-BankApp |
| **Day 84** | Argo CD & GitOps | Introduction to GitOps and Argo CD (`AI-BankApp-DevOps`) |
| **Day 85** | Argo CD & GitOps | Argo CD Deep Dive: Sync Strategies, Rollbacks, and Multi-App Management |
| **Day 86** | Argo CD & GitOps | GitOps Project: End-to-End CI/CD Pipeline with AI-BankApp |
| **Day 87** | Agentic AI for DevOps | Introduction to Agentic AI for DevOps (`agentic-ai-for-devops`) |
| **Day 88** | Agentic AI for DevOps | Multi-Tool Agents, MCP, and CI/CD Analyzer |
| **Day 89** | Agentic AI for DevOps | Production AI Agents: KubeHealer and AIOps (`kubehealer`) |
| **Day 90** | Grand Finale | Grand Finale: The Complete DevOps Journey |

---

## Task 4: Capstone Reference Projects Summary

| Project | Days Used | Core Stack & Architecture |
| :--- | :--- | :--- |
| **`observability-for-devops`** | Days 73–77 | Prometheus, Grafana, Loki, Promtail, Node Exporter, cAdvisor, and OpenTelemetry Collector orchestrated via Docker Compose. |
| **`AI-BankApp-DevOps`** | Days 78–86 | Full-stack Spring Boot + MySQL + Ollama AI banking platform provisioned on AWS EKS via Terraform, packaged with Helm, and deployed via GitHub Actions and Argo CD GitOps. |
| **`agentic-ai-for-devops`** | Days 87–88 | Autonomous ReAct agents and Model Context Protocol (MCP) tool servers for multi-domain Docker, Kubernetes, and GitHub Actions root-cause analysis. |
| **`kubehealer`** | Day 89 | Self-healing Kubernetes AIOps agent powered by Temporal durable workflows, Claude Sonnet 4 diagnostic reasoning, and `kubectl` strategic patching. |

---

## Task 5: Core SRE Principles Earned Through Hands-On Practice

1. **Declarative State Over Manual Intervention:** Whether managing AWS infrastructure via Terraform or cluster workloads via Argo CD, Git must remain the single source of truth.
2. **Idempotency & Reproducibility:** Every script, Ansible playbook, and Terraform module must produce predictable, repeatable outcomes without configuration drift.
3. **Stateful Reliability & Data Persistence:** Protecting stateful workloads (LVM, Docker volumes, Kubernetes StatefulSets, EBS CSI drivers, and remote Terraform state locking) is critical for zero-data-loss operations.
4. **Observability Drives Mean Time to Resolution (MTTR):** Metrics (Prometheus), logs (Loki), and traces (OpenTelemetry) provide the vital signals needed by both human SREs and AI agents to pinpoint failures rapidly.
5. **AI Augmentation Requires Strict Guardrails:** Autonomous agents dramatically accelerate incident triage, but production reliability demands durable execution (Temporal), blast-radius scope limits, and clear escalation paths to human operators.

---

## 🙏 Acknowledgments

A special thanks to **Shubham Londhe**, the **TrainWithShubham**  and **SRE?DevOps** community for continuous guidance and structuring this hands-on challenge!

**Repository:** [Production-Ready-DevOps-SRE-Journey](https://github.com/NB11-ML/Production-Ready-DevOps-SRE-Journey)

**Status:** `#90DaysOfDevOps` Completed ✅

