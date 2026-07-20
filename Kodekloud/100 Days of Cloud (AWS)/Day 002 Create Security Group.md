# AWS Day 02: Creating a Security Group for Controlled Network Access

This document explains the second foundational step in working with AWS infrastructure: creating a Security Group. A Security Group defines which network traffic is allowed to reach an EC2 instance and which traffic is allowed to leave it. Unlike traditional firewalls configured directly on servers, Security Groups operate at the AWS networking layer and are enforced before traffic ever reaches the instance’s operating system.

The goal of this task is to create a Security Group named `nautilus-sg` in the default VPC of the `us-east-1` region, allowing web traffic over HTTP and administrative access using SSH. This setup mirrors a very common real-world starting point for application servers.

---

- [AWS Day 02: Creating a Security Group for Controlled Network Access](#aws-day-02-creating-a-security-group-for-controlled-network-access)
  - [What Is Being Created and Why It Exists](#what-is-being-created-and-why-it-exists)
  - [Fixed Requirements for This Task](#fixed-requirements-for-this-task)
  - [Understanding the Networking Terms in Context](#understanding-the-networking-terms-in-context)
  - [Creating the Security Group Using the AWS Management Console](#creating-the-security-group-using-the-aws-management-console)
  - [Creating the Security Group Using the AWS CLI](#creating-the-security-group-using-the-aws-cli)
  - [Verifying the Security Group Configuration](#verifying-the-security-group-configuration)
  - [Internal Behavior and Practical Implications](#internal-behavior-and-practical-implications)
  - [Key Outcome of This Step](#key-outcome-of-this-step)



## What Is Being Created and Why It Exists

A Security Group is an AWS-managed virtual firewall. Every EC2 instance must be associated with at least one Security Group. When traffic reaches AWS networking, the Security Group rules are evaluated first. If traffic does not match any allowed rule, it is silently dropped.

Security Groups are stateful. This means if inbound traffic is allowed, the response traffic is automatically permitted back out, even if no explicit outbound rule exists for that response. This behavior removes the need to manually define return paths for connections like SSH or HTTP.

In this task, the Security Group exists to allow two types of access. HTTP access allows users or tools to reach a web service running on the instance. SSH access allows administrators to log in securely to manage or troubleshoot the server.

---

## Fixed Requirements for This Task

The Security Group must be created with a specific name and description so it can be easily identified later.

The group name must be `nautilus-sg`.

The description must be `Security group for Nautilus App Servers`.

It must be created inside the default VPC of the `us-east-1` region. AWS isolates networking per region, so choosing the correct region is mandatory.

Two inbound rules must exist. One rule must allow TCP traffic on port 80 from anywhere on the internet. The second rule must allow TCP traffic on port 22 from anywhere on the internet.

---

## Understanding the Networking Terms in Context

Inbound rules, also called ingress rules, control traffic coming into an instance. Each rule defines three things: where the traffic comes from, which protocol it uses, and which port it targets.

The CIDR value `0.0.0.0/0` represents the entire IPv4 internet. Using this source means the port is open to connections from any public IP address.

Port 80 is the standard port used by HTTP, which is unencrypted web traffic. Web servers such as Apache or Nginx listen on this port by default.

Port 22 is the standard port for SSH, which is a secure, encrypted protocol used to access Linux servers remotely.

The default VPC is an automatically created virtual network that AWS provides in every region. It includes predefined subnets, route tables, and an internet gateway, making it suitable for simple setups and learning environments.

---

## Creating the Security Group Using the AWS Management Console

The AWS Management Console provides a visual way to define networking rules and is useful for understanding how Security Groups are structured.

Begin by opening the AWS Console using the provided login URL and credentials. After login, verify that the selected region in the top-right corner is `N. Virginia (us-east-1)`. Resources created in a different region will not be visible here.

Navigate to the EC2 service using the search bar. In the EC2 dashboard, locate the Network & Security section in the left-hand navigation menu and select Security Groups.

Click the Create security group button. In the basic details section, enter `nautilus-sg` as the name and `Security group for Nautilus App Servers` as the description. Leave the VPC selection set to the default VPC.

Under the inbound rules section, add two rules. The first rule uses the predefined HTTP type, which automatically sets the protocol to TCP and the port to 80. Set the source to Anywhere IPv4, which corresponds to `0.0.0.0/0`.

Add a second rule using the SSH type. This sets the protocol to TCP and the port to 22. Again, set the source to Anywhere IPv4.

After reviewing the rules, create the Security Group. At this point, the group exists and can be attached to EC2 instances.

---

## Creating the Security Group Using the AWS CLI

The AWS CLI method mirrors how infrastructure is often created in automation scripts. Each command maps directly to an AWS API call.

The first step is to create the Security Group object itself. This command registers the group name and description with AWS inside the default VPC.

```bash
aws ec2 create-security-group \
  --group-name nautilus-sg \
  --description "Security group for Nautilus App Servers" \
  --region us-east-1

===  OUTPUT  ===

{
    "GroupId": "sg-05b61b38daa0f311c",
    "SecurityGroupArn": "arn:aws:ec2:us-east-1:236330316854:security-group/sg-05b61b38daa0f311c"
}

```

The output of this command includes a unique Security Group ID. This ID uniquely identifies the group within the region, even if another group has the same name in the future.

After the group exists, inbound rules are added one by one.

To allow HTTP traffic on port 80:

```bash
aws ec2 authorize-security-group-ingress \
  --group-name nautilus-sg \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region us-east-1


===  OUTPUT  ===

{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-0d5aac99f385a1df6",
            "GroupId": "sg-05b61b38daa0f311c",
            "GroupOwnerId": "236330316854",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIpv4": "0.0.0.0/0",
            "SecurityGroupRuleArn": "arn:aws:ec2:us-east-1:236330316854:security-group-rule/sgr-0d5aac99f385a1df6"
        }
    ]
}
```

This command tells AWS to accept TCP connections targeting port 80 from any IPv4 address.

To allow SSH traffic on port 22:

```bash
aws ec2 authorize-security-group-ingress \
  --group-name nautilus-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region us-east-1

===  OUTPUT  ===

{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-01af7679f7d8730b0",
            "GroupId": "sg-05b61b38daa0f311c",
            "GroupOwnerId": "236330316854",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "CidrIpv4": "0.0.0.0/0",
            "SecurityGroupRuleArn": "arn:aws:ec2:us-east-1:236330316854:security-group-rule/sgr-01af7679f7d8730b0"
        }
    ]
}

```

Each rule is stored independently inside the Security Group.

---

## Verifying the Security Group Configuration

To confirm that the Security Group and its rules were created correctly, query AWS for the group details.

```bash
aws ec2 describe-security-groups \
  --group-names nautilus-sg \
  --region us-east-1

===  OUTPUT  ===

{
    "SecurityGroups": [
        {
            "GroupId": "sg-05b61b38daa0f311c",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ],
            "VpcId": "vpc-0fc37e8f7ee7c2453",
            "SecurityGroupArn": "arn:aws:ec2:us-east-1:236330316854:security-group/sg-05b61b38daa0f311c",
            "OwnerId": "236330316854",
            "GroupName": "nautilus-sg",
            "Description": "Security group for Nautilus App Servers",
            "IpPermissions": [
                {
                    "IpProtocol": "tcp",
                    "FromPort": 80,
                    "ToPort": 80,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": 22,
                    "ToPort": 22,
                    "UserIdGroupPairs": [],
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": []
                }
            ]
        }
    ]
}

```

The output shows all inbound and outbound rules associated with the group. You should see two inbound rules matching ports 80 and 22 with a source of `0.0.0.0/0`.

---

## Internal Behavior and Practical Implications

Security Groups do not inspect traffic content. They only evaluate protocol, port, and source or destination. If a packet matches an allowed rule, it is permitted. Otherwise, it is dropped without notification.

Because Security Groups are stateful, allowing inbound SSH automatically allows the server to send SSH responses back to the client. No extra outbound rule is required for this behavior.

Opening SSH to the entire internet is acceptable for lab environments but is risky in production. In real deployments, SSH access is usually restricted to a known IP range or a bastion host.

---

## Key Outcome of This Step

At the end of this task, a reusable Security Group exists that allows web and administrative access to EC2 instances in the `us-east-1` region. This group can now be attached during instance launch or applied to existing instances. With network access defined, the next logical step is launching an EC2 instance that uses this Security Group.
