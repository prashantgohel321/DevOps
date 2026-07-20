# Cloud (AWS) Day 04: Enable Versioning for S3 Bucket

This document describes the fourth step in the AWS migration workflow: enabling **S3 bucket versioning** for controlled data protection. Versioning ensures that objects stored in a bucket are not permanently lost when overwritten or deleted. Instead of replacing or removing data directly, S3 keeps historical versions, allowing rollback and recovery.

---

<br>
<br>

- [Cloud (AWS) Day 04: Enable Versioning for S3 Bucket](#cloud-aws-day-04-enable-versioning-for-s3-bucket)
  - [Objective](#objective)
  - [Why Versioning Matters](#why-versioning-matters)
- [Method 1: Using AWS Management Console (UI)](#method-1-using-aws-management-console-ui)
  - [Step 1: Login and Select Region](#step-1-login-and-select-region)
  - [Step 2: Open Target Bucket](#step-2-open-target-bucket)
  - [Step 3: Enable Versioning](#step-3-enable-versioning)
  - [Step 4: Confirmation](#step-4-confirmation)
- [Method 2: Using AWS CLI](#method-2-using-aws-cli)
  - [Step 1: Enable Versioning](#step-1-enable-versioning)
    - [What This Command Does](#what-this-command-does)
  - [Step 2: Verify Versioning Status](#step-2-verify-versioning-status)
    - [Expected Output](#expected-output)
- [Internal Behavior After Enabling Versioning](#internal-behavior-after-enabling-versioning)
- [Key Outcome](#key-outcome)


<br>
<br>

## Objective

Enable versioning on the S3 bucket:

* **Bucket Name:** `devops-s3-4951`
* **Region:** `us-east-1` (N. Virginia)
* **Action:** Enable Versioning

---

<br>
<br>

## Why Versioning Matters

By default, when you upload a file with the same name as an existing file in S3, the older file is replaced. If you delete a file, it is permanently removed.

When versioning is enabled:

* Every uploaded object receives a unique **Version ID**.
* Uploading the same file name creates a new version instead of replacing the old one.
* Deleting an object inserts a **delete marker** instead of removing data permanently.
* Previous versions remain stored and can be restored.

This mechanism protects against:

* Accidental overwrites
* Accidental deletions
* Application deployment mistakes
* Data corruption scenarios

Versioning transforms S3 from simple storage into a recoverable storage system.

---

<br>
<br>

# Method 1: Using AWS Management Console (UI)

This method allows direct visibility into bucket configuration.

## Step 1: Login and Select Region

1. Log in to the AWS Management Console.
2. Confirm the region is set to **N. Virginia (us-east-1)**.
3. Search for **S3** in the Services search bar.

## Step 2: Open Target Bucket

1. Locate the bucket named `devops-s3-4951`.
2. Click the bucket name to open its dashboard.

## Step 3: Enable Versioning

1. Open the **Properties** tab.
2. Locate the **Bucket Versioning** section.
3. Click **Edit**.
4. Select **Enable**.
5. Click **Save changes**.

## Step 4: Confirmation

* A success message confirms the update.
* Versioning status changes from **Disabled** to **Enabled**.

At this point, all future uploads will receive unique Version IDs.

---

<br>
<br>

# Method 2: Using AWS CLI

This method is preferred for automation and scripting.

## Step 1: Enable Versioning

Run the following command:

```bash
aws s3api put-bucket-versioning \
    --bucket devops-s3-4951 \
    --versioning-configuration Status=Enabled \
    --region us-east-1
```

### What This Command Does

* `s3api` interacts directly with low-level S3 APIs.
* `put-bucket-versioning` updates versioning configuration.
* `--bucket` specifies the target bucket.
* `--versioning-configuration Status=Enabled` activates version tracking.
* `--region` ensures the request targets the correct AWS region.

The command produces no output if successful.

---

<br>
<br>

## Step 2: Verify Versioning Status

```bash
aws s3api get-bucket-versioning --bucket devops-s3-4951 --region us-east-1
```

### Expected Output

```json
{
    "Status": "Enabled"
}
```

If versioning has never been configured, the command may return empty output. If disabled after being enabled previously, the status may appear as `Suspended`.

---

<br>
<br>

# Internal Behavior After Enabling Versioning

Once enabled:

* Each object upload generates a unique Version ID.
* Deleting an object does not remove previous versions.
* A delete marker hides the latest version from normal listing.
* Storage costs increase because all versions are retained.

To fully remove an object, all version IDs must be explicitly deleted.

Example: Listing object versions

```bash
aws s3api list-object-versions --bucket devops-s3-4951 --region us-east-1
```

This command shows all versions and delete markers.

---

<br>
<br>

# Key Outcome

The S3 bucket `devops-s3-4951` in `us-east-1` now has versioning enabled. The bucket can store and manage multiple object versions, allowing controlled recovery of overwritten or deleted data. This prepares the storage layer for safe production deployment and controlled rollback capabilities.
