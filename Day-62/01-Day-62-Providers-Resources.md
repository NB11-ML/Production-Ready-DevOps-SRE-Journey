# 🌍 Day 62: Providers, Resources, and Dependencies

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![SRE](https://img.shields.io/badge/SRE-FF4F00?style=for-the-badge&logo=opsgenie&logoColor=white)

Today we transition from creating standalone resources to building a complete, interconnected cloud networking stack. Understanding how Terraform maps these connections—through both implicit and explicit dependencies—is a core skill for any Site Reliability Engineer managing production infrastructure.

---

## 🛠️ Task 1: Explore the AWS Provider

Terraform relies on plugins called "providers" to interact with cloud APIs. 

**Version Constraints Explained:**
*   `~> 5.0`: This is a "pessimistic constraint operator." It allows Terraform to download any non-breaking minor/patch updates in the 5.x range (e.g., 5.1, 5.100.0)[cite: 5], but it will explicitly block an upgrade to 6.0, which might contain breaking changes.
*   `>= 5.0`: Allows any version greater than or equal to 5.0, including major breaking updates like 6.0 or 7.0 (Risky for production).
*   `= 5.0.0`: Locks the provider to one exact version.

<img width="850" height="849" alt="Day-62 Terra Init" src="https://github.com/user-attachments/assets/7eb3692c-1709-4326-bbf9-4b7c0fd27a0b" />

**The `.terraform.lock.hcl` File:**

When running `terraform init`, Terraform generates a lock file[cite: 5, 6]. 
This file records the exact provider versions and cryptographic hashes downloaded[cite: 6]. 
It ensures that if another engineer clones this repository six months from now, 
Terraform will use the exact same provider version, preventing the "it works on my machine" problem.

<img width="850" height="533" alt="Day-62 terra lock hcl" src="https://github.com/user-attachments/assets/25c23dec-4ac2-4edc-afdf-41fb11a5fedf" />

---

## 🏗️ Task 2: Build a VPC from Scratch

We defined a complete network architecture using `main.tf`.

```hcl
resource "aws_vpc" "terraformvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "TerraWeek-VPC"
  }
}

resource "aws_subnet" "terraformsubnet" {
  vpc_id                  = aws_vpc.terraformvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "TerraWeek-Public-Subnet"
  }
}

resource "aws_internet_gateway" "terraformgateway" {
  vpc_id = aws_vpc.terraformvpc.id
}

resource "aws_route_table" "terraformroute" {
  vpc_id = aws_vpc.terraformvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraformgateway.id
  }
}

resource "aws_route_table_association" "terraform_route_table" {
  route_table_id = aws_route_table.terraformroute.id
  subnet_id      = aws_subnet.terraformsubnet.id
}

```
<img width="845" height="795" alt="Day-62 Terraform plan vpc" src="https://github.com/user-attachments/assets/3dc0a8d5-111b-4095-a645-dc9592105233" />

**Verification:** Looking at the AWS VPC Resource Map, we successfully connected our `10.0.0.0/16` VPC, the `us-east-1a` subnet, the route table, and the internet gateway into a unified architecture.

<img width="1400" height="331" alt="Screenshot 2026-09-21 at 21 05 40" src="https://github.com/user-attachments/assets/7842d0c6-6b0c-46ed-a4ca-46d62a3b0542" />

---
## 🧠 Task 3: Understand Implicit Dependencies

Terraform is declarative. It reads the entire configuration and builds a Directed Acyclic Graph (DAG) to determine the exact order of operations. 

**How does Terraform know to create the VPC before the subnet?**
When we look at our subnet code, we see this specific line:
```hcl
resource "aws_subnet" "terraformsubnet" {
  # THIS is an implicit dependency!
  vpc_id = aws_vpc.terraformvpc.id 
  
  cidr_block = "10.0.1.0/24"
  # ... (other config)
}

```

Terraform detects this attribute reference (`aws_vpc.terraformvpc.id`). It knows it cannot retrieve an ID for a VPC that doesn't exist yet, so it creates an **implicit dependency**, forcing the VPC to be created first.

**What happens if you try to create the subnet first?**

The Terraform engine physically will not allow it; its graph execution forces the VPC first. However, if you hardcoded a fake VPC string ID to bypass Terraform's graph, the AWS API would instantly reject the request, throwing an error that the VPC does not exist.

**List of Implicit Dependencies in our Stack:**

1. `aws_subnet` depends on `aws_vpc`
2. `aws_internet_gateway` depends on `aws_vpc`
3. `aws_route_table` depends on `aws_vpc` and `aws_internet_gateway`
4. `aws_route_table_association` depends on `aws_route_table` and `aws_subnet`
5. `aws_security_group` depends on `aws_vpc`
6. `aws_instance` depends on `aws_subnet` and `aws_security_group`

**Visualizing the Dependencies:**

<img width="1404" height="203" alt="image" src="https://github.com/user-attachments/assets/eba2862d-d57e-41b7-aae6-a463f17647ef" />

---

## 🔒 Task 4: Add a Security Group and EC2 Instance

We expanded the configuration to provision a compute instance secured by an ingress firewall.

```hcl
resource "aws_security_group" "terraformsg" {
    name = "terraformsecuritygroup"
    description = "Controls ingress and egress ports"
    vpc_id = aws_vpc.terraformvpc.id

    ingress{
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 80
        to_port = 80
        protocol = "tcp"
    }
    ingress{
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 22
        to_port = 22
        protocol = "tcp"
    } 
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "TerraWeek-SG"
    }
}

resource "aws_instance" "terraformec2" {
    ami = "ami-0fef201115eefe936"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.terraformsubnet.id
    vpc_security_group_ids =[aws_security_group.terraformsg.id]
    associate_public_ip_address = true
    tags = {
      Name = "TerraWeek-Server" 
    }
}

```
<img width="849" height="407" alt="Day-62 Task4 SG and EC2" src="https://github.com/user-attachments/assets/e801e497-c6fe-4667-b34e-05b9ea1a93b3" />
<img width="851" height="436" alt="Day-62 Task4 output" src="https://github.com/user-attachments/assets/7e3b2b38-b6a4-4064-9cc7-fada281b2314" />
<img width="1056" height="231" alt="Screenshot 2026-09-21 at 23 50 24" src="https://github.com/user-attachments/assets/18695ac3-f33b-4b91-ba32-475a8ca92699" />
<img width="1652" height="825" alt="Screenshot 2026-09-21 at 23 52 05" src="https://github.com/user-attachments/assets/9f4375eb-9a79-42dd-a56c-1f8dfd0f865c" />
<img width="2798" height="666" alt="image" src="https://github.com/user-attachments/assets/37db609d-d096-4656-a0ff-0a88047d8cab" />
<img width="2808" height="602" alt="image" src="https://github.com/user-attachments/assets/c8ca9ca9-6480-4814-8d40-62aad638f731" />



**Verification:**

* The `terraform apply` completed successfully, adding 7 resources.


* The `TerraWeek-Server` EC2 instance (`t3.micro`) is running in `us-east-1a`.


* The `TerraWeek-SG` properly configured TCP Port 80 and TCP Port 22 for inbound traffic and allows all traffic outbound.

<img width="1404" height="203" alt="image" src="https://github.com/user-attachments/assets/eba2862d-d57e-41b7-aae6-a463f17647ef" />

---

## 🔗 Task 5: Explicit Dependencies with `depends_on`

Sometimes resources do not share attributes, meaning Terraform will try to create them simultaneously. We use `depends_on` to force a sequence manually.

```hcl
resource "aws_s3_bucket" "terraformweekbucket" {
    bucket = "terraformweekbucket22092026"
    depends_on = [ aws_instance.terraformec2 ]
}

```
<img width="857" height="519" alt="Day-62 Task5 s3 bucket plan" src="https://github.com/user-attachments/assets/4e76fe11-c07e-4516-9812-f5abfa36bfb2" />

**Real-World SRE Use Cases for `depends_on`:**

1. **IAM Policy Propagation:** When creating an EKS cluster, you must wait for the IAM roles to propagate fully. You add a `depends_on` pointing to the IAM Policy Attachment before the cluster spins up to prevent permission errors.
2. **Database Seeding (Null Resources):** If running a local script to inject tables into a newly provisioned RDS database, the script must explicitly wait for the database creation to finish, otherwise the script will fail connecting to a missing endpoint.

---

## ♻️ Task 6: Lifecycle Rules and Destroy

Terraform provides `lifecycle` blocks to customize resource management.

```hcl

resource "aws_instance" "terraformec2" {
    #ami = "ami-0fef201115eefe936"
    ami = "ami-0b6d9d3d33ba97d99" #Added to check lifecycle
    instance_type = "t3.micro"

    subnet_id = aws_subnet.terraformsubnet.id
    vpc_security_group_ids =[aws_security_group.terraformsg.id]

    associate_public_ip_address = true

    lifecycle {
        create_before_destroy = true
    }

    tags = {
      Name = "TerraWeek-Server" 
    }
}

```

<img width="1270" height="945" alt="Screenshot 2026-09-22 at 00 35 59" src="https://github.com/user-attachments/assets/5aa51966-13f7-40f7-a6e5-a4838de03a0a" />


1. **`create_before_destroy = true`**: Essential for zero-downtime deployments. If an EC2 AMI needs updating, Terraform will spin up the new server first, wait for it to be ready, and only *then* terminate the old one.
2. **`prevent_destroy = true`**: The ultimate safety net. Often attached to production RDS Databases or stateful S3 buckets to block accidental `terraform destroy` commands from wiping out critical data.
3. **`ignore_changes = [tags]`**: Useful when other systems (like an Auto-Scaling Group or an external tagging policy) modify resources outside of Terraform. This prevents Terraform from trying to "revert" those necessary changes during the next apply.

**Final Cleanup:**
Running `terraform destroy` mapped the dependency graph in reverse, wiping out the EC2 instance and Security Group before deleting the foundational Subnet and VPC, ensuring zero orphaned resources and zero AWS billing surprises.
