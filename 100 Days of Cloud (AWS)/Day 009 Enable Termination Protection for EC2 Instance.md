# Cloud (AWS) Day 09: Enable Termination Protection for EC2 Instance

This document outlines the solution for the ninth task in the AWS migration strategy: enabling **Termination Protection** for an existing EC2 instance named `datacenter-ec2`.

Termination Protection is a safety feature that prevents an EC2 instance from being accidentally deleted (terminated). When enabled, any attempt to terminate the instance through the AWS Management Console, CLI, or API will fail until the protection is explicitly disabled.

---

## Task Requirements
* **Resource:** EC2 Instance
* **Instance Name:** `datacenter-ec2`
* **Action:** Enable Termination Protection
* **Region:** `us-east-1` (N. Virginia)

---

## Method 1: Using the AWS Management Console (UI)

### Step 1: Login & Navigate
1.  Open the **Console URL** provided in your credentials.
2.  Log in with the **Username** (`kk_labs_user_412261`) and **Password** (`Hb@VKmy0Nprf`).
3.  Ensure you are in the **N. Virginia (us-east-1)** region.
4.  In the search bar, type `EC2` and select **EC2** under Services.

### Step 2: Locate the Instance
1.  Click on **Instances** (running) in the dashboard.
2.  Locate the instance named `datacenter-ec2`.
3.  Select the checkbox next to the instance name.

### Step 3: Enable Termination Protection
1.  Click the **Actions** dropdown menu at the top.
2.  Select **Instance settings**.
3.  Click **Change termination protection**.
4.  Select the **Enable** checkbox.
5.  Click **Save**.

---

## Method 2: Using the AWS CLI

This method is used on the `aws-client` host for faster execution and scripting.

### Step 1: Get the Instance ID
Retrieve the ID for the instance tagged with the name `datacenter-ec2`.

```bash
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=datacenter-ec2" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region us-east-1)

echo "Target Instance ID: $INSTANCE_ID"
```

### Step 2: Modify the Attribute
The attribute governing Termination Protection is `disableApiTermination`.

```bash
aws ec2 modify-instance-attribute \
    --instance-id $INSTANCE_ID \
    --disable-api-termination "Value=true" \
    --region us-east-1
```

### Step 3: Verification
Confirm that the attribute has been set to `true`.

```bash
aws ec2 describe-instance-attribute \
    --instance-id $INSTANCE_ID \
    --attribute disableApiTermination \
    --region us-east-1
```

**Expected Output:**
```json
{
    "InstanceId": "i-xxxxxxxxxxxxxxxxx",
    "DisableApiTermination": {
        "Value": true
    }
}
```

---

## Deep Dive: Operational Guardrails

### Why use Termination Protection?
In cloud infrastructure, accidental deletion is a significant risk. For stateful servers (like databases or primary application servers), enabling termination protection ensures that an administrator must perform a deliberate, two-step process to delete the instance:
1.  Disable the protection attribute.
2.  Terminate the instance.

### Interaction with Auto Scaling
Note that Termination Protection **does not** prevent Amazon EC2 Auto Scaling from terminating an instance if the instance is part of an Auto Scaling group and the group needs to scale down or mark the instance as unhealthy. This protection is specifically against API-driven termination commands.

### Difference from Stop Protection
* **Stop Protection:** Prevents the instance from being *stopped* (Shut down).
* **Termination Protection:** Prevents the instance from being *terminated* (Deleted).
   
