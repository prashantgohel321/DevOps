# Cloud (AWS) Day 11: Attach Elastic Network Interface (ENI)

This document outlines the solution for the eleventh task in the AWS migration strategy: attaching an **Elastic Network Interface (ENI)** to an existing EC2 instance.

Attaching a secondary ENI allows an instance to communicate on two different subnets or provides a dedicated interface for management, monitoring, or backup traffic.

---

## Task Requirements
* **Resource:** Elastic Network Interface (ENI) Attachment
* **Instance Name:** `xfusion-ec2`
* **ENI Name:** `xfusion-eni`
* **Region:** `us-east-1` (N. Virginia)
* **Pre-requisite:** Ensure instance initialization is complete.
* **Goal:** Status must be `attached`.

---

## Method 1: Using the AWS Management Console (UI)

### Step 1: Login & Verify Instance Readiness
1.  Open the **Console URL** provided in your credentials.
2.  Log in with the **Username** (`kk_labs_user_471123`) and **Password** (`Zl6lv!mH!o5R`).
3.  Navigate to **EC2** -> **Instances**.
4.  Locate `xfusion-ec2`. Ensure the **Status check** says `2/2 checks passed`.

### Step 2: Locate the Network Interface
1.  In the left-hand navigation pane, scroll down to the **Network & Security** section.
2.  Click **Network Interfaces**.
3.  Locate the ENI named `xfusion-eni`.

### Step 3: Attach the Interface
1.  Select the checkbox next to `xfusion-eni`.
2.  Click the **Actions** dropdown menu.
3.  Select **Attach**.
4.  In the **Instance** search box, select the `xfusion-ec2` instance.
5.  Click **Attach**.

### Step 4: Verification
1.  Refresh the page.
2.  Check the **Status** column for `xfusion-eni`. It should now say **In-use**.
3.  Check the **Attachment status** column; it should confirm the interface is attached to the instance ID.

---

## Method 2: Using the AWS CLI

This method can be performed directly from the `aws-client` host.

### Step 1: Wait for Instance Initialization
Before attaching hardware components, ensure the instance is fully initialized.

```bash
# Get Instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=xfusion-ec2" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region us-east-1)

echo "Waiting for $INSTANCE_ID to initialize..."
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID --region us-east-1
echo "Instance is ready."
```

### Step 2: Get the Network Interface ID
```bash
ENI_ID=$(aws ec2 describe-network-interfaces \
    --filters "Name=tag:Name,Values=xfusion-eni" \
    --query "NetworkInterfaces[0].NetworkInterfaceId" \
    --output text \
    --region us-east-1)

echo "ENI ID is: $ENI_ID"
```

### Step 3: Attach the ENI
Use the `attach-network-interface` command. We assign it to **Device Index 1** (Index 0 is the primary interface).

```bash
aws ec2 attach-network-interface \
    --network-interface-id $ENI_ID \
    --instance-id $INSTANCE_ID \
    --device-index 1 \
    --region us-east-1
```

### Step 4: Verification
Check the status of the ENI to confirm it is "attached".

```bash
aws ec2 describe-network-interfaces \
    --network-interface-ids $ENI_ID \
    --query "NetworkInterfaces[0].Status" \
    --output text \
    --region us-east-1
```
* **Expected Output:** `in-use` (which indicates it is attached).

---

## Deep Dive: Multi-Homed Instances

### What is an ENI?
An Elastic Network Interface is a logical networking component in a VPC that represents a virtual network card. It includes a primary private IPv4 address, one or more secondary private IPv4 addresses, a MAC address, and security group memberships.

### Why use a Secondary ENI?
1.  **Network Isolation:** You can connect an instance to two different subnets (e.g., a management subnet and a data subnet).
2.  **Low-Budget High Availability:** You can detach an ENI from a failing instance and attach it to a standby instance, moving the IP address and network configuration with it.
3.  **Management and Monitoring:** Use a secondary interface for monitoring tools or backup agents to keep that traffic separate from application traffic.

### Important Constraint
A secondary ENI must be in the **same Availability Zone** as the EC2 instance it is being attached to. You cannot attach an ENI from `us-east-1a` to an instance in `us-east-1b`.
 
