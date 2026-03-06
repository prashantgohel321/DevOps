# Terraform Level 02 Day 01: Create VPC and Subnet with Dependencies

This document outlines the solution for Terraform Level 02 Day 01. The objective was to provision core AWS networking components while explicitly defining resource dependencies using the `depends_on` meta-argument.

## Table of Contents
- [Terraform Level 02 Day 01: Create VPC and Subnet with Dependencies](#terraform-level-02-day-01-create-vpc-and-subnet-with-dependencies)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Define Variables (`variables.tf`)](#1-define-variables-variablestf)
    - [2. Set Variable Values (`terraform.tfvars`)](#2-set-variable-values-terraformtfvars)
    - [3. Create Infrastructure (`main.tf`)](#3-create-infrastructure-maintf)
    - [4. Define Outputs (`outputs.tf`)](#4-define-outputs-outputstf)
    - [5. Execution and Validation](#5-execution-and-validation)
  - [Deep Dive: Implicit vs. Explicit Dependencies](#deep-dive-implicit-vs-explicit-dependencies)
    - [Implicit Dependencies](#implicit-dependencies)
    - [Explicit Dependencies (`depends_on`)](#explicit-dependencies-depends_on)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Create a VPC and a Subnet where the Subnet explicitly depends on the VPC.

* **Working Directory:** `/home/bob/terraform`
* **VPC Name:** `devops-vpc` (sourced from variable `KKE_VPC_NAME`)
* **Subnet Name:** `devops-subnet` (sourced from variable `KKE_SUBNET_NAME`)
* **Key Requirement:** Use the `depends_on` argument in the Subnet resource.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Define Variables (`variables.tf`)
<a name="1-define-variables"></a>
Declare the variables to allow for dynamic naming of the networking resources.

**Command:**
```bash
cd /home/bob/terraform
vi variables.tf
```

**Content:**
```hcl
variable "KKE_VPC_NAME" {
  description = "The name of the VPC"
  type        = string
}

variable "KKE_SUBNET_NAME" {
  description = "The name of the Subnet"
  type        = string
}
```

### 2. Set Variable Values (`terraform.tfvars`)
<a name="2-set-variable-values"></a>
Provide the actual string values for the defined variables.

**Command:**
```bash
vi terraform.tfvars
```

**Content:**
```hcl
KKE_VPC_NAME    = "devops-vpc"
KKE_SUBNET_NAME = "devops-subnet"
```

### 3. Create Infrastructure (`main.tf`)
<a name="3-create-infrastructure"></a>
Define the AWS resources. The Subnet resource includes an explicit `depends_on` block.

**Command:**
```bash
vi main.tf
```

**Content:**
```hcl
provider "aws" {
  region = "us-east-1"
}

# Create the VPC
resource "aws_vpc" "devops_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.KKE_VPC_NAME
  }
}

# Create the Subnet
resource "aws_subnet" "devops_subnet" {
  vpc_id     = aws_vpc.devops_vpc.id
  cidr_block = "10.0.1.0/24"

  # Explicit dependency definition
  depends_on = [
    aws_vpc.devops_vpc
  ]

  tags = {
    Name = var.KKE_SUBNET_NAME
  }
}
```

### 4. Define Outputs (`outputs.tf`)
<a name="4-define-outputs"></a>
Configure Terraform to output the names of the resources after creation.

**Command:**
```bash
vi outputs.tf
```

**Content:**
```hcl
output "kke_vpc_name" {
  value = aws_vpc.devops_vpc.tags["Name"]
}

output "kke_subnet_name" {
  value = aws_subnet.devops_subnet.tags["Name"]
}
```

### 5. Execution and Validation
<a name="5-execution-and-validation"></a>
Follow the standard Terraform workflow to deploy and verify.

1.  **Initialize:** `terraform init`
2.  **Plan:** `terraform plan` (Verify 2 resources to add).
3.  **Apply:** `terraform apply -auto-approve`
4.  **Final Check:** Run `terraform plan` again. It should return **"No changes. Your infrastructure matches the configuration."**

---

## Deep Dive: Implicit vs. Explicit Dependencies
<a name="deep-dive-dependencies"></a>

### Implicit Dependencies
Terraform automatically understands the order of creation by looking at references. In our `aws_subnet` resource, the line `vpc_id = aws_vpc.devops_vpc.id` creates an **implicit dependency**. Terraform knows it cannot create the Subnet without the VPC ID, so it always creates the VPC first.

### Explicit Dependencies (`depends_on`)
The `depends_on` meta-argument is used to define dependencies that Terraform **cannot** infer automatically. 
* **Use Case:** When a resource relies on another resource's behavior rather than its data (e.g., an application that needs an S3 bucket to exist and have a specific policy applied before the app starts, even if the app doesn't reference the bucket ARN directly).
* **In this Task:** Although the dependency is already implicit via the `vpc_id` reference, adding `depends_on` explicitly reinforces the provisioning order as per the DevOps team's requirements.
  