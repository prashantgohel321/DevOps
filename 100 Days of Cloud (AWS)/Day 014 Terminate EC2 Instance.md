# Cloud (AWS) Day 14: Terminate EC2 Instance

This document outlines the solution for the fourteenth task in the AWS migration strategy: cleaning up obsolete resources by terminating an EC2 instance.

As migration progresses, certain temporary or legacy resources become redundant. Terminating them is essential to maintain a clean infrastructure state and avoid unnecessary AWS charges.

---

## Task Requirements
* **Resource:** EC2 Instance
* **Instance Name:** `datacenter-ec2`
* **Action:** Terminate the instance.
* **Condition:** Ensure the instance is in the `terminated` state.
* **Region:** `us-east-1` (N. Virginia)

---

## Method 1: Using the AWS Management Console (UI)

This method provides a visual confirmation of the termination process.

### Step 1: Login & Navigate
1.  Open the **Console URL** provided in your credentials.
2.  Log in with the **Username** and **Password**.
3.  Ensure you are in the **N. Virginia (us-east-1)** region (check the top-right corner).
4.  In the search bar, type `EC2` and select **EC2** under Services.

### Step 2: Locate the Instance
1.  Click on **Instances** in the left-hand navigation pane to view all instances.
2.  Locate the instance named `datacenter-ec2`.
3.  Select the checkbox next to the instance name.

### Step 3: Terminate the Instance
1.  Click the **Instance state** dropdown menu located at the top right of the instance list.
2.  Select **Terminate instance**.
3.  A warning pop-up will appear advising that on an EBS-backed instance, the default action is for the root EBS volume to be deleted.
4.  Click the orange **Terminate** button to confirm.

### Step 4: Verification
1.  Watch the **Instance state** column. It will transition from `Shutting-down` to `Terminated`.
2.  Wait until the state explicitly says **Terminated** before considering the task complete.

---

## Method 2: Using the AWS CLI

This method executes the termination programmatically via the terminal on the `aws-client` host.

### Step 1: Get the Instance ID
First, dynamically fetch the instance ID based on its Name tag.

```bash
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=datacenter-ec2" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region us-east-1)

echo "Target Instance ID is: $INSTANCE_ID"
```

### Step 2: Terminate the Instance
Trigger the termination command using the retrieved Instance ID.

```bash
echo "Terminating the instance..."
aws ec2 terminate-instances \
    --instance-ids $INSTANCE_ID \
    --region us-east-1
```

### Step 3: Wait for Termination to Complete
To ensure the instance has fully reached the `terminated` state before submitting the task, use the `wait` command.

```bash
echo "Waiting for instance to reach 'terminated' state..."
aws ec2 wait instance-terminated \
    --instance-ids $INSTANCE_ID \
    --region us-east-1
echo "Instance successfully terminated."
```

### Step 4: Verification (Optional)
To quickly confirm the final state of the instance:

```bash
aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].[InstanceId, State.Name]" \
    --output table \
    --region us-east-1
```
* **Expected Output:** The state should read `terminated`.

---

## Deep Dive: Termination vs. Stopping

### Stopping an Instance
* **Data:** The data on your attached EBS volumes is preserved.
* **Billing:** You are not charged for instance usage while it's stopped, but you **are** still charged for the EBS volumes attached to it, as well as any Elastic IPs.
* **State:** Can be started again at any time.

### Terminating an Instance
* **Data:** By default, the root EBS volume is deleted (because the `DeleteOnTermination` attribute is set to true). Other attached EBS volumes might be preserved depending on their settings.
* **Billing:** You stop paying for the instance entirely.
* **State:** **Irreversible**. You cannot restart a terminated instance. It will remain visible in the AWS console for a short period (typically 1-2 hours) with the `terminated` status before completely disappearing.
  
