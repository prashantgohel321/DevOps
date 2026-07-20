# Cloud (AWS) Day 07: Change EC2 Instance Type

This document outlines the solution for the seventh task in the AWS migration strategy: resizing an existing EC2 instance to optimize cost and resource utilization.

We will cover two methods to achieve this:
1.  **AWS Management Console (UI)** 2.  **AWS Command Line Interface (CLI)**

---

## Task Requirements
* **Target Instance:** `xfusion-ec2`
* **Current Type:** `t2.micro`
* **New Type:** `t2.nano`
* **Region:** `us-east-1` (N. Virginia)
* **Conditions:** * Wait for status checks to complete before making changes.
    * Ensure the instance is in the `Running` state after the change is complete.

---

## The Golden Rule of Resizing EC2 Instances
**You cannot change an instance type while the instance is running.** The instance must be transitioned to the `Stopped` state first. This is because AWS needs to migrate your virtual machine to different underlying physical hardware that supports the new instance type specifications.

---

## Method 1: Using the AWS Management Console (UI)

### Step 1: Login & Navigate
1.  Open the **Console URL** provided in your credentials.
2.  Log in with the **Username** and **Password**.
3.  Ensure you are in the **N. Virginia (us-east-1)** region.
4.  In the search bar, type `EC2` and select **EC2** under Services.
5.  Click on **Instances (running)** in the main dashboard.

### Step 2: Verify Status Checks
1.  Locate the instance named `xfusion-ec2`.
2.  Look at the **Status check** column. 
3.  If it says `Initializing`, **wait** until it displays `2/2 checks passed`.

### Step 3: Stop the Instance
1.  Select the checkbox next to `xfusion-ec2`.
2.  Click the **Instance state** dropdown menu at the top right.
3.  Select **Stop instance**, and confirm by clicking **Stop** in the pop-up modal.
4.  Wait for the "Instance state" column to change from `Stopping` to `Stopped`.

### Step 4: Change Instance Type
1.  Ensure `xfusion-ec2` is still selected.
2.  Click the **Actions** dropdown menu.
3.  Navigate to **Instance settings** -> **Change instance type**.
4.  In the "Instance type" dropdown, search for and select **t2.nano**.
5.  Click **Apply**.

### Step 5: Start the Instance
1.  With `xfusion-ec2` selected, click the **Instance state** dropdown menu.
2.  Select **Start instance**.
3.  Wait a few moments until the state says `Running`. The task is now complete.

---

## Method 2: Using the AWS CLI

This method executes the entire workflow via the terminal on the `aws-client` host.

### Step 1: Get the Instance ID
First, dynamically fetch the instance ID based on the tag name.

```bash
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=xfusion-ec2" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region us-east-1)

echo "Instance ID is: $INSTANCE_ID"
```

### Step 2: Wait for Status Checks to Complete
Ensure the instance has fully initialized before disrupting it. The `wait` command will pause the terminal until the condition is met.

```bash
echo "Waiting for status checks to complete..."
aws ec2 wait instance-status-ok \
    --instance-ids $INSTANCE_ID \
    --region us-east-1
echo "Status checks passed."
```

### Step 3: Stop the Instance
Trigger the stop command and wait for the state transition to finish.

```bash
echo "Stopping the instance..."
aws ec2 stop-instances \
    --instance-ids $INSTANCE_ID \
    --region us-east-1

aws ec2 wait instance-stopped \
    --instance-ids $INSTANCE_ID \
    --region us-east-1
echo "Instance stopped."
```

### Step 4: Modify the Instance Type
Now that it is stopped, modify the attribute.

```bash
echo "Changing instance type to t2.nano..."
aws ec2 modify-instance-attribute \
    --instance-id $INSTANCE_ID \
    --instance-type "{\"Value\": \"t2.nano\"}" \
    --region us-east-1
```

### Step 5: Start the Instance
Turn the instance back on and wait for it to be fully running.

```bash
echo "Starting the instance..."
aws ec2 start-instances \
    --instance-ids $INSTANCE_ID \
    --region us-east-1

aws ec2 wait instance-running \
    --instance-ids $INSTANCE_ID \
    --region us-east-1
echo "Instance is now running with the new type."
```

### Step 6: Verification
To quickly confirm the new instance type and state:

```bash
aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].[InstanceId, InstanceType, State.Name]" \
    --output table \
    --region us-east-1
```
    
