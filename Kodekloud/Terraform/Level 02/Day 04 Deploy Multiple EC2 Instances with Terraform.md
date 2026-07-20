# Terraform Level 02 Day 04: Deploy Multiple EC2 Instances

This document outlines the solution for Terraform Level 02 Day 04. The objective was to provision a scalable set of EC2 instances using the `count` meta-argument while maintaining a clean, modular structure using variables, locals, and data sources.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Define Variables (`variables.tf`)](#1-define-variables)
    * [2. Configure Locals and Data Sources (`locals.tf`)](#2-configure-locals)
    * [3. Set Variable Values (`terraform.tfvars`)](#3-set-variable-values)
    * [4. Create Infrastructure (`main.tf`)](#4-create-infrastructure)
    * [5. Define Outputs (`outputs.tf`)](#5-define-outputs)
3.  [Deep Dive: Scaling with `count`](#deep-dive-scaling-with-count)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision 3 EC2 instances with standardized naming and modular configuration.

* **Working Directory:** `/home/bob/terraform`
* **Count:** 3 instances.
* **Instance Type:** `t2.micro`.
* **Naming Convention:** `datacenter-instance-1`, `datacenter-instance-2`, etc.
* **Key Pair:** `datacenter-key`.
* **AMI Requirement:** Dynamically retrieve the latest Amazon Linux 2 AMI ID.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Define Variables (`variables.tf`)
<a name="1-define-variables"></a>
Declare the inputs required for the configuration to ensure reusability.

**Command:**
```bash
cd /home/bob/terraform
vi variables.tf
```

**Content:**
```hcl
variable "KKE_INSTANCE_COUNT" {
  description = "Number of instances to provision"
  type        = number
}

variable "KKE_INSTANCE_TYPE" {
  description = "The EC2 instance hardware type"
  type        = string
}

variable "KKE_KEY_NAME" {
  description = "The name of the SSH key pair"
  type        = string
}

variable "KKE_INSTANCE_PREFIX" {
  description = "Prefix for instance naming"
  type        = string
}
```

### 2. Configure Locals and Data Sources (`locals.tf`)
<a name="2-configure-locals"></a>
Use a data source to find the latest AMI and assign it to a local variable for internal use.

**Command:**
```bash
vi locals.tf
```

**Content:**
```hcl
data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  AMI_ID = data.aws_ami.latest_amazon_linux_2.id
}
```

### 3. Set Variable Values (`terraform.tfvars`)
<a name="3-set-variable-values"></a>
Provide the specific values requested by the Nautilus DevOps team.

**Command:**
```bash
vi terraform.tfvars
```

**Content:**
```hcl
KKE_INSTANCE_COUNT  = 3
KKE_INSTANCE_TYPE   = "t2.micro"
KKE_KEY_NAME        = "datacenter-key"
KKE_INSTANCE_PREFIX = "datacenter-instance"
```

### 4. Create Infrastructure (`main.tf`)
<a name="4-create-infrastructure"></a>
Define the EC2 resource using the `count` meta-argument and dynamic tagging.

**Command:**
```bash
vi main.tf
```

**Content:**
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "datacenter_nodes" {
  count         = var.KKE_INSTANCE_COUNT
  ami           = local.AMI_ID
  instance_type = var.KKE_INSTANCE_TYPE
  key_name      = var.KKE_KEY_NAME

  tags = {
    # Dynamically generates names: datacenter-instance-1, 2, 3
    Name = "${var.KKE_INSTANCE_PREFIX}-${count.index + 1}"
  }
}
```

### 5. Define Outputs (`outputs.tf`)
<a name="5-define-outputs"></a>
Export the names of the created instances for verification.

**Command:**
```bash
vi outputs.tf
```

**Content:**
```hcl
output "kke_instance_names" {
  value = aws_instance.datacenter_nodes[*].tags["Name"]
}
```

---

## Deep Dive: Scaling with `count`
<a name="deep-dive-scaling-with-count"></a>

### The `count` Meta-Argument
Instead of defining the same `aws_instance` resource block three times, we use `count`. This tells Terraform to manage a list of identical resources.
* **`count.index`**: This is a zero-based integer representing the current index in the loop. By using `${count.index + 1}`, we transform the index from `0, 1, 2` to a human-friendly `1, 2, 3`.

### Locals vs. Variables
* **Variables (`var.`)**: These are external inputs. You use them when you want to allow a user or a `.tfvars` file to change values.
* **Locals (`local.`)**: These are internal constants or calculated values. They are not intended to be changed from the outside. In this task, we use a local for `AMI_ID` because it's a calculated value derived from a data source.

### The Splat Operator (`[*]`)
In the `outputs.tf`, we used `aws_instance.datacenter_nodes[*]`. Since the resource has a `count`, it is treated as a list. The splat operator allows us to iterate through all instances in that list and extract a specific attribute (the Name tag) for each.
   
