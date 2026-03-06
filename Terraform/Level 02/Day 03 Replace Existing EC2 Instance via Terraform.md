# Terraform Level 02 Day 03: Replace Existing EC2 Instance

This document outlines the solution for Terraform Level 02 Day 03. The objective was to demonstrate how to use the Terraform CLI to forcefully destroy and recreate a specific resource (an EC2 instance) even when the underlying configuration files remain unchanged.

## Table of Contents
- [Terraform Level 02 Day 03: Replace Existing EC2 Instance](#terraform-level-02-day-03-replace-existing-ec2-instance)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Verify Initial State](#1-verify-initial-state)
    - [2. Execute Forceful Replacement](#2-execute-forceful-replacement)
    - [3. Verification](#3-verification)
  - [Deep Dive: The `-replace` Flag](#deep-dive-the--replace-flag)
    - [Evolution from `taint`](#evolution-from-taint)
    - [When to use `-replace`?](#when-to-use--replace)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Forcefully recreate the `devops-ec2` instance using the Terraform CLI.

* **Working Directory:** `/home/bob/terraform`
* **Resource Name:** `aws_instance.web_server`
* **Instance Tag Name:** `devops-ec2` (defined in `terraform.tfvars`)
* **Constraint:** Do not modify any `.tf` files. The new instance must have a different unique Instance ID.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify Initial State
<a name="1-verify-initial-state"></a>
First, navigate to the terraform directory and check the current instance ID exported by your `outputs.tf`.

**Command:**
```bash
cd /home/bob/terraform
terraform output
```
*Note the current `instance_id` (e.g., `i-0abcdef1234567890`).*

### 2. Execute Forceful Replacement
<a name="2-execute-forfecul-replacement"></a>
To trigger a recreation without changing code, we use the `-replace` option during the apply phase. This tells Terraform to mark the resource as "tainted" and schedule it for a destroy/create cycle.

**Command:**
```bash
terraform apply -replace="aws_instance.web_server"
```

**Expected Interaction:**
1.  Terraform will refresh the state.
2.  The plan will show: `Plan: 1 to add, 0 to change, 1 to destroy.`
3.  Type `yes` to confirm.

### 3. Verification
<a name="3-verification"></a>
Once the process is complete, verify that the instance has been replaced by checking the outputs again.

**Command:**
```bash
terraform output
```
*Compare this with the ID from Step 1. It should be entirely different.*

**Final Check:**
```bash
terraform plan
```
*Output should return: **"No changes. Your infrastructure matches the configuration."***

---

## Deep Dive: The `-replace` Flag
<a name="deep-dive-replace-flag"></a>

### Evolution from `taint`
In older versions of Terraform (pre-0.15.2), you had to use two commands: `terraform taint <resource>` followed by `terraform apply`. This was risky because if you forgot to run apply, the resource remained "tainted" in the state file. 

The `-replace` flag (introduced in Terraform 1.1) is a safer, atomic way to handle this. It only marks the resource for replacement for that *specific* execution.

### When to use `-replace`?
1.  **Debugging User Data:** If a script in `user_data` failed but the instance is "running", Terraform sees no change in the code. You use `-replace` to rerun the initialization.
2.  **Environment Refresh:** Forcefully rotating instances to ensure they are clean and compliant.
3.  **Corruption:** If a manual change was made in the AWS Console (out-of-band) that Terraform cannot automatically reconcile through an update.
 
