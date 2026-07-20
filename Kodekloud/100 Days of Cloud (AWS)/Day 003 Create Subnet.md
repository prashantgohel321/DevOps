# AWS Day 03: Creating a Subnet Inside the Default VPC

This document explains the third foundational networking step in AWS: creating a subnet. A subnet is not just an IP range. It is the boundary that defines where an EC2 instance physically lives inside a region. Every subnet belongs to exactly one Availability Zone, and every EC2 instance must be launched into a subnet. Without a subnet, an instance has no network placement.

The goal of this task is to create a subnet named `datacenter-subnet` inside the default VPC in the `us-east-1` region using a valid, non-overlapping CIDR range.

---

<br>
<br>

- [AWS Day 03: Creating a Subnet Inside the Default VPC](#aws-day-03-creating-a-subnet-inside-the-default-vpc)
  - [Why Subnets Exist Inside a VPC](#why-subnets-exist-inside-a-vpc)
  - [Fixed Requirements for This Task](#fixed-requirements-for-this-task)
  - [Understanding CIDR in Practical Terms](#understanding-cidr-in-practical-terms)
  - [Creating the Subnet Using the AWS Management Console](#creating-the-subnet-using-the-aws-management-console)
  - [Creating the Subnet Using the AWS CLI](#creating-the-subnet-using-the-aws-cli)
  - [Verifying the Subnet Creation](#verifying-the-subnet-creation)
  - [Internal Networking Behavior After Creation](#internal-networking-behavior-after-creation)
  - [Key Outcome of This Step](#key-outcome-of-this-step)


<br>
<br>

## Why Subnets Exist Inside a VPC

A VPC, or Virtual Private Cloud, is an isolated network inside AWS. When AWS creates a default VPC in a region, it assigns it a CIDR block such as `172.31.0.0/16`. That `/16` block represents a large pool of IP addresses.

A subnet is a smaller portion carved out of that larger block. For example, dividing `172.31.0.0/16` into `172.31.100.0/24` means you are reserving 256 IP addresses within that range for a specific zone.

Each subnet exists in one Availability Zone. An Availability Zone is an isolated data center location within a region, such as `us-east-1a` or `us-east-1b`. When you launch an EC2 instance into a subnet, the instance is physically placed in that zone.

This means subnet selection influences fault tolerance, routing behavior, and internet access patterns.

---

<br>
<br>

## Fixed Requirements for This Task

The subnet must:

* Be created in the `us-east-1` region
* Belong to the default VPC
* Be named `datacenter-subnet`
* Use a CIDR block that fits inside the default VPC range
* Avoid overlapping with any existing subnet CIDR blocks

A valid example range would be `172.31.100.0/24`, assuming it is unused.

---

<br>
<br>

## Understanding CIDR in Practical Terms

CIDR notation defines how large the subnet is.

The `/24` in `172.31.100.0/24` means the first 24 bits define the network portion and the remaining 8 bits define host addresses. That results in 256 total IP addresses.

AWS reserves 5 IP addresses in every subnet for internal networking. So in a `/24`, 251 IP addresses are usable for EC2 instances.

Choosing the CIDR is not random. It must:

* Fall within the parent VPC range
* Not overlap with any existing subnet
* Be large enough for expected growth

---

<br>
<br>

## Creating the Subnet Using the AWS Management Console

The console method is useful for visually checking overlap and selecting an Availability Zone.

After logging into AWS and verifying the region is `N. Virginia (us-east-1)`, search for the VPC service.

In the left navigation panel, select Subnets, then click Create subnet.

Select the default VPC from the dropdown. Enter `datacenter-subnet` as the name.

Choose an Availability Zone explicitly, for example `us-east-1a`. While leaving it as "No preference" is allowed, selecting a specific zone makes infrastructure placement intentional and predictable.

In the IPv4 CIDR block field, enter `172.31.100.0/24`. If AWS reports an overlap error, it means that CIDR is already assigned. In that case, select a nearby unused range such as `172.31.101.0/24`.

After validation succeeds, create the subnet.

At this point, the subnet exists but does not automatically guarantee internet access. Internet accessibility depends on route tables and whether an internet gateway is attached to the VPC.

---

<br>
<br>

## Creating the Subnet Using the AWS CLI

The CLI method requires awareness of the VPC ID and currently used subnets.

First, retrieve the default VPC ID.

```bash
aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" \
  --output text
```

This returns a value like `vpc-0ad6d017026d940c2`. This identifier uniquely represents the VPC inside the region.

Next, check existing subnet ranges to avoid overlap.

```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-0abc123def456ghij" \
  --query "Subnets[*].CidrBlock"
```

```text

[
    "172.31.64.0/20",
    "172.31.16.0/20",
    "172.31.32.0/20",
    "172.31.0.0/20",
    "172.31.80.0/20",
    "172.31.48.0/20"
]

```

Review the output and choose a CIDR block not listed.

Now create the subnet, replacing the VPC ID accordingly.

```bash
aws ec2 create-subnet \
  --vpc-id vpc-0abc123def456ghij \
  --cidr-block 172.31.100.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=datacenter-subnet}]' \
  --region us-east-1
```

```text

{
    "Subnet": {
        "AvailabilityZoneId": "use1-az5",
        "MapCustomerOwnedIpOnLaunch": false,
        "OwnerId": "700493584428",
        "AssignIpv6AddressOnCreation": false,
        "Ipv6CidrBlockAssociationSet": [],
        "Tags": [
            {
                "Key": "Name",
                "Value": "datacenter-subnet"
            }
        ],
        "SubnetArn": "arn:aws:ec2:us-east-1:700493584428:subnet/subnet-0d1fe53702aa9cae1",
        "EnableDns64": false,
        "Ipv6Native": false,
        "PrivateDnsNameOptionsOnLaunch": {
            "HostnameType": "ip-name",
            "EnableResourceNameDnsARecord": false,
            "EnableResourceNameDnsAAAARecord": false
        },
        "SubnetId": "subnet-0d1fe53702aa9cae1",
        "State": "available",
        "VpcId": "vpc-0ad6d017026d940c2",
        "CidrBlock": "172.31.100.0/24",
        "AvailableIpAddressCount": 251,
        "AvailabilityZone": "us-east-1f",
        "DefaultForAz": false,
        "MapPublicIpOnLaunch": false
    }
}

```

This command instructs AWS to:

* Place the subnet inside the specified VPC
* Allocate the chosen IP range
* Bind it to a specific Availability Zone
* Attach a Name tag immediately

Without tagging, the subnet would appear unnamed in the console, which complicates management at scale.

---

<br>
<br>

## Verifying the Subnet Creation

To confirm that the subnet exists and has the correct tag:

```bash
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=datacenter-subnet" \
  --region us-east-1
```

```text

{
    "Subnets": [
        {
            "AvailabilityZoneId": "use1-az5",
            "MapCustomerOwnedIpOnLaunch": false,
            "OwnerId": "700493584428",
            "AssignIpv6AddressOnCreation": false,
            "Ipv6CidrBlockAssociationSet": [],
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "datacenter-subnet"
                }
            ],
            "SubnetArn": "arn:aws:ec2:us-east-1:700493584428:subnet/subnet-0d1fe53702aa9cae1",
            "EnableDns64": false,
            "Ipv6Native": false,
            "PrivateDnsNameOptionsOnLaunch": {
                "HostnameType": "ip-name",
                "EnableResourceNameDnsARecord": false,
                "EnableResourceNameDnsAAAARecord": false
            },
            "BlockPublicAccessStates": {
                "InternetGatewayBlockMode": "off"
            },
            "SubnetId": "subnet-0d1fe53702aa9cae1",
            "State": "available",
            "VpcId": "vpc-0ad6d017026d940c2",
            "CidrBlock": "172.31.100.0/24",
            "AvailableIpAddressCount": 251,
            "AvailabilityZone": "us-east-1f",
            "DefaultForAz": false,
            "MapPublicIpOnLaunch": false
        }
    ]
}

```

The output should display the subnet ID, CIDR block, Availability Zone, and VPC association.

---

<br>
<br>

## Internal Networking Behavior After Creation

Creating a subnet only allocates IP space. It does not define whether instances in that subnet can reach the internet.

Internet access depends on three components working together:

* The VPC must have an Internet Gateway attached
* The subnet’s route table must contain a route to that gateway
* The EC2 instance must have a public IP (if direct internet access is required)

The default VPC typically has these elements pre-configured, which is why subnets created inside it often behave like public subnets by default.

However, understanding that subnets alone do not define internet reachability is critical for future architecture involving private subnets and NAT gateways.

---

<br>
<br>

## Key Outcome of This Step

At the end of this task, a new subnet named `datacenter-subnet` exists inside the default VPC in `us-east-1`, carved from a valid CIDR range and bound to a specific Availability Zone. This subnet can now host EC2 instances.

With the Key Pair, Security Group, and Subnet in place, all required networking components now exist to launch a properly isolated EC2 instance in the next step.
