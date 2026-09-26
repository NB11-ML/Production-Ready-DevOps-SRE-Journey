# 🔍 Console & CLI Cleanup Verification

To ensure zero surprise charges on your AWS bill after tearing down production infrastructure (such as EKS clusters, VPCs, NAT Gateways, and Load Balancers), it is best practice as an SRE to actively verify that no orphaned resources remain in your account. 

Run the following AWS CLI commands in your terminal to verify that your `us-east-1` region is completely clean.
---

## 1. Verify Load Balancers (Classic & v2)

Kubernetes services configured with `type: LoadBalancer` automatically spin up external AWS Load Balancers outside of Terraform's direct management. You must check both Classic and Application/Network Load Balancers to ensure they were terminated.

**Command:**

```bash
aws elb describe-load-balancers --region us-east-1 --query "LoadBalancerDescriptions[*].LoadBalancerName"
aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[*].LoadBalancerName"

```

**Expected Output:**

```json
[]

```

* **Detail:** An empty array (`[]`) confirms that all Classic, Application (ALB), and Network (NLB) load balancers have been completely deleted and you are no longer paying hourly rates for public entry points.

---

## 2. Verify Orphaned Elastic IPs

Unallocated or detached Elastic IP addresses accrue hourly charges in AWS. This command checks for any lingering public IPs left behind by deleted NAT Gateways or instances.

**Command:**

```bash
aws ec2 describe-addresses --region us-east-1 --query "Addresses[*].PublicIp"

```

**Expected Output:**

```json
[]

```

* **Detail:** An empty array confirms that no idle Elastic IPs are sitting unattached in your account.

---

## 3. Verify EKS Clusters

This command checks if any active EKS control planes still exist in the target region.

**Command:**

```bash
aws eks list-clusters --region us-east-1

```

**Expected Output:**

```json
{
    "clusters": []
}

```

* **Detail:** An empty clusters list verifies that the `terraweek-eks` control plane has been fully destroyed, eliminating the baseline cluster management fee.

---

## 4. Verify Running EC2 Instances

This command queries for any running EC2 instances (such as worker nodes that failed to terminate).

**Command:**

```bash
aws ec2 describe-instances --region us-east-1 --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].InstanceId"

```

**Expected Output:**

```json
[]

```

* **Detail:** An empty array verifies that zero EC2 instances are actively running in your region, ensuring compute costs are completely halted.

---

> **SRE Best Practice Note:** If any of these commands return resource IDs instead of empty brackets `[]`, investigate immediately, check your region, and manually terminate or delete the remaining components in the AWS Management Console.
