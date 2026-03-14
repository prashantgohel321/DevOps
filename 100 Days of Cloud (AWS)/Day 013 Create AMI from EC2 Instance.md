# Cloud (AWS) Day 13: Create AMI from EC2 Instance

This document explains the solution for the thirteenth task in the AWS migration journey: creating an **Amazon Machine Image (AMI)** from an existing EC2 instance.

During cloud migrations or infrastructure scaling, teams often need to create identical copies of servers. Instead of configuring a new server from the beginning every time, AWS allows capturing the complete state of an EC2 instance as an image. This image can later be used to launch multiple identical instances with the same operating system, installed packages, configuration files, and application setup.

In this task, an AMI must be created from the EC2 instance named **datacenter-ec2**.

---

# Task Requirements

* **Resource:** Amazon Machine Image (AMI)
* **Source Instance Name:** `datacenter-ec2`
* **AMI Name:** `datacenter-ec2-ami`
* **Region:** `us-east-1` (N. Virginia)
* **Expected State:** `available`

---

# Understanding the Concept

An **AMI (Amazon Machine Image)** is essentially a template used to launch EC2 instances.

It contains three important things:

1. **Operating system image** – the base system such as Amazon Linux, Ubuntu, or Red Hat.
2. **Application configuration** – any software installed inside the instance (web servers, databases, tools, etc.).
3. **Block device mapping** – the storage layout, which tells AWS what EBS volumes should be attached when a new instance launches.

When an AMI is created, AWS takes **snapshots of the EBS volumes** attached to the instance. A **snapshot** is a point‑in‑time backup of a storage volume. These snapshots are then used to generate the AMI.

Once the AMI creation process finishes, the AMI state becomes **available**, which means it is ready to launch new EC2 instances.

---

# Method 1: Using AWS Management Console (Web Interface)

This method uses the AWS graphical interface, which is commonly used when performing infrastructure tasks manually.

## Step 1: Login to AWS Console

1. Open the **Console URL** provided in the credentials.
2. Enter the following login details.

```
Username: kk_labs_user_701086
Password: IsklM@h23%ZU
```

3. After logging in, make sure the selected region is:

```
us-east-1 (N. Virginia)
```

A **region** is a physical geographic location where AWS maintains data centers. Resources such as EC2 instances, AMIs, and volumes exist inside a region, so the correct region must always be selected.

---

## Step 2: Navigate to EC2 Service

1. In the AWS search bar, type **EC2**.
2. Select **EC2** from the services list.

The EC2 service is responsible for running virtual servers in AWS.

---

## Step 3: Locate the Instance

1. In the left navigation panel, click **Instances**.
2. Find the instance named:

```
datacenter-ec2
```

3. Select the checkbox next to this instance.

---

## Step 4: Create Image (AMI)

1. Click the **Actions** dropdown menu.
2. Navigate to:

```
Image and templates → Create image
```

3. Fill in the details:

```
Image name: datacenter-ec2-ami
```

4. Leave other settings as default.

5. Click **Create image**.

When this action is performed, AWS begins creating **snapshots of the instance's EBS volumes**, which are then used to build the AMI.

---

## Step 5: Verify AMI Creation

1. In the left navigation panel, go to:

```
Images → AMIs
```

2. Locate the AMI named:

```
datacenter-ec2-ami
```

3. Wait until the **State** becomes:

```
available
```

The **available** state indicates that the AMI has been successfully created and can now be used to launch new EC2 instances.

---

# Method 2: Using AWS CLI

This method performs the same task using command line tools from the **aws-client host**.

The **AWS CLI (Command Line Interface)** is a tool that allows interacting with AWS services directly from the terminal. It is widely used in DevOps workflows, automation scripts, and CI/CD pipelines.

---

# Step 1: Retrieve Instance ID

AWS CLI commands usually require the **Instance ID** instead of the instance name.

The following command retrieves the ID of the instance tagged with the name `datacenter-ec2`.

```bash
INSTANCE_ID=$(aws ec2 describe-instances \
--filters "Name=tag:Name,Values=datacenter-ec2" \
--query "Reservations[*].Instances[*].InstanceId" \
--output text \
--region us-east-1)

 echo "Instance ID: $INSTANCE_ID"
```

Explanation of key parts:

* **describe-instances** → fetches information about EC2 instances.
* **filters** → narrows the search to instances whose tag name matches `datacenter-ec2`.
* **query** → extracts only the InstanceId from the returned JSON output.
* **--output text** → prints the value in simple text format.

---

# Step 2: Create the AMI

Now create the AMI from the retrieved instance.

```bash
aws ec2 create-image \
--instance-id $INSTANCE_ID \
--name "datacenter-ec2-ami" \
--region us-east-1
```

Important parameters:

* **create-image** → command used to create an AMI from an EC2 instance.
* **--instance-id** → specifies the source EC2 instance.
* **--name** → name of the AMI being created.

After running the command, AWS returns an **ImageId** (for example `ami-0abcd1234`). This ID uniquely identifies the created AMI.

---

# Step 3: Verify AMI State

To confirm that the AMI has been created successfully, run the following command:

```bash
aws ec2 describe-images \
--owners self \
--filters "Name=name,Values=datacenter-ec2-ami" \
--query "Images[*].State" \
--output text \
--region us-east-1
```

Expected output:

```
available
```

If the state initially appears as **pending**, it means AWS is still creating snapshots. Once snapshot creation completes, the state automatically changes to **available**.

---

# Deep Understanding: What Happens Internally

When an AMI is created from an EC2 instance, AWS performs the following steps internally:

1. AWS identifies all **EBS volumes** attached to the instance.
2. It creates **snapshots** of those volumes.
3. These snapshots are stored in Amazon S3 internally by AWS.
4. AWS builds an **AMI metadata template** that references those snapshots.

Because the AMI references snapshots rather than copying entire disks immediately, the process is efficient and storage optimized.

Whenever a new EC2 instance is launched from this AMI, AWS simply recreates the required EBS volumes from the stored snapshots.

This is the mechanism that makes AMIs extremely useful for:

* Infrastructure replication
* Auto scaling groups
* Backup strategies
* Disaster recovery
* Golden image pipelines used in DevOps environments

---

# Final Verification

The task is considered successful when:

```
AMI Name: datacenter-ec2-ami
State: available
Region: us-east-1
```

Once the AMI reaches the **available** state, it can be used to launch new EC2 instances that are exact copies of the original `datacenter-ec2` server.
