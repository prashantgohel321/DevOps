# Cloud (AWS) Day 06: Launch EC2 Instance

This document explains how to launch an EC2 instance in AWS. An EC2 instance represents a virtual server running inside the AWS cloud infrastructure. The instance can be used to host applications, run scripts, or act as a backend server for services.

Two approaches are demonstrated:

1. AWS Management Console (UI)
2. AWS Command Line Interface (CLI)

---

- [Cloud (AWS) Day 06: Launch EC2 Instance](#cloud-aws-day-06-launch-ec2-instance)
  - [Objective](#objective)
- [Understanding the Components](#understanding-the-components)
- [Method 1: Launch Instance Using AWS Console](#method-1-launch-instance-using-aws-console)
  - [Step 1: Access EC2 Service](#step-1-access-ec2-service)
  - [Step 2: Start Launch Wizard](#step-2-start-launch-wizard)
  - [Step 3: Configure Instance Details](#step-3-configure-instance-details)
    - [Name](#name)
    - [AMI Selection](#ami-selection)
    - [Instance Type](#instance-type)
  - [Step 4: Create Key Pair](#step-4-create-key-pair)
  - [Step 5: Configure Networking](#step-5-configure-networking)
  - [Step 6: Launch Instance](#step-6-launch-instance)
- [Method 2: Launch Instance Using AWS CLI](#method-2-launch-instance-using-aws-cli)
  - [Step 1: Create Key Pair](#step-1-create-key-pair)
  - [Step 2: Get Default Security Group ID](#step-2-get-default-security-group-id)
  - [Step 3: Retrieve Latest Amazon Linux AMI](#step-3-retrieve-latest-amazon-linux-ami)
  - [Step 4: Launch the Instance](#step-4-launch-the-instance)
- [Step 5: Verify Instance](#step-5-verify-instance)
- [Key Outcome](#key-outcome)

<br>
<br>

## Objective

Launch an EC2 instance with the following configuration:

* **Instance Name:** `nautilus-ec2`
* **AMI:** Amazon Linux
* **Instance Type:** `t2.micro`
* **Key Pair:** `nautilus-kp`
* **Security Group:** `default`
* **Region:** `us-east-1`

---

<br>
<br>

# Understanding the Components

Before creating the instance, it is important to understand the resources involved.

**EC2 (Elastic Compute Cloud)** provides virtual machines that run on AWS infrastructure. Each instance behaves like a normal server with CPU, memory, networking, and storage.

**AMI (Amazon Machine Image)** is the operating system template used to create the instance. It includes the base OS and sometimes additional packages.

**Instance Type** determines hardware resources. `t2.micro` provides:

* 1 vCPU
* 1 GB RAM

**Key Pair** is used for SSH authentication. AWS stores the public key while the private key remains with the user.

**Security Groups** act as virtual firewalls controlling network traffic to and from the instance.

---

<br>
<br>

# Method 1: Launch Instance Using AWS Console

## Step 1: Access EC2 Service

1. Log in to the AWS Management Console.
2. Ensure the region is set to **us-east-1 (N. Virginia)**.
3. Search for **EC2** in the Services menu.

---

<br>
<br>

## Step 2: Start Launch Wizard

Click **Launch instance** from the EC2 dashboard.

---

<br>
<br>

## Step 3: Configure Instance Details

### Name

Set the instance name:

```
nautilus-ec2
```

### AMI Selection

Choose:

```
Amazon Linux 2 AMI
```

### Instance Type

Select:

```
t2.micro
```

---

<br>
<br>

## Step 4: Create Key Pair

Create a new key pair:

* **Key pair name:** `nautilus-kp`
* **Key type:** RSA
* **Format:** `.pem`

Download the private key and store it securely.

---

<br>
<br>

## Step 5: Configure Networking

Under **Network Settings**:

* Use default VPC
* Use default subnet
* Select existing security group
* Choose `default`

---

<br>
<br>

## Step 6: Launch Instance

Click **Launch Instance**.

After launch:

Navigate to **EC2 → Instances**.

The instance should appear with status:

```
Running
```

---

<br>
<br>

# Method 2: Launch Instance Using AWS CLI

CLI-based provisioning is commonly used for automation and infrastructure scripting.

---

## Step 1: Create Key Pair

```bash
aws ec2 create-key-pair \
  --key-name nautilus-kp \
  --key-type rsa \
  --query 'KeyMaterial' \
  --output text > nautilus-kp.pem \
  --region us-east-1

chmod 400 nautilus-kp.pem
```

This command generates a new SSH key pair and stores the private key locally.

---

<br>
<br>

## Step 2: Get Default Security Group ID

```bash
DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=default \
  --query 'SecurityGroups[0].GroupId' \
  --output text \
  --region us-east-1)

 echo $DEFAULT_SG_ID

# OUTPUT
# sg-094aae8bf2d6c6a6d
```

The command retrieves the security group identifier required for instance creation.

---

<br>
<br>

## Step 3: Retrieve Latest Amazon Linux AMI

```bash
AMI_ID=$(aws ssm get-parameters \
  --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
  --query 'Parameters[0].Value' \
  --output text \
  --region us-east-1)

 echo $AMI_ID

# OUTPUT
# ami-0199fa5fada510433
```

Using AWS Systems Manager ensures that the most recent Amazon Linux AMI is used.

---

<br>
<br>

## Step 4: Launch the Instance

```bash
aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --key-name nautilus-kp \
  --security-group-ids $DEFAULT_SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nautilus-ec2}]' \
  --region us-east-1

# OUTPUT

{
    "ReservationId": "r-01615b0d088ed28b0",
    "OwnerId": "971482151402",
    "Groups": [],
    "Instances": [
        {
            "Architecture": "x86_64",
            "BlockDeviceMappings": [],
            "ClientToken": "acb28892-acfe-4583-a740-2740aedfea2b",
            "EbsOptimized": false,
            "EnaSupport": true,
            "Hypervisor": "xen",
            "NetworkInterfaces": [
                {
                    "Attachment": {
                        "AttachTime": "2026-03-04T11:13:08.000Z",
                        "AttachmentId": "eni-attach-0fac5c5a82aa22b0e",
                        "DeleteOnTermination": true,
                        "DeviceIndex": 0,
                        "Status": "attaching",
                        "NetworkCardIndex": 0
                    },
                    "Description": "",
                    "Groups": [
                        {
                            "GroupId": "sg-094aae8bf2d6c6a6d",
                            "GroupName": "default"
                        }
                    ],
                    "Ipv6Addresses": [],
                    "MacAddress": "0a:ff:d4:5c:b5:c3",
                    "NetworkInterfaceId": "eni-02d836dc1f5200779",
                    "OwnerId": "971482151402",
                    "PrivateDnsName": "ip-172-31-17-121.ec2.internal",
                    "PrivateIpAddress": "172.31.17.121",
                    "PrivateIpAddresses": [
                        {
                            "Primary": true,
                            "PrivateDnsName": "ip-172-31-17-121.ec2.internal",
                            "PrivateIpAddress": "172.31.17.121"
                        }
                    ],
                    "SourceDestCheck": true,
                    "Status": "in-use",
                    "SubnetId": "subnet-07577a508f7765cfb",
                    "VpcId": "vpc-05d01c9c9a5be79a4",
                    "InterfaceType": "interface",
                    "Operator": {
                        "Managed": false
                    }
                }
            ],
            "RootDeviceName": "/dev/xvda",
            "RootDeviceType": "ebs",
            "SecurityGroups": [
                {
                    "GroupId": "sg-094aae8bf2d6c6a6d",
                    "GroupName": "default"
                }
            ],
            "SourceDestCheck": true,
            "StateReason": {
                "Code": "pending",
                "Message": "pending"
            },
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "nautilus-ec2"
                }
            ],
            "VirtualizationType": "hvm",
            "CpuOptions": {
                "CoreCount": 1,
                "ThreadsPerCore": 1
            },
            "CapacityReservationSpecification": {
                "CapacityReservationPreference": "open"
            },
            "MetadataOptions": {
                "State": "pending",
                "HttpTokens": "optional",
                "HttpPutResponseHopLimit": 1,
                "HttpEndpoint": "enabled",
                "HttpProtocolIpv6": "disabled",
                "InstanceMetadataTags": "disabled"
            },
            "EnclaveOptions": {
                "Enabled": false
            },
            "PrivateDnsNameOptions": {
                "HostnameType": "ip-name",
                "EnableResourceNameDnsARecord": false,
                "EnableResourceNameDnsAAAARecord": false
            },
            "MaintenanceOptions": {
                "AutoRecovery": "default",
                "RebootMigration": "default"
            },
            "CurrentInstanceBootMode": "legacy-bios",
            "Operator": {
                "Managed": false
            },
            "InstanceId": "i-0c2459ecf77232e94",
            "ImageId": "ami-0199fa5fada510433",
            "State": {
                "Code": 0,
                "Name": "pending"
            },
            "PrivateDnsName": "ip-172-31-17-121.ec2.internal",
            "PublicDnsName": "",
            "StateTransitionReason": "",
            "KeyName": "nautilus-kp",
            "AmiLaunchIndex": 0,
            "ProductCodes": [],
            "InstanceType": "t2.micro",
            "LaunchTime": "2026-03-04T11:13:08.000Z",
            "Placement": {
                "GroupName": "",
                "Tenancy": "default",
                "AvailabilityZone": "us-east-1a"
            },
            "Monitoring": {
                "State": "disabled"
            },
            "SubnetId": "subnet-07577a508f7765cfb",
            "VpcId": "vpc-05d01c9c9a5be79a4",
            "PrivateIpAddress": "172.31.17.121"
        }
    ]
}
```

This command provisions the EC2 instance with the specified configuration.

---

<br>
<br>

# Step 5: Verify Instance

To confirm that the instance is running:

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nautilus-ec2" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]" \
  --output table \
  --region us-east-1

# OUTPUT

-----------------------------------------------------
|                 DescribeInstances                 |
+----------------------+----------+-----------------+
|  i-0c2459ecf77232e94 |  running |  100.53.13.199  |
+----------------------+----------+-----------------+
```

Expected output includes:

* Instance ID
* Running state
* Public IP address

---

<br>
<br>

# Key Outcome

An EC2 instance named `nautilus-ec2` is successfully launched in the `us-east-1` region using the `t2.micro` instance type and Amazon Linux AMI. The instance is secured using the `nautilus-kp` key pair and protected by the default security group.
