# Cloud (AWS) Day 10: Attach Elastic IP to EC2 Instance

This document outlines the solution for the tenth task in the AWS migration strategy: associating an **Elastic IP (EIP)** with an existing EC2 instance.

By attaching an Elastic IP, you provide the `datacenter-ec2` instance with a static, public IPv4 address that does not change even if the instance is stopped and restarted.

---

## Task Requirements
* **Resource:** Elastic IP Association
* **Instance Name:** `datacenter-ec2`
* **Elastic IP Name:** `datacenter-ec2-eip`
* **Region:** `us-east-1` (N. Virginia)

---

## Method 1: Using the AWS Management Console (UI)

### Step 1: Login & Navigate
1.  Open the **Console URL** provided in your credentials.
2.  Log in with the **Username** (`kk_labs_user_204948`) and **Password** (`a^t7mYmt^3jD`).
3.  Ensure you are in the **N. Virginia (us-east-1)** region.
4.  In the search bar, type `EC2` and select **EC2** under Services.

### Step 2: Locate the Elastic IP
1.  In the left-hand navigation pane, scroll down to the **Network & Security** section.
2.  Click **Elastic IPs**.
3.  Locate the Elastic IP tagged with the name `datacenter-ec2-eip`.

### Step 3: Associate the Address
1.  Select the checkbox next to the `datacenter-ec2-eip` entry.
2.  Click the **Actions** dropdown menu at the top right.
3.  Select **Associate Elastic IP address**.
4.  **Resource type:** Ensure **Instance** is selected.
5.  **Instance:** Click in the search box and select the instance named `datacenter-ec2`.
6.  Click **Associate**.

---

## Method 2: Using the AWS CLI

This method can be performed directly from the `aws-client` host terminal.

### Step 1: Get the Instance ID
Retrieve the ID for the instance named `datacenter-ec2`.

```bash
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=datacenter-ec2" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region us-east-1)

echo "Target Instance ID: $INSTANCE_ID"
```

### Step 2: Get the Allocation ID
Retrieve the Allocation ID for the Elastic IP named `datacenter-ec2-eip`. Note that CLI operations for EIPs usually require the **AllocationId**, not the public IP itself.

```bash
ALLOC_ID=$(aws ec2 describe-addresses \
    --filters "Name=tag:Name,Values=datacenter-ec2-eip" \
    --query "Addresses[0].AllocationId" \
    --output text \
    --region us-east-1)

echo "EIP Allocation ID: $ALLOC_ID"
```

### Step 3: Associate the Elastic IP
Run the association command to link the two resources.

```bash
aws ec2 associate-address \
    --instance-id $INSTANCE_ID \
    --allocation-id $ALLOC_ID \
    --region us-east-1
```

### Step 4: Verification
Confirm that the instance now has the Elastic IP assigned as its public IP address.

```bash
aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --output text \
    --region us-east-1
```

---

## Deep Dive: Elastic IP Persistence

### Dynamic vs. Static IPs
By default, when you launch an EC2 instance, it receives a **Public IP** from the AWS pool. This IP is dynamic. If you stop the instance (to save costs or change the instance type) and start it again, AWS will likely assign it a *different* public IP. This breaks DNS records and external application connections.

### The Elastic IP Solution
An **Elastic IP** is associated with your AWS account, not the hardware. 
* It remains static. 
* You can re-associate it with a different instance if the original one fails (useful for basic failover).
* **Cost Note:** Elastic IPs are free while associated with a running instance. AWS charges a small hourly fee for Elastic IPs that are allocated but *not* attached to a resource, to prevent "IP squatting."
 
