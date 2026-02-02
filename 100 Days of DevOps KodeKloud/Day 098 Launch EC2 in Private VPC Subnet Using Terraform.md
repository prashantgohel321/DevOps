# DevOps Day 98: Launch EC2 in Private VPC Subnet Using Terraform

This document outlines the solution for DevOps Day 98. The objective was to architect a secure, private infrastructure environment on AWS. This involved creating a custom Virtual Private Cloud (VPC), a private subnet, a secure Security Group, and an EC2 instance that is isolated from the public internet.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Define Variables (`variables.tf`)](#1-define-variables-variablestf)
    * [2. Define Outputs (`outputs.tf`)](#2-define-outputs-outputstf)
    * [3. Create Infrastructure (`main.tf`)](#3-create-infrastructure-maintf)
    * [4. Initialize, Plan, and Apply](#4-initialize-plan-and-apply)
3.  [Deep Dive: Terraform Concepts Used](#deep-dive-terraform-concepts-used)
    * [Private Subnets](#private-subnets)
    * [Security Group Ingress Logic](#security-group-ingress-logic)
    * [Data Sources for AMIs](#data-sources-for-amis)
4.  [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision a private infrastructure stack containing a VPC, Subnet, and EC2 Instance.

**Requirements:**
1.  **VPC:** `nautilus-priv-vpc` with CIDR `10.0.0.0/16`.
2.  **Subnet:** `nautilus-priv-subnet` with CIDR `10.0.1.0/24`. Must be private (disable auto-assign public IP).
3.  **EC2:** `nautilus-priv-ec2` (t2.micro) inside the private subnet.
4.  **Security:** Allow inbound traffic *only* from the VPC's CIDR block.
5.  **Structure:** Use `variables.tf`, `main.tf`, and `outputs.tf`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Define Variables (`variables.tf`)
<a name="1-define-variables-variablestf"></a>
First, I defined the CIDR blocks as variables to keep the configuration flexible.

**Command:**
```bash
vi variables.tf
```

**Content:**
```hcl
variable "KKE_VPC_CIDR" {
  default = "10.0.0.0/16"
}

variable "KKE_SUBNET_CIDR" {
  default = "10.0.1.0/24"
}
```

### 2. Define Outputs (`outputs.tf`)
<a name="2-define-outputs-outputstf"></a>
I defined outputs to easily retrieve resource names after deployment.

**Command:**
```bash
vi outputs.tf
```

**Content:**
```hcl
output "KKE_vpc_name" {
  value = aws_vpc.devops_vpc.tags["Name"]
}

output "KKE_subnet_name" {
  value = aws_subnet.devops_subnet.tags["Name"]
}

output "KKE_ec2_private" {
  value = aws_instance.devops_ec2.tags["Name"]
}
```

### 3. Create Infrastructure (`main.tf`)
<a name="3-create-infrastructure-maintf"></a>
This is the core logic. I created the VPC, Subnet, Security Group, and EC2 instance. I also used a Data Source to fetch the latest Amazon Linux 2 AMI automatically.

**Command:**
```bash
vi main.tf
```

**Content:**
```hcl
# 1. Create the VPC
resource "aws_vpc" "devops_vpc" {
  cidr_block = var.KKE_VPC_CIDR
  tags = {
    Name = "nautilus-priv-vpc"
  }
}

# 2. Create the Private Subnet
resource "aws_subnet" "devops_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = var.KKE_SUBNET_CIDR
  map_public_ip_on_launch = false # Ensures it is a private subnet

  tags = {
    Name = "nautilus-priv-subnet"
  }
}

# 3. Create Security Group
resource "aws_security_group" "devops_sg" {
  name        = "devops_priv_sg"
  description = "Allow traffic from VPC CIDR only"
  vpc_id      = aws_vpc.devops_vpc.id

  # Ingress: Allow all traffic protocol (-1) ONLY from within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.KKE_VPC_CIDR]
  }

  # Egress: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Fetch Latest AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 5. Create EC2 Instance
resource "aws_instance" "devops_ec2" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.devops_subnet.id
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  tags = {
    Name = "nautilus-priv-ec2"
  }
}
```

### 4. Initialize, Plan, and Apply
<a name="4-initialize-plan-and-apply"></a>
Finally, I executed the Terraform workflow.

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

---

## Deep Dive: Terraform Concepts Used
<a name="deep-dive-terraform-concepts-used"></a>

### Private Subnets
<a name="private-subnets"></a>
In Terraform, defining a subnet as "private" isn't a single switch. It involves:
1.  **`map_public_ip_on_launch = false`**: This ensures instances launched here do not get a public IP address automatically.
2.  **Routing**: Although not explicitly configured in this basic task, a true private subnet usually has a Route Table that does *not* point to an Internet Gateway (IGW).

### Security Group Ingress Logic
<a name="security-group-ingress-logic"></a>
The requirement was "accessible only from within the VPC".
* **`cidr_blocks = [var.KKE_VPC_CIDR]`**: This limits incoming traffic to IP addresses that exist inside the VPC (`10.0.0.0/16`). Any traffic attempting to enter from the internet (e.g., `0.0.0.0/0`) will be blocked by this rule.

### Data Sources for AMIs
<a name="data-sources-for-amis"></a>
Hardcoding AMI IDs (e.g., `ami-0abcdef12345`) is brittle because IDs change between AWS regions and over time as AWS releases updates.
* **`data "aws_ami"`**: Allows us to query AWS for an image based on filters (like "name matches amzn2-ami*"). This ensures we always get a valid, recent image for the current region.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: `Unsupported attribute "vpc_id"`**
* **Error:**
  ```text
  Error: Unsupported attribute
  on main.tf line 11, in resource "aws_subnet" "devops_subnet":
  11:      vpc_id = aws_vpc.devops_vpc.vpc_id
  ```
* **Cause:** The `aws_vpc` resource exports an attribute named `id`, not `vpc_id`. When referencing a resource you just created, you almost always use `<RESOURCE_TYPE>.<NAME>.id`.
* **Fix:** Change `aws_vpc.devops_vpc.vpc_id` to `aws_vpc.devops_vpc.id`.

**Issue: Instance not reachable from internet**
* **Context:** This is actually **intended behavior** for this task. Since the instance is in a private subnet and the Security Group only allows internal VPC traffic, you cannot SSH into it directly from your laptop or the jump host unless the jump host is also inside the VPC.
   
