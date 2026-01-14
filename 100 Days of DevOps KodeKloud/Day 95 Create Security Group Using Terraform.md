# DevOps Day 95: Create Security Group Using Terraform

This document outlines the solution for DevOps Day 95. The objective was to provision an AWS Security Group in the default VPC using Terraform, with specific inbound rules for HTTP (port 80) and SSH (port 22).

## Table of Contents
- [DevOps Day 95: Create Security Group Using Terraform](#devops-day-95-create-security-group-using-terraform)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create `variables.tf`](#1-create-variablestf)
    - [2. Create `main.tf`](#2-create-maintf)
    - [3. Initialize and Apply](#3-initialize-and-apply)
  - [Deep Dive: Terraform Concepts Used](#deep-dive-terraform-concepts-used)
    - [Data Sources (`aws_vpc`)](#data-sources-aws_vpc)
    - [Resources (`aws_security_group`)](#resources-aws_security_group)
    - [Ingress Rules](#ingress-rules)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Create a Security Group named `datacenter-sg` in the `us-east-1` region within the default VPC.

**Requirements:**
1.  **Directory:** `/home/bob/terraform`
2.  **Files:** `variables.tf` (optional but good practice) and `main.tf`.
3.  **Resource:** `aws_security_group`.
4.  **Properties:**
    * **Name:** `datacenter-sg`
    * **Description:** "Security group for Nautilus App Servers"
    * **Inbound Rule 1:** HTTP (Port 80) from `0.0.0.0/0`.
    * **Inbound Rule 2:** SSH (Port 22) from `0.0.0.0/0`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create `variables.tf`
<a name="1-create-variablestf"></a>
We define variables to make our configuration cleaner and reusable.

**Command:**
```bash
cd /home/bob/terraform
vi variables.tf
```

**Content:**
```hcl
variable "sg_name" {
  default = "datacenter-sg"
}

variable "sg_description" {
  default = "Security group for Nautilus App Servers"
}
```

### 2. Create `main.tf`
<a name="2-create-maintf"></a>
This is the core configuration. We use a **Data Source** to find the default VPC ID dynamically, and a **Resource** to create the Security Group.

**Command:**
```bash
vi main.tf
```

**Content:**
```hcl
# Data Source: Get the Default VPC
data "aws_vpc" "default_vpc" {
  default = true
}

# Resource: Create the Security Group
resource "aws_security_group" "xfusion_sg" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = data.aws_vpc.default_vpc.id
  
  # Inbound Rule for HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound Rule for SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### 3. Initialize and Apply
<a name="3-initialize-and-apply"></a>
Run the Terraform workflow to deploy the infrastructure.

1.  **Initialize:** Downloads the AWS provider plugin.
    ```bash
    terraform init
    ```
2.  **Plan:** Shows what Terraform intends to do.
    ```bash
    terraform plan
    ```
3.  **Apply:** Executes the plan. The `-auto-approve` flag skips the "yes" confirmation prompt.
    ```bash
    terraform apply -auto-approve
    ```

**Verification:**
To verify the creation, you can list the state or use the AWS CLI (if configured).
```bash
terraform state list
# Expected Output:
# data.aws_vpc.default_vpc
# aws_security_group.xfusion_sg
```

---

## Deep Dive: Terraform Concepts Used
<a name="deep-dive-terraform-concepts-used"></a>

### Data Sources (`aws_vpc`)
<a name="data-sources-aws_vpc"></a>
Data sources allow Terraform to use information defined outside of Terraform.
* `data "aws_vpc" "default_vpc"`: This tells Terraform to query AWS for an existing VPC.
* `default = true`: The filter used to find the specific VPC we want (the default one).
* `data.aws_vpc.default_vpc.id`: How we reference the ID of the found VPC in other resources.

### Resources (`aws_security_group`)
<a name="resources-aws_security_group"></a>
Resources are the most important element in Terraform. They define the infrastructure objects you want to create.
* `resource "aws_security_group" "xfusion_sg"`: This declares a security group resource. `xfusion_sg` is the internal Terraform name, while `var.sg_name` ("datacenter-sg") becomes the actual AWS resource name.

### Ingress Rules
<a name="ingress-rules"></a>
* **Ingress:** Defines inbound traffic rules (traffic coming *into* the server).
* **Egress:** Defines outbound traffic rules (traffic leaving the server). By default, AWS Security Groups allow all outbound traffic, so we didn't need to define an egress block explicitly for this task unless we wanted to restrict it.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: `Unsupported block type`**
* **Error:** `Blocks of type "ingres" are not expected here.`
* **Cause:** A typo in the `main.tf` file. The keyword was written as `ingres` instead of `ingress`.
* **Fix:** Correct spelling to `ingress` in the `main.tf` file.

**Issue: `vpc_id` is required**
* **Cause:** Creating a Security Group without specifying a VPC ID creates it in the default VPC in older platforms (EC2-Classic), but in modern VPCs, it's best practice (and often required) to specify the VPC ID explicitly using the data source method shown above.
   