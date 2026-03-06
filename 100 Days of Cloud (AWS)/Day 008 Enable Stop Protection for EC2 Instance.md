# Cloud (AWS) Day 08: Enable Stop Protection for EC2 Instance

This document outlines the solution for the eighth task in the AWS migration strategy: enabling **Stop Protection** for an existing EC2 instance named `datacenter-ec2`.

Stop Protection prevents an EC2 instance from being stopped using the AWS Management Console, CLI, or SDKs, reducing the risk of accidental downtime.

---

## Task Requirements
* **Resource:** EC2 Instance
* **Instance Name:** `datacenter-ec2`
* **Action:** Enable Stop Protection
* **Region:** `us-east-1` (N. Virginia)

---

## Method 1: Using the AWS Management Console (UI)

### Step 1: Login & Navigate
1.  Open the **Console URL** provided in your credentials.
2.  Log in with the **Username** (`kk_labs_user_264877`) and **Password** (`US95cslC8lGS`).
3.  Ensure you are in the **N. Virginia (us-east-1)** region.
4.  In the search bar, type `EC2` and select **EC2** under Services.

### Step 2: Locate the Instance
1.  Click on **Instances** (running) in the dashboard.
2.  Locate the instance named `datacenter-ec2`.
3.  Select the checkbox next to the instance name.

### Step 3: Enable Stop Protection
1.  Click the **Actions** dropdown menu.
2.  Select **Instance settings**.
3.  Click **Change stop protection**.
4.  Select the **Enable** checkbox.
5.  Click **Save**.

---

## Method 2: Using the AWS CLI

This method allows you to enable protection directly from the `aws-client` host terminal.

### Step 1: Get the Instance ID
First, retrieve the ID of the instance named `datacenter-ec2`.

```bash
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=datacenter-ec2" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region us-east-1)

echo "Target Instance ID: $INSTANCE_ID"
```

### Step 2: Modify the Attribute
The attribute that controls Stop Protection is called `disableApiStop`.

```bash
aws ec2 modify-instance-attribute \
    --instance-id $INSTANCE_ID \
    --disable-api-stop "Value=true" \
    --region us-east-1
```

### Step 3: Verification
To confirm that Stop Protection is now enabled:

```bash
aws ec2 describe-instance-attribute \
    --instance-id $INSTANCE_ID \
    --attribute disableApiStop \
    --region us-east-1
```

**Expected Output:**
```json
{
    "InstanceId": "i-xxxxxxxxxxxxxxxxx",
    "DisableApiStop": {
        "Value": true
    }
}
```

---

## Deep Dive: Stop Protection vs. Termination Protection

* **Stop Protection (`disableApiStop`):** Prevents the instance from being transitioned to the `stopped` state. This is useful for preventing accidental reboots or shutdowns on mission-critical servers.
* **Termination Protection (`disableApiTermination`):** Prevents the instance from being permanently deleted. When enabled, the `Terminate` action will fail until the attribute is disabled.

Both features are vital components of a "Defense in Depth" strategy to protect cloud infrastructure from administrative errors.
  
