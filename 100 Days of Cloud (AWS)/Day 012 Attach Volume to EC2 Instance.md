# Cloud (AWS) Day 12: Attach EBS Volume to EC2 Instance

This document outlines the solution for the twelfth task in the AWS migration strategy: attaching a standalone **Elastic Block Store (EBS) Volume** to an existing EC2 instance.

By attaching this volume, you provide the `devops-ec2` server with additional persistent block storage that can be formatted and mounted as a filesystem.

---

## Task Requirements
* **Resource:** EBS Volume Attachment
* **Instance Name:** `devops-ec2`
* **Volume Name:** `devops-volume`
* **Device Name:** `/dev/sdb`
* **Region:** `us-east-1` (N. Virginia)

---

## Method 1: Using the AWS Management Console (UI)

### Step 1: Login & Navigate
1.  Open the **Console URL** provided in your credentials.
2.  Log in with the **Username** (`kk_labs_user_410600`) and **Password** (`mAkb^%@M2@Nu`).
3.  Ensure you are in the **N. Virginia (us-east-1)** region.
4.  In the search bar, type `EC2` and select **EC2** under Services.

### Step 2: Locate the Volume
1.  In the left-hand navigation pane, scroll down to the **Elastic Block Store** section.
2.  Click **Volumes**.
3.  Locate the volume tagged with the name `devops-volume`.

### Step 3: Attach the Volume
1.  Select the checkbox next to `devops-volume`.
2.  Click the **Actions** dropdown menu at the top right.
3.  Select **Attach volume**.
4.  **Instance:** Click in the search box and select the instance named `devops-ec2`.
5.  **Device name:** Delete the default value and enter `/dev/sdb`.
6.  Click **Attach volume**.

### Step 4: Verification
* Refresh the volume list.
* The **State** should change from `Available` to `In-use`.
* Check the **Attachment information** column; it should display the instance ID and the device name `/dev/sdb`.

---

## Method 2: Using the AWS CLI

This method can be performed directly from the `aws-client` host.

### Step 1: Get the Instance ID
Retrieve the ID for the instance named `devops-ec2`.

```bash
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=devops-ec2" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region us-east-1)

echo "Target Instance ID: $INSTANCE_ID"
```

### Step 2: Get the Volume ID
Retrieve the ID for the volume named `devops-volume`.

```bash
VOLUME_ID=$(aws ec2 describe-volumes \
    --filters "Name=tag:Name,Values=devops-volume" \
    --query "Volumes[0].VolumeId" \
    --output text \
    --region us-east-1)

echo "Target Volume ID: $VOLUME_ID"
```

### Step 3: Attach the Volume
Use the `attach-volume` command with the specific device name requirement.

```bash
aws ec2 attach-volume \
    --volume-id $VOLUME_ID \
    --instance-id $INSTANCE_ID \
    --device /dev/sdb \
    --region us-east-1
```

### Step 4: Verification
Confirm the attachment state.

```bash
aws ec2 describe-volumes \
    --volume-ids $VOLUME_ID \
    --query "Volumes[0].State" \
    --output text \
    --region us-east-1
```
* **Expected Output:** `in-use` (which indicates it is successfully attached).

---

## Deep Dive: EBS Attachment and Device Naming

### Availability Zone Constraint
An EBS volume must be in the **same Availability Zone (AZ)** as the EC2 instance it is being attached to. If your instance is in `us-east-1a` and the volume is in `us-east-1b`, they cannot be connected. AWS migration tasks usually ensure they match, but it is a vital check in production.

### Device Names (/dev/sdb)
* **OS Translation:** While you attach the volume as `/dev/sdb` in the AWS console, modern Linux kernels (using the NVMe driver) might rename this device internally (e.g., to `/dev/nvme1n1`).
* **Persistent Naming:** It is best practice to use UUIDs or labels when configuring `/etc/fstab` inside the OS to ensure the volume mounts correctly even if the device name changes after a reboot.

### Instance State
You can attach an EBS volume while an instance is `running` or `stopped`. However, to use the disk, you must log into the OS, format the partition (if new), and mount it.
 
