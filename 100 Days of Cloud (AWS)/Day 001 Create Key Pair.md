# AWS Day 01: Creating a Key Pair for Secure EC2 Access

This document walks through the first practical step in an AWS learning and migration journey: creating a Key Pair. A key pair is not just a formality in AWS. It is the foundation of how secure access to Linux-based EC2 instances works. Every EC2 instance that you will create later relies on this key pair for login, troubleshooting, automation, and recovery. If this step is not understood properly, many future problems will appear confusing and hard to debug.

The goal of this task is to create one reusable key pair named `devops-kp` in the `us-east-1` region using both the AWS Console and the AWS CLI, and to understand what actually happens internally when the key pair is created and used.

---

- [AWS Day 01: Creating a Key Pair for Secure EC2 Access](#aws-day-01-creating-a-key-pair-for-secure-ec2-access)
  - [What You Are Creating and Why It Exists](#what-you-are-creating-and-why-it-exists)
  - [Fixed Requirements for This Task](#fixed-requirements-for-this-task)
  - [Understanding the Terms as They Appear](#understanding-the-terms-as-they-appear)
  - [Creating the Key Pair Using the AWS Console](#creating-the-key-pair-using-the-aws-console)
  - [Creating the Key Pair Using the AWS CLI](#creating-the-key-pair-using-the-aws-cli)
  - [Securing the Private Key on the Local System](#securing-the-private-key-on-the-local-system)
  - [Verifying the Key Pair Exists in AWS](#verifying-the-key-pair-exists-in-aws)
  - [Exploring Additional Useful Commands](#exploring-additional-useful-commands)
  - [Summary of What You Learned Internally](#summary-of-what-you-learned-internally)



<br>
<br>

## What You Are Creating and Why It Exists

You are creating a key pair, which is simply a cryptographic identity used for SSH access. SSH, which stands for Secure Shell, is the protocol used to open a secure terminal session to a remote Linux server. Instead of logging in with a username and password, SSH uses cryptographic proof. This proof is based on two mathematically linked keys.

One key is private and must stay only with you. This is the private key file that gets downloaded to your machine. The other key is public and is stored by AWS. When an EC2 instance is launched, AWS injects the public key into the instance. During login, your SSH client proves that it owns the private key that matches the public key already present on the server. If the proof matches, access is granted.

AWS never stores your private key. This design is intentional. It means AWS cannot log into your servers, but it also means that if the private key is lost, access to the instance is permanently lost unless other recovery mechanisms exist.

---

<br>
<br>

## Fixed Requirements for This Task

The key pair created in this task must follow these exact parameters so that later examples and commands continue to work consistently.

The resource being created is a Key Pair. The name of the key pair must be `devops-kp`. The encryption algorithm must be RSA, which is the most widely supported public-key algorithm for SSH. The AWS region must be `us-east-1`, which physically corresponds to the North Virginia AWS region.

AWS resources are always region-scoped. A key pair created in one region cannot be used in another region. This becomes very important later when working with multiple environments.

---

<br>
<br>

## Understanding the Terms as They Appear

A **key pair** is a logical object in AWS that represents a public key stored by AWS and a private key stored by you. The private key never leaves your machine unless you copy it yourself.

**RSA** refers to the encryption algorithm used to generate the keys. In simple terms, it is the mathematical method used to ensure that the public key and private key are linked in a way that cannot be guessed or reversed.

A **PEM file** is a plain text file that contains the private key in a specific format understood by OpenSSH, which is the default SSH client on Linux, macOS, and modern Windows PowerShell.

A **PPK file** is the same private key but converted into a format used by PuTTY, which is an older SSH client commonly used on Windows.

A **region** in AWS is a physically separate group of data centers. Resources created in one region are isolated from other regions unless explicitly copied or recreated.

---

<br>
<br>

## Creating the Key Pair Using the AWS Console

The AWS Management Console is the web-based interface. This method is useful when you are new, when you want visual confirmation, or when you are explaining concepts to others.

Start by opening the AWS Console URL that was provided with your credentials. Log in using the given username and password. After logging in, the first thing to verify is the region selector at the top right of the screen. It must show `N. Virginia (us-east-1)`. If it shows any other region, change it before proceeding.

In the global search bar at the top, type `EC2` and select the EC2 service from the results. This opens the EC2 dashboard.

In the left navigation menu, scroll until you find the section named **Network & Security**. Inside this section, click on **Key Pairs.** This page shows all key pairs that already exist in the selected region.

Click the **Create key pair** button. A configuration form will appear. Enter `devops-kp` as the key pair name. **Select RSA** as the key pair type. For the private key file format, choose **PEM** if you are using Linux, macOS, or PowerShell. Choose PPK only if you are planning to use PuTTY.

Once you click **Create key pair**, AWS generates the key material. The public key is stored internally by AWS. The private key is sent once to your browser and immediately downloaded. This is the only time AWS will ever show you this private key.

Save the downloaded file securely. If this file is deleted or lost, it cannot be recovered or re-downloaded.

---

<br>
<br>

## Creating the Key Pair Using the AWS CLI

The AWS CLI method is closer to how automation and real production work is done. Everything happens from the terminal, and nothing relies on clicking buttons.

Before creating the key pair, the AWS CLI must know who you are and which region to operate in. This is done using the `aws configure` command. This command stores your access credentials and default region locally.

```bash
aws configure
```

During this process, you provide the Access Key ID and Secret Access Key. These are long-lived credentials tied to an IAM user. You also specify `us-east-1` as the default region and `json` as the default output format.

Once the CLI is configured, the key pair can be created using a single command.

```bash
aws ec2 create-key-pair \
  --key-name devops-kp \
  --key-type rsa \
  --query 'KeyMaterial' \
  --output text > devops-kp.pem
```

Internally, this command calls the EC2 API to generate a new key pair. AWS generates the public and private key together. The public key is stored by AWS. The private key is returned one time in the API response.

The `--query 'KeyMaterial'` option extracts only the private key text from the full API response. The `--output text` option ensures the key is written as clean text instead of JSON. The redirection operator `>` writes that text directly into a file named `devops-kp.pem`.

If any of these options are removed or changed incorrectly, the resulting file may be unusable for SSH.

---

<br>
<br>

## Securing the Private Key on the Local System

SSH clients are strict about private key permissions. If a private key file can be read by other users on the system, SSH will refuse to use it.

To restrict access, change the file permissions so that only the owner can read the file.

```bash
chmod 400 devops-kp.pem
```

This permission mode means the owner can read the file, but no one can write to it, and no other user can read it. This step is mandatory on Linux and macOS systems.

---

<br>
<br>

## Verifying the Key Pair Exists in AWS

To confirm that the key pair was successfully created and stored in AWS, use the following command.

```bash
aws ec2 describe-key-pairs --key-names devops-kp
```

This command queries AWS for metadata about the key pair. The output includes the key name, key type, creation time, and fingerprint. The fingerprint is a hash that uniquely represents the public key and is often used for verification and auditing.

---

<br>
<br>

## Exploring Additional Useful Commands

You can list all key pairs in the current region using:

```bash
aws ec2 describe-key-pairs
```

To delete a key pair when it is no longer needed:

```bash
aws ec2 delete-key-pair --key-name devops-kp
```

Deleting a key pair from AWS does not delete the private key file from your machine. However, any EC2 instance that relies on that key pair will become inaccessible if no other access method exists.

To check which region your CLI is currently using:

```bash
aws configure get region
```

Understanding and practicing these commands builds muscle memory that becomes essential later when launching instances, configuring automation, and managing infrastructure at scale.

---

<br>
<br>

## Summary of What You Learned Internally

A key pair is not just a file; it is a trust relationship between your machine and AWS-managed servers. AWS stores only the public key and never your private key. Regions isolate resources, so consistency in region selection matters. Console actions and CLI commands ultimately call the same AWS APIs, but the CLI exposes how automation actually works. Securing the private key locally is just as important as creating it.

With this foundation in place, the next logical step is launching an EC2 instance that uses this key pair for secure access.
