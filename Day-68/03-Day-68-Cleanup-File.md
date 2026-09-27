# 🧹 Lab Teardown & Resource Cleanup

To prevent unnecessary AWS charges and ensure a clean environment, all infrastructure provisioned for this lab must be destroyed once testing is complete. Leaving unused EC2 instances or custom VPCs running is a poor SRE practice.

### Step 1: Destroy Infrastructure via Terraform
Navigate to the directory containing the Terraform state and configuration files, then execute the destroy command. This automatically reverses the `main.tf` configuration, deleting the EC2 instances, custom VPC, Subnets, Internet Gateway, Route Tables, Security Groups, and the AWS Key Pair.

```bash
cd ../Prod-Ansible/Terra-Ansi-Infra
terraform destroy --auto-approve

```

### Step 2: Verify Teardown via AWS CLI

After Terraform reports a successful destroy, it is best practice to verify the cloud provider's actual state using the AWS CLI.

**1. Verify EC2 Instances**
Check that all instances are in a `terminated` state.

```bash
aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name']|[0].Value}" --output table --region us-east-1

```

*Note: Instances in a `terminated` state immediately stop incurring compute charges. They will remain visible in the AWS console and CLI output for a few hours before automatically disappearing.*

**2. Verify VPC Deletion**
Ensure the custom `ansible-lab-vpc` has been removed.

```bash
aws ec2 describe-vpcs --query "Vpcs[*].{VpcId:VpcId,Name:Tags[?Key=='Name']|[0].Value}" --output table --region us-east-1

```

**3. Verify Key Pair Deletion**
Confirm the `ansible_lab_key` no longer exists in AWS.

```bash
aws ec2 describe-key-pairs --query "KeyPairs[*].KeyName" --output table --region us-east-1

```

**4. Verify Security Group Deletion**
Verify the `ansible-lab-sg` has been deleted.

```bash
aws ec2 describe-security-groups --query "SecurityGroups[*].{GroupName:GroupName,GroupId:GroupId}" --output table --region us-east-1

```

By completing these steps, the AWS environment is completely clean and zero orphaned resources are left behind.

```
