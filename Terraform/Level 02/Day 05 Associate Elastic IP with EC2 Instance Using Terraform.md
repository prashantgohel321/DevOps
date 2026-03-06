# Terraform Level 02 Day 05: Associate Elastic IP with EC2 Instance

This document outlines the solution for Terraform Level 02 Day 05. The objective was to provide the Development Team with a stable, persistent access point for their application by provisioning an EC2 instance and associating it with an AWS Elastic IP (EIP).

## Table of Contents
- [Terraform Level 02 Day 05: Associate Elastic IP with EC2 Instance](#terraform-level-02-day-05-associate-elastic-ip-with-ec2-instance)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create Infrastructure (`main.tf`)](#1-create-infrastructure-maintf)
    - [2. Define Outputs (`outputs.tf`)](#2-define-outputs-outputstf)
    - [3. Execution and Validation](#3-execution-and-validation)
  - [Deep Dive: Elastic IP Architecture](#deep-dive-elastic-ip-architecture)
    - [What is an Elastic IP?](#what-is-an-elastic-ip)
    - [Association Logic](#association-logic)
    - [Use Cases](#use-cases)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Deploy an Ubuntu EC2 instance and ensure it has a static public IP address.

* **Working Directory:** `/home/bob/terraform`
* **EC2 Instance:** `nautilus-ec2` (type: `t2.micro`, image: Ubuntu).
* **Elastic IP:** `nautilus-eip` associated with the instance.
* **Outputs Required:** * `KKE_instance_name`: Name tag of the instance.
    * `KKE_eip`: The actual Elastic IP address.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create Infrastructure (`main.tf`)
<a name="1-create-infrastructure"></a>
This file initializes the provider, fetches a valid Ubuntu AMI, and defines the EC2 and EIP resources. Note that we link the EIP to the instance using the `instance` attribute.

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

# Data Source: Get the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Resource: EC2 Instance
resource "aws_instance" "nautilus_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "nautilus-ec2"
  }
}

# Resource: Elastic IP
resource "aws_eip" "nautilus_eip" {
  instance = aws_instance.nautilus_ec2.id
  domain   = "vpc"

  tags = {
    Name = "nautilus-eip"
  }
}
```

### 2. Define Outputs (`outputs.tf`)
<a name="2-define-outputs"></a>
Define the specific output variables requested for validation.

**Command:**
```bash
vi outputs.tf
```

**Content:**
```hcl
output "KKE_instance_name" {
  value = aws_instance.nautilus_ec2.tags["Name"]
}

output "KKE_eip" {
  value = aws_eip.nautilus_eip.public_ip
}
```

### 3. Execution and Validation
<a name="3-execute-and-validate"></a>
Initialize and apply the configuration.

1.  **Initialize:** `terraform init`
2.  **Plan:** `terraform plan` (Verify 2 resources to add).
3.  **Apply:** `terraform apply -auto-approve`
4.  **Verification:**
    Run `terraform output` to see the assigned Elastic IP.
    ```bash
    terraform output
    ```

**Final Check:**
Run `terraform plan` one last time. It must return:
**"No changes. Your infrastructure matches the configuration."**

---

## Deep Dive: Elastic IP Architecture
<a name="deep-dive-elastic-ip-architecture"></a>

### What is an Elastic IP?
An Elastic IP (EIP) is a static, public IPv4 address designed for dynamic cloud computing. Unlike standard public IPs which change whenever an instance is stopped and started, an EIP is associated with your AWS account and remains yours until you explicitly release it.

### Association Logic
In this configuration, we defined the association directly within the `aws_eip` resource using the `instance` attribute:
`instance = aws_instance.nautilus_ec2.id`

This creates a dependency where Terraform ensures the EC2 instance is created *before* attempting to allocate and map the IP address.

### Use Cases
* **Consistent Access:** Providing a stable endpoint for mobile apps or third-party APIs that whitelist specific IP addresses.
* **DNS Stability:** Allowing you to map a DNS record (like `app.nautilus.com`) to an IP that won't change during maintenance windows or instance upgrades.
   
