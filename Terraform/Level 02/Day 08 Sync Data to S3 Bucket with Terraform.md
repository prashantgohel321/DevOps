# Terraform Level 02 Day 08: Sync Data to S3 Bucket

This document outlines the solution for Terraform Level 02 Day 08. The objective was to create a new private S3 bucket and migrate (sync) all data from an existing source bucket to the new destination bucket using Terraform's orchestration capabilities.

## Table of Contents
- [Terraform Level 02 Day 08: Sync Data to S3 Bucket](#terraform-level-02-day-08-sync-data-to-s3-bucket)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Define Variables (`variables.tf`)](#1-define-variables-variablestf)
    - [2. Set Variable Values (`terraform.tfvars`)](#2-set-variable-values-terraformtfvars)
    - [3. Update Infrastructure (`main.tf`)](#3-update-infrastructure-maintf)
    - [4. Define Outputs (`outputs.tf`)](#4-define-outputs-outputstf)
    - [5. Execution and Validation](#5-execution-and-validation)
  - [Deep Dive: S3 Data Migration in IaC](#deep-dive-s3-data-migration-in-iac)
    - [Why use `null_resource`?](#why-use-null_resource)
    - [The `local-exec` Provisioner](#the-local-exec-provisioner)
    - [Verification](#verification)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision a target S3 bucket and synchronize content from the source bucket.

* **Working Directory:** `/home/bob/terraform`
* **Source Bucket:** `nautilus-s3-6930`
* **Target Bucket:** `nautilus-sync-28584` (Variable: `KKE_BUCKET`)
* **Outputs Required:**
    * `new_kke_bucket_name`
    * `new_kke_bucket_acl`

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Define Variables (`variables.tf`)
<a name="1-define-variables"></a>
Declare the variable for the new bucket name.

**Command:**
```bash
cd /home/bob/terraform
vi variables.tf
```

**Content:**
```hcl
variable "KKE_BUCKET" {
  description = "The name for the new S3 bucket"
  type        = string
}
```

### 2. Set Variable Values (`terraform.tfvars`)
<a name="2-set-variable-values"></a>
Provide the target bucket name value.

**Command:**
```bash
vi terraform.tfvars
```

**Content:**
```hcl
KKE_BUCKET = "nautilus-sync-28584"
```

### 3. Update Infrastructure (`main.tf`)
<a name="3-update-infrastructure"></a>
Modify the `main.tf` to include the new bucket and the synchronization logic. We use a `null_resource` with a `local-exec` provisioner to perform the AWS CLI `s3 sync`.

**Command:**
```bash
vi main.tf
```

**Content:**
```hcl
# Existing source bucket resource
resource "aws_s3_bucket" "wordpress_bucket" {
  bucket = "nautilus-s3-6930"
}

resource "aws_s3_bucket_acl" "wordpress_bucket_acl" {
  bucket = aws_s3_bucket.wordpress_bucket.id
  acl    = "private"
}

# 1. Create the New Private S3 Bucket
resource "aws_s3_bucket" "sync_bucket" {
  bucket = var.KKE_BUCKET
}

resource "aws_s3_bucket_acl" "sync_bucket_acl" {
  bucket = aws_s3_bucket.sync_bucket.id
  acl    = "private"
}

# 2. Data Migration Logic
# Using null_resource to trigger the sync during apply
resource "null_resource" "s3_sync" {
  triggers = {
    # Re-run if either bucket ID changes
    source_bucket = aws_s3_bucket.wordpress_bucket.id
    target_bucket = aws_s3_bucket.sync_bucket.id
  }

  provisioner "local-exec" {
    # Standard sync command using the LocalStack endpoint provided in provider.tf
    command = "aws --endpoint-url=http://aws:4566 s3 sync s3://${aws_s3_bucket.wordpress_bucket.id} s3://${aws_s3_bucket.sync_bucket.id}"
  }

  depends_on = [
    aws_s3_bucket.wordpress_bucket,
    aws_s3_bucket.sync_bucket
  ]
}
```

### 4. Define Outputs (`outputs.tf`)
<a name="4-define-outputs"></a>
Configure the required output values.

**Command:**
```bash
vi outputs.tf
```

**Content:**
```hcl
output "new_kke_bucket_name" {
  value = aws_s3_bucket.sync_bucket.bucket
}

output "new_kke_bucket_acl" {
  value = aws_s3_bucket_acl.sync_bucket_acl.acl
}
```

### 5. Execution and Validation
<a name="5-execution-and-validation"></a>
Deploy the configuration.

1.  **Initialize:** `terraform init`
2.  **Plan:** `terraform plan` (Verify resources to add).
3.  **Apply:** `terraform apply -auto-approve`
4.  **Final Check:** Run `terraform plan` again. It must return: **"No changes. Your infrastructure matches the configuration."**

---

## Deep Dive: S3 Data Migration in IaC
<a name="deep-dive-s3-migration"></a>

### Why use `null_resource`?
Terraform is designed for managing the **state** of resources (buckets, ACLs, policies), not necessarily the **content** (files/objects) inside them. To perform a one-time data sync during infrastructure provisioning, we use the `null_resource`.

### The `local-exec` Provisioner
The `local-exec` provisioner invokes a local executable (in this case, the `aws` CLI) after the resource is created. 
* **The Command:** `aws s3 sync` is highly efficient as it only copies new or updated files.
* **The Endpoint:** In this lab environment, we specify `--endpoint-url=http://aws:4566` to ensure the CLI talks to the simulated LocalStack environment rather than the public AWS cloud.

### Verification
You can verify the sync was successful by running the following command in your terminal:
```bash
aws --endpoint-url=http://aws:4566 s3 ls s3://nautilus-sync-28584
```
Both buckets should return the same list of files.
   
