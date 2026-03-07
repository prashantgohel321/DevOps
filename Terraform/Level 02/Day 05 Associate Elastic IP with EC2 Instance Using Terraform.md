# Terraform Level 02 Day 05: Associate Elastic IP with EC2 Instance

This document outlines the solution for Terraform Level 02 Day 05. The objective was to satisfy a Development Team request for an EC2 instance with a persistent, stable public IP address by utilizing an AWS Elastic IP (EIP).

## Table of Contents
- [Terraform Level 02 Day 05: Associate Elastic IP with EC2 Instance](#terraform-level-02-day-05-associate-elastic-ip-with-ec2-instance)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create Infrastructure (`main.tf`)](#1-create-infrastructure-maintf)
    - [2. Define Outputs (`outputs.tf`)](#2-define-outputs-outputstf)
    - [3. Execution and Validation](#3-execution-and-validation)
  - [Deep Dive: Elastic IP Concepts](#deep-dive-elastic-ip-concepts)
    - [What is an Elastic IP (EIP)?](#what-is-an-elastic-ip-eip)
    - [Association Behavior](#association-behavior)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Deploy an Ubuntu-based EC2 instance and link it to a static Elastic IP.

* **Working Directory:** `/home/bob/terraform`
* **EC2 Instance:** `xfusion-ec2` (type: `t2.micro`, image: Ubuntu).
* **Elastic IP:** `xfusion-eip` associated with the instance.
* **Outputs Required:** * `KKE_instance_name`: The "Name" tag of the instance.
    * `KKE_eip`: The public IP address of the Elastic IP.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create Infrastructure (`main.tf`)
<a name="1-create-infrastructure"></a>
This file contains the core resource definitions. We use a data source to fetch the latest Ubuntu AMI to ensure the configuration is robust and region-independent.

**Command:**
```bash
cd /home/bob/terraform
vi main.tf
```

**Content:**
```hcl
provider "aws" {
  region = "us-east-1"
}

# Data Source: Retrieve the latest Ubuntu 22.04 AMI ID
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Resource: Launch the EC2 Instance
resource "aws_instance" "xfusion_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "xfusion-ec2"
  }
}

# Resource: Allocate and Associate the Elastic IP
resource "aws_eip" "xfusion_eip" {
  instance = aws_instance.xfusion_ec2.id
  domain   = "vpc"

  tags = {
    Name = "xfusion-eip"
  }
}
```

### 2. Define Outputs (`outputs.tf`)
<a name="2-define-outputs"></a>
Define the specific output variables required by the DevOps team for validation.

**Command:**
```bash
vi outputs.tf
```

**Content:**
```hcl
output "KKE_instance_name" {
  value = aws_instance.xfusion_ec2.tags["Name"]
}

output "KKE_eip" {
  value = aws_eip.xfusion_eip.public_ip
}
```

### 3. Execution and Validation
<a name="3-execution-and-validation"></a>
Follow the Terraform lifecycle commands to provision the infrastructure.

1.  **Initialize:** `terraform init` (Downloads the AWS provider).
2.  **Plan:** `terraform plan` (Verify 2 resources will be created).
3.  **Apply:** `terraform apply -auto-approve` (Execute the changes).
4.  **Verification:** Run `terraform output` to see the results.

**Final Check:**
Run `terraform plan` again. It must return:
**"No changes. Your infrastructure matches the configuration."**

---

## Deep Dive: Elastic IP Concepts
<a name="deep-dive-elastic-ip-concepts"></a>

### What is an Elastic IP (EIP)?
A standard public IP address assigned to an EC2 instance is dynamic; it changes if the instance is stopped and restarted. An **Elastic IP** is a static IPv4 address designed for dynamic cloud computing. It is associated with your AWS account, not a specific instance, allowing you to re-mask the address to another instance in your account if one fails.

### Association Behavior
In our `main.tf`, we linked the EIP using the `instance` attribute:
`instance = aws_instance.xfusion_ec2.id`

This creates a dependency chain:
1.  Terraform creates the **EC2 Instance**.
2.  Terraform allocates the **EIP**.
3.  Terraform performs the **Association** between the two.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: `Error: Your query returned no results` for `data.aws_ami.ubuntu`**

If `terraform plan` fails with this error, it means the filter criteria (Name or Owner) did not match any available AMIs in your current AWS region.

* **Cause 1: Region Mismatch.** The AMI name pattern `ubuntu-jammy-22.04...` is usually standard, but ensure your `provider "aws"` region (e.g., `us-east-1`) is correct.
* **Cause 2: Overly Restrictive Filter.** Some environments or lab accounts may only have specific versions of Ubuntu available (e.g., 20.04 Focal instead of 22.04 Jammy).
* **Fix:** Try broadening the filter in `main.tf` to look for Focal if Jammy is missing:
    ```hcl
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    ```
    Alternatively, use a wildcard to find any Ubuntu server image:
    ```hcl
    values = ["*ubuntu*server*"]
    ```
* **Cause 3: Missing Virtualization Type.** Adding a filter for `virtualization-type = ["hvm"]` (as updated in the Step-by-Step section above) often helps narrow down the correct hardware-assisted virtual machine images.
    
