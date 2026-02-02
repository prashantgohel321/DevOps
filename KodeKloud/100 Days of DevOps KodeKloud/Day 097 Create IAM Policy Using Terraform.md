# DevOps Day 97: Create IAM Policy Using Terraform

This document outlines the solution for DevOps Day 97. The objective was to provision an AWS IAM Policy that grants read-only access to the EC2 console using Terraform.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Create `main.tf`](#1-create-maintf)
    * [2. Initialize Terraform](#2-initialize-terraform)
    * [3. Plan and Apply](#3-plan-and-apply)
3.  [Deep Dive: Terraform Concepts Used](#deep-dive-terraform-concepts-used)
    * [IAM Policy Resource](#iam-policy-resource)
    * [JSON Policy Document](#json-policy-document)
4.  [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Create an IAM policy named `iampolicy_yousuf` in the `us-east-1` region that allows read-only access to EC2 instances, AMIs, and snapshots.

**Requirements:**
1.  **Directory:** `/home/bob/terraform`
2.  **File:** `main.tf`
3.  **Resource:** `aws_iam_policy`
4.  **Properties:**
    * **Name:** `iampolicy_yousuf`
    * **Description:** "Read-only access to EC2 Console (instances, AMIs and snapshots)"
    * **Permissions:** `ec2:Describe*` on all resources (`*`).

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create `main.tf`
<a name="1-create-maintf"></a>
We define the IAM policy resource. The crucial part is the `policy` argument, which expects a JSON string. We use Terraform's `jsonencode` function to write this cleanly.

**Command:**
```bash
cd /home/bob/terraform
vi main.tf
```

**Content:**
```hcl
resource "aws_iam_policy" "policy_yousuf" {
  name        = "iampolicy_yousuf"
  description = "Read-only access to EC2 Console (instances, AMIs and snapshots)"

  # Using jsonencode ensures the policy is formatted correctly without manual escaping
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
```

### 2. Initialize Terraform
<a name="2-initialize-terraform"></a>
Prepare the working directory by downloading the necessary provider plugins.

**Command:**
```bash
terraform init
```

### 3. Plan and Apply
<a name="3-plan-and-apply"></a>
Preview the changes and then apply them to create the infrastructure.

**Commands:**
```bash
terraform plan
terraform apply -auto-approve
```

**Verification:**
After applying, you can list the state to confirm the resource exists.
```bash
terraform state list
# Expected output: aws_iam_policy.policy_yousuf
```

---

## Deep Dive: Terraform Concepts Used
<a name="deep-dive-terraform-concepts-used"></a>

### IAM Policy Resource
<a name="iam-policy-resource"></a>
* **`aws_iam_policy`**: This resource creates a managed policy in IAM. Managed policies are standalone policies that you can attach to multiple users, groups, and roles.

### JSON Policy Document
<a name="json-policy-document"></a>
* **`jsonencode()`**: Writing raw JSON inside a Terraform file can be messy due to quote escaping (e.g., `"{\"Version\": \"...\"}"`). The `jsonencode` function allows you to write standard HCL (Terraform language) maps and lists, and it automatically converts them to valid JSON string format required by the AWS API.
* **`ec2:Describe*`**: This wild-card action grants permission for all API calls starting with "Describe". In AWS, "Describe" actions are read-only (viewing lists of instances, volumes, snapshots, etc.), satisfying the "read-only access" requirement.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: Syntax Error in JSON**
* **Cause:** A common mistake (visible in the initial prompt) is using an equals sign inside the version string: `"Version" = "2012=10-17"`.
* **Fix:** The correct AWS Policy version string is `"2012-10-17"`.

**Issue: Invalid Action**
* **Cause:** Providing an action that doesn't exist, like `ec2:ListAll`.
* **Fix:** Verify permission names in the AWS Policy Generator documentation. `ec2:Describe*` is the standard for read-only access.
    
