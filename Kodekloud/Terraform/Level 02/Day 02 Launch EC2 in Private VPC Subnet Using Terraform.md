# Terraform Level 02 Day 02: Launch EC2 in Private VPC Subnet

This document outlines the solution for Terraform Level 02 Day 02. The objective was to architect a secure, isolated AWS environment using Infrastructure as Code. This involves creating a custom VPC, a private subnet (with auto-assign IP disabled), a restricted Security Group, and an EC2 instance.

## Table of Contents
- [Terraform Level 02 Day 02: Launch EC2 in Private VPC Subnet](#terraform-level-02-day-02-launch-ec2-in-private-vpc-subnet)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Define Variables (`variables.tf`)](#1-define-variables-variablestf)
    - [2. Create Infrastructure (`main.tf`)](#2-create-infrastructure-maintf)
    - [3. Define Outputs (`outputs.tf`)](#3-define-outputs-outputstf)
    - [4. Execution and Validation](#4-execution-and-validation)
  - [Deep Dive: Private Subnets \& Internal Security](#deep-dive-private-subnets--internal-security)
    - [Private Subnet Logic](#private-subnet-logic)
    - [Security Group Scope](#security-group-scope)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision a private infrastructure stack in AWS using Terraform.

* **Working Directory:** `/home/bob/terraform`
* **VPC:** `nautilus-priv-vpc` with CIDR `10.0.0.0/16`.
* **Subnet:** `nautilus-priv-subnet` with CIDR `10.0.1.0/24`. `map_public_ip_on_launch` must be `false`.
* **Security Group:** Allow inbound traffic *only* from the VPC CIDR block.
* **EC2 Instance:** `nautilus-priv-ec2` of type `t2.micro` launched in the private subnet.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Define Variables (`variables.tf`)
<a name="1-define-variables"></a>
Declare the variables for the CIDR blocks to maintain a modular configuration.

**Command:**
```bash
cd /home/bob/terraform
vi variables.tf
```

**Content:**
```hcl
variable "KKE_VPC_CIDR" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "KKE_SUBNET_CIDR" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.1.0/24"
}
```

### 2. Create Infrastructure (`main.tf`)
<a name="2-create-infrastructure"></a>
Define the AWS resources. This file includes the provider, VPC, Subnet, Security Group, and the EC2 instance. Note the use of a data source to fetch a valid AMI.

**Command:**
```bash
vi main.tf
```

**Content:**
```hcl
provider "aws" {
  region = "us-east-1"
}

# 1. Create the VPC
resource "aws_vpc" "nautilus_vpc" {
  cidr_block = var.KKE_VPC_CIDR

  tags = {
    Name = "nautilus-priv-vpc"
  }
}

# 2. Create the Private Subnet
resource "aws_subnet" "nautilus_subnet" {
  vpc_id                  = aws_vpc.nautilus_vpc.id
  cidr_block              = var.KKE_SUBNET_CIDR
  map_public_ip_on_launch = false

  tags = {
    Name = "nautilus-priv-subnet"
  }
}

# 3. Create Security Group
resource "aws_security_group" "nautilus_sg" {
  name        = "nautilus-priv-sg"
  description = "Allow internal VPC traffic only"
  vpc_id      = aws_vpc.nautilus_vpc.id

  # Ingress: Allow all protocols from within the VPC CIDR
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

# 4. Fetch Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 5. Launch EC2 Instance
resource "aws_instance" "nautilus_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.nautilus_subnet.id
  vpc_security_group_ids = [aws_security_group.nautilus_sg.id]

  tags = {
    Name = "nautilus-priv-ec2"
  }
}
```

### 3. Define Outputs (`outputs.tf`)
<a name="3-define-outputs"></a>
Configure the outputs to verify resource names as required.

**Command:**
```bash
vi outputs.tf
```

**Content:**
```hcl
output "KKE_vpc_name" {
  value = aws_vpc.nautilus_vpc.tags["Name"]
}

output "KKE_subnet_name" {
  value = aws_subnet.nautilus_subnet.tags["Name"]
}

output "KKE_ec2_private" {
  value = aws_instance.nautilus_ec2.tags["Name"]
}
```

### 4. Execution and Validation
<a name="4-execution-and-validation"></a>
Follow the standard Terraform workflow.

1.  **Initialize:** `terraform init`
2.  **Plan:** `terraform plan` (Verify 4 resources to add).
3.  **Apply:** `terraform apply -auto-approve`
4.  **Final Check:** Run `terraform plan` again. It must return **"No changes. Your infrastructure matches the configuration."**

---

## Deep Dive: Private Subnets & Internal Security
<a name="deep-dive-private-subnets"></a>

### Private Subnet Logic
A subnet is considered "private" in AWS if:
1.  **`map_public_ip_on_launch = false`**: Instances created here do not receive a public IP address, making them unreachable from the internet.
2.  **Routing**: The associated route table does *not* have a route to an Internet Gateway (IGW).

### Security Group Scope
The requirement was to allow access "only from within the VPC's CIDR block."
* **`cidr_blocks = [var.KKE_VPC_CIDR]`**: By setting the ingress rule to the VPC's own range (`10.0.0.0/16`), we ensure that even if the instance had a public IP (which it doesn't), the firewall would block any traffic originating from outside the `nautilus-priv-vpc` network.
* **`protocol = "-1"`**: This is shorthand for "all protocols." It allows internal services (like databases or internal APIs) to communicate using any port or protocol they require.
  
