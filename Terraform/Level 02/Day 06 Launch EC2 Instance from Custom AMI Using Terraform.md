# Terraform Level 02 Day 06: Launch EC2 Instance from Custom AMI

This document outlines the solution for Terraform Level 02 Day 06. The objective was to demonstrate an image-based backup and deployment workflow: creating a custom AMI (Amazon Machine Image) from an existing managed instance and launching a new instance using that specific AMI.

## Table of Contents
- [Terraform Level 02 Day 06: Launch EC2 Instance from Custom AMI](#terraform-level-02-day-06-launch-ec2-instance-from-custom-ami)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create Infrastructure Configuration (`main.tf`)](#1-create-infrastructure-configuration-maintf)
    - [2. Define Outputs (`outputs.tf`)](#2-define-outputs-outputstf)
    - [3. Execution and Validation](#3-execution-and-validation)
  - [Deep Dive: AMI Management](#deep-dive-ami-management)
    - [Resource Referencing](#resource-referencing)
    - [State Transitions during AMI Creation](#state-transitions-during-ami-creation)
    - [The Immutable Pattern](#the-immutable-pattern)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Capture an AMI from the current `devops-ec2` server and provision a new instance using that image.

* **Working Directory:** `/home/bob/terraform`
* **Source Instance:** `devops-ec2` (Resource name `aws_instance.ec2`)
* **New AMI Name:** `devops-ec2-ami`
* **New Instance Name:** `devops-ec2-new`
* **Outputs Required:**
    * `KKE_ami_id`: ID of the created AMI.
    * `KKE_new_instance_id`: ID of the new EC2 instance.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create Infrastructure Configuration (`main.tf`)
<a name="1-create-infrastructure-configuration"></a>
This configuration includes the initial EC2 resource, the AMI resource that references it, and the new EC2 resource that consumes the AMI.

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

# 1. Provision the base EC2 instance
resource "aws_instance" "ec2" {
  ami                    = "ami-0c101f26f147fa7fd"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["sg-4fb5d852bfca6d5f9"]

  tags = {
    Name = "devops-ec2"
  }
}

# 2. Create an AMI from the instance defined above
resource "aws_ami_from_instance" "custom_ami" {
  name               = "devops-ec2-ami"
  source_instance_id = aws_instance.ec2.id
}

# 3. Launch a new instance from the created AMI
resource "aws_instance" "new_node" {
  ami           = aws_ami_from_instance.custom_ami.id
  instance_type = "t2.micro"

  tags = {
    Name = "devops-ec2-new"
  }
}
```

### 2. Define Outputs (`outputs.tf`)
<a name="2-define-outputs"></a>
Export the required identifiers to satisfy the validation requirements.

**Command:**
```bash
vi outputs.tf
```

**Content:**
```hcl
output "KKE_ami_id" {
  description = "The ID of the created AMI"
  value       = aws_ami_from_instance.custom_ami.id
}

output "KKE_new_instance_id" {
  description = "The ID of the new EC2 instance launched from the AMI"
  value       = aws_instance.new_node.id
}
```

### 3. Execution and Validation
<a name="3-execution-and-validation"></a>
Apply the configuration to execute the workflow.

1.  **Initialize:** `terraform init`
2.  **Plan:** `terraform plan` (Should show 2 additional resources to add if the base instance is already in state).
3.  **Apply:** `terraform apply -auto-approve`
4.  **Verification:**
    Check the outputs:
    ```bash
    terraform output
    ```

**Final Check:**
Run `terraform plan` again. It must return:
**"No changes. Your infrastructure matches the configuration."**

---

## Deep Dive: AMI Management
<a name="deep-dive-ami-management"></a>

### Resource Referencing
In this task, we directly reference the ID of a managed resource: `source_instance_id = aws_instance.ec2.id`. This establishes an explicit dependency. Terraform ensures the base instance is running before it attempts to capture the AMI.

### State Transitions during AMI Creation
When `aws_ami_from_instance` is executed:
* **Reboot:** By default, AWS reboots the source instance to ensure filesystem consistency.
* **Snapshots:** AWS creates EBS snapshots of all volumes attached to the source instance. These snapshots form the basis of the AMI.

### The Immutable Pattern
This workflow is a cornerstone of "Immutable Infrastructure." Instead of patching servers in place, you create an image of a configured server and launch new ones from that image. This ensures consistency across a fleet of instances.
  
