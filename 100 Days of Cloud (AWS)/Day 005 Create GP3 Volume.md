# Cloud (AWS) Day 05: Create GP3 Volume

This document explains how to create a standalone Amazon EBS (Elastic Block Store) volume using the GP3 volume type. The volume behaves like a virtual hard disk that can later be attached to an EC2 instance for persistent storage.

---

<br>
<br>

- [Cloud (AWS) Day 05: Create GP3 Volume](#cloud-aws-day-05-create-gp3-volume)
  - [Objective](#objective)
- [Understanding the Concept](#understanding-the-concept)
- [Method 1: Using AWS Management Console](#method-1-using-aws-management-console)
  - [Step 1: Access EC2 Service](#step-1-access-ec2-service)
  - [Step 2: Navigate to Volumes](#step-2-navigate-to-volumes)
  - [Step 3: Configure Volume Settings](#step-3-configure-volume-settings)
  - [Step 4: Add Name Tag](#step-4-add-name-tag)
  - [Step 5: Create Volume](#step-5-create-volume)
- [Method 2: Using AWS CLI](#method-2-using-aws-cli)
  - [Step 1: Create Volume](#step-1-create-volume)
    - [Command Explanation](#command-explanation)
  - [Step 2: Verify Volume](#step-2-verify-volume)
- [Internal Lifecycle of an EBS Volume](#internal-lifecycle-of-an-ebs-volume)
- [Key Outcome](#key-outcome)


<br>
<br>

## Objective

Provision an EBS volume with the following configuration:

* **Name Tag:** `devops-volume`
* **Volume Type:** `gp3`
* **Size:** `2 GiB`
* **Region:** `us-east-1` (N. Virginia)

---

<br>
<br>

# Understanding the Concept

An EBS volume provides block-level storage. Unlike S3 (which is object storage), EBS works like a disk attached to a virtual machine.

Key characteristics:

* It exists inside a specific Availability Zone (AZ).
* It must be attached to an EC2 instance in the same AZ.
* Data persists independently of instance lifecycle.

The `gp3` volume type is a general-purpose SSD option. It allows baseline performance (3000 IOPS and 125 MiB/s throughput) without tying performance strictly to storage size.

---

<br>
<br>

# Method 1: Using AWS Management Console

## Step 1: Access EC2 Service

1. Log in to the AWS Management Console.
2. Ensure region is set to **us-east-1 (N. Virginia)**.
3. Navigate to **EC2** service.

---

<br>
<br>

## Step 2: Navigate to Volumes

1. In the left menu under **Elastic Block Store**, select **Volumes**.
2. Click **Create volume**.

---

<br>
<br>

## Step 3: Configure Volume Settings

* **Volume Type:** General Purpose SSD (gp3)
* **Size:** 2 GiB
* **IOPS:** Leave default (3000)
* **Throughput:** Leave default (125)
* **Availability Zone:** Select one (e.g., us-east-1a)

The Availability Zone selection is mandatory. The volume physically resides inside that AZ.

---

<br>
<br>

## Step 4: Add Name Tag

Under the **Tags** section:

* Key → `Name`
* Value → `devops-volume`

Tagging ensures easier identification and management.

---

<br>
<br>

## Step 5: Create Volume

Click **Create volume**.

After creation:

* State should show: `Available`
* Volume is ready to be attached to an EC2 instance

---

<br>
<br>

# Method 2: Using AWS CLI

## Step 1: Create Volume

```bash
aws ec2 create-volume \
    --volume-type gp3 \
    --size 2 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=devops-volume}]' \
    --region us-east-1

# OUTPUT

{
    "Iops": 3000,
    "Tags": [
        {
            "Key": "Name",
            "Value": "devops-volume"
        }
    ],
    "VolumeType": "gp3",
    "MultiAttachEnabled": false,
    "Throughput": 125,
    "VolumeId": "vol-060f74f55a4d65caa",
    "Size": 2,
    "SnapshotId": "",
    "AvailabilityZone": "us-east-1a",
    "State": "creating",
    "CreateTime": "2026-02-17T00:35:11.000Z",
    "Encrypted": false
}

```

<br>
<br>

### Command Explanation

* `create-volume` → API action to create EBS volume
* `--volume-type gp3` → Selects performance tier
* `--size 2` → Sets capacity in GiB
* `--availability-zone us-east-1a` → Specifies physical placement
* `--tag-specifications` → Adds Name tag at creation
* `--region us-east-1` → Targets correct AWS region

If successful, AWS returns a JSON response containing:

* VolumeId
* Size
* State
* VolumeType

---

<br>
<br>

## Step 2: Verify Volume

```bash
aws ec2 describe-volumes \
    --filters Name=tag:Name,Values=devops-volume \
    --region us-east-1

# OUTPUT

{
    "Volumes": [
        {
            "Iops": 3000,
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "devops-volume"
                }
            ],
            "VolumeType": "gp3",
            "MultiAttachEnabled": false,
            "Throughput": 125,
            "Operator": {
                "Managed": false
            },
            "VolumeId": "vol-060f74f55a4d65caa",
            "Size": 2,
            "SnapshotId": "",
            "AvailabilityZone": "us-east-1a",
            "State": "available",
            "CreateTime": "2026-02-17T00:35:11.897Z",
            "Attachments": [],
            "Encrypted": false
        }
    ]
}

```

Expected output should include:

* `"State": "available"`
* `"Size": 2`
* `"VolumeType": "gp3"`

---

<br>
<br>

# Internal Lifecycle of an EBS Volume

1. Volume is created inside a specific AZ.
2. State becomes `available`.
3. It can be attached to a running EC2 instance.
4. Once attached, it appears as a block device (e.g., `/dev/xvdf`).
5. The instance must format and mount the volume before use.

If detached, the volume returns to `available` state but retains data.

---

<br>
<br>

# Key Outcome

A standalone EBS volume named `devops-volume` has been created in `us-east-1` using the `gp3` type with 2 GiB of storage. The volume is now ready to be attached to an EC2 instance for persistent storage use.
