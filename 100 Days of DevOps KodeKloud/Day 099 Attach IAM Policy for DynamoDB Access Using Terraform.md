# DevOps Day 99: Attach IAM Policy for DynamoDB Access Using Terraform

This document outlines the solution for DevOps Day 99. The objective was to implement secure, fine-grained access control for a DynamoDB table. I used Terraform to provision the table, create a specific IAM role for EC2 instances, and attach a strictly scoped read-only policy.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Define Variables (`variables.tf` & `terraform.tfvars`)](#1-define-variables-variablestf--terraformtfvars)
    * [2. Create Infrastructure (`main.tf`)](#2-create-infrastructure-maintf)
    * [3. Define Outputs (`outputs.tf`)](#3-define-outputs-outputstf)
    * [4. Initialize and Apply](#4-initialize-and-apply)
3.  [Deep Dive: Terraform Concepts Used](#deep-dive-terraform-concepts-used)
    * [DynamoDB Resource](#dynamodb-resource)
    * [IAM Roles & Assume Policies](#iam-roles--assume-policies)
    * [IAM Policies & JSON Encoding](#iam-policies--json-encoding)
4.  [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Create a secure DynamoDB table and an IAM role with read-only access to that specific table.

**Requirements:**
1.  **DynamoDB Table:** `xfusion-table` (Billing: PAY_PER_REQUEST, Hash Key: id).
2.  **IAM Role:** `xfusion-role` (Assumable by EC2).
3.  **IAM Policy:** `xfusion-readonly-policy` (Permissions: GetItem, Scan, Query).
4.  **Scope:** The policy must apply *only* to the created table.
5.  **Structure:** Use `variables.tf`, `terraform.tfvars`, `main.tf`, and `outputs.tf`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Define Variables (`variables.tf` & `terraform.tfvars`)
<a name="1-define-variables-variablestf--terraformtfvars"></a>
I started by defining the input variables to make the code reusable, then assigned their specific values in the `.tfvars` file.

**`variables.tf`**:
```hcl
variable "KKE_TABLE_NAME" {}
variable "KKE_ROLE_NAME" {}
variable "KKE_POLICY_NAME" {}
```

**`terraform.tfvars`**:
```hcl
KKE_TABLE_NAME  = "xfusion-table"
KKE_ROLE_NAME   = "xfusion-role"
KKE_POLICY_NAME = "xfusion-readonly-policy"
```

### 2. Create Infrastructure (`main.tf`)
<a name="2-create-infrastructure-maintf"></a>
This file ties everything together. It creates the table, the role, the policy, and the attachment between the role and policy.

**Command:**
```bash
vi main.tf
```

**Content:**
```hcl
# 1. Create DynamoDB Table
resource "aws_dynamodb_table" "xfusion_table" {
  name         = var.KKE_TABLE_NAME
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = var.KKE_TABLE_NAME
  }
}

# 2. Create IAM Role
resource "aws_iam_role" "xfusion_role" {
  name = var.KKE_ROLE_NAME

  # Trust Policy: Allows EC2 to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# 3. Create Read-Only Policy
resource "aws_iam_policy" "xfusion_readonly_policy" {
  name        = var.KKE_POLICY_NAME
  description = "Read-only access to xfusion-table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ]
      # Crucial: Restricting access ONLY to this specific table's ARN
      Resource = aws_dynamodb_table.xfusion_table.arn
    }]
  })
}

# 4. Attach Policy to Role
resource "aws_iam_role_policy_attachment" "xfusion_attach" {
  role       = aws_iam_role.xfusion_role.name
  policy_arn = aws_iam_policy.xfusion_readonly_policy.arn
}
```

### 3. Define Outputs (`outputs.tf`)
<a name="3-define-outputs-outputstf"></a>
I defined outputs to verify the created resource names.

**Content:**
```hcl
output "kke_dynamodb_table" {
  value = aws_dynamodb_table.xfusion_table.name
}

output "kke_iam_role_name" {
  value = aws_iam_role.xfusion_role.name
}

output "kke_iam_policy_name" {
  value = aws_iam_policy.xfusion_readonly_policy.name
}
```

### 4. Initialize and Apply
<a name="4-initialize-and-apply"></a>
I initialized Terraform to download the AWS provider and applied the configuration.

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

---

## Deep Dive: Terraform Concepts Used
<a name="deep-dive-terraform-concepts-used"></a>

### DynamoDB Resource
<a name="dynamodb-resource"></a>
* **`aws_dynamodb_table`**: Creates a NoSQL table.
* **`billing_mode = "PAY_PER_REQUEST"`**: This is ideal for unpredictable workloads or dev environments as you don't pay for idle capacity.
* **`hash_key`**: This is the primary key. We defined a simple primary key named `id` of type String (`S`).

### IAM Roles & Assume Policies
<a name="iam-roles--assume-policies"></a>
* **Role vs. User**: A Role is an identity you *assume*, not one you log in as.
* **`assume_role_policy`**: This is the "Trust Policy". It defines *who* can wear the hat. In our code, we specified `Principal: { Service: "ec2.amazonaws.com" }`, meaning only EC2 instances can use this role.

### IAM Policies & JSON Encoding
<a name="iam-policies--json-encoding"></a>
* **`jsonencode`**: Writing policies in native Terraform maps/lists is cleaner and safer than writing raw JSON strings. Terraform handles the formatting and escaping.
* **Dynamic ARN Reference**: Instead of hardcoding the resource ARN (e.g., `arn:aws:dynamodb:us-east-1:123:table/xfusion-table`), I used `aws_dynamodb_table.xfusion_table.arn`. This ensures the policy always points to the exact table Terraform created, even if the region or account ID changes.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: Invalid JSON Syntax**
* **Error:** `MalformedPolicyDocument`
* **Cause:** Often caused by writing raw JSON strings with incorrect escaping.
* **Fix:** Always use the `jsonencode()` function in Terraform for policy documents.

**Issue: Cycle Error**
* **Cause:** If you try to reference the Policy ARN inside the Role creation or vice-versa incorrectly.
* **Fix:** Keep resources separate. Create the Role, create the Policy, and then link them with `aws_iam_role_policy_attachment`.
   
