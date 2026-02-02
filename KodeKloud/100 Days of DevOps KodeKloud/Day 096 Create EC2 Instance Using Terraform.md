# DevOps Day 96: Create EC2 Instance Using Terraform

This document outlines the solution for DevOps Day 96. The objective was to provision an AWS EC2 instance using Terraform, including generating an SSH key pair and attaching it to the instance for secure access.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Create `main.tf`](#1-create-maintf)
    * [2. Initialize and Apply](#2-initialize-and-apply)
    * [3. Verification](#3-verification)
3.  [Deep Dive: Terraform Concepts Used](#deep-dive-terraform-concepts-used)
    * [TLS Private Key & AWS Key Pair](#tls-private-key--aws-key-pair)
    * [EC2 Instance Resource](#ec2-instance-resource)
    * [Data Sources (Security Groups)](#data-sources-security-groups)
4.  [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision an AWS EC2 instance named `datacenter-ec2` with a specific AMI and instance type, secured by a new SSH key pair.

**Requirements:**
1.  **Directory:** `/home/bob/terraform`
2.  **File:** `main.tf`
3.  **Key Pair:** Create a new RSA key named `datacenter-kp`.
4.  **EC2 Instance:**
    * **AMI:** `ami-0c101f26f147fa7fd`
    * **Type:** `t2.micro`
    * **Name Tag:** `datacenter-ec2`
    * **Security Group:** Attach the `default` security group.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create `main.tf`
<a name="1-create-maintf"></a>
We define the necessary resources: a cryptographic key, an AWS key pair resource to upload that key, a data source to find the security group, and finally the instance itself.

**Command:**
```bash
cd /home/bob/terraform
vi main.tf
```

**Content:**
```hcl
# 1. Generate a secure private key locally
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Create an AWS Key Pair using the public key from the resource above
resource "aws_key_pair" "deployer" {
  key_name   = "datacenter-kp"
  public_key = tls_private_key.my_key.public_key_openssh
}

# 3. Find the 'default' Security Group ID dynamically
data "aws_security_group" "default_sg" {
  name = "default"
}

# 4. Create the EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  # Attach the security group found in step 3
  vpc_security_group_ids = [data.aws_security_group.default_sg.id]

  tags = {
    Name = "datacenter-ec2"
  }
}
```

### 2. Initialize and Apply
<a name="2-initialize-and-apply"></a>
Run the standard Terraform workflow.

1.  **Initialize:** Downloads the AWS and TLS provider plugins.
    ```bash
    terraform init
    ```
2.  **Plan:** Previews the creation of the key, key pair, and instance.
    ```bash
    terraform plan
    ```
3.  **Apply:** Deploys the resources.
    ```bash
    terraform apply -auto-approve
    ```

### 3. Verification
<a name="3-verification"></a>
Verify that Terraform is tracking the resources.
```bash
terraform state list
# Expected Output:
# data.aws_security_group.default_sg
# aws_instance.web
# aws_key_pair.deployer
# tls_private_key.my_key
```

---

## Deep Dive: Terraform Concepts Used
<a name="deep-dive-terraform-concepts-used"></a>

### TLS Private Key & AWS Key Pair
<a name="tls-private-key--aws-key-pair"></a>
This is a powerful pattern for managing access.
* **`tls_private_key`**: Generates the raw cryptographic material (the private and public key data) within Terraform's memory.
* **`aws_key_pair`**: Takes the public key part (`public_key_openssh`) and uploads it to AWS console so it can be injected into EC2 instances.
* **Security Note:** The private key exists in your `terraform.tfstate` file. In production, treat your state file as a sensitive secret!

### EC2 Instance Resource
<a name="ec2-instance-resource"></a>
* **`aws_instance`**: The fundamental resource for creating virtual machines.
* **`key_name`**: Links the instance to the Key Pair we created, allowing SSH access.
* **`vpc_security_group_ids`**: Controls network access. We used a list `[]` because an instance can have multiple security groups.

### Data Sources (Security Groups)
<a name="data-sources-security-groups"></a>
* **`data "aws_security_group"`**: Instead of hardcoding a Security Group ID (like `sg-12345`), which changes per account/region, we tell Terraform to "Find the group named 'default'". This makes the code portable across different AWS accounts.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: "AMI not found"**
* **Cause:** The AMI ID `ami-0c101f26f147fa7fd` is specific to a region (likely `us-east-1`). If your provider is configured for a different region (e.g., `us-west-2`), this AMI ID will not exist there.
* **Fix:** Ensure your `provider "aws"` block or environment variables specify `region = "us-east-1"`.

**Issue: "InvalidKey.Format"**
* **Cause:** If you try to paste a pre-generated key incorrectly into the `public_key` field.
* **Fix:** Using `tls_private_key` resource (as done in the solution) avoids format errors because Terraform handles the string generation automatically.
  
