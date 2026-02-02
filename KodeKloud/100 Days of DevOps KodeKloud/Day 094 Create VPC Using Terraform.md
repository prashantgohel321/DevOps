# DevOps Day 94: Create VPC Using Terraform

This document outlines the solution for DevOps Day 94. The objective was to provision a fundamental networking component—an AWS Virtual Private Cloud (VPC)—using Infrastructure as Code (IaC) with Terraform.

## Table of Contents
- [DevOps Day 94: Create VPC Using Terraform](#devops-day-94-create-vpc-using-terraform)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the `main.tf` File](#1-create-the-maintf-file)
    - [2. Initialize Terraform](#2-initialize-terraform)
    - [3. Generate the Plan](#3-generate-the-plan)
    - [4. Apply the Configuration](#4-apply-the-configuration)
  - [Deep Dive: How Terraform Works Internally](#deep-dive-how-terraform-works-internally)
    - [Core Architecture](#core-architecture)
    - [The Provider Plugin Model](#the-provider-plugin-model)
    - [State Management (`terraform.tfstate`)](#state-management-terraformtfstate)
    - [Execution Flow](#execution-flow)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision an AWS VPC named `nautilus-vpc` in the `us-east-1` region using Terraform.

**Requirements:**
1.  **Directory:** `/home/bob/terraform`
2.  **File:** Create only `main.tf`.
3.  **Resource:** `aws_vpc`
4.  **Properties:**
    * **Name Tag:** `nautilus-vpc`
    * **CIDR Block:** Any valid IPv4 CIDR (e.g., `10.0.0.0/16`).
    * **Region:** `us-east-1`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the `main.tf` File
<a name="1-create-the-maintf-file"></a>
This file contains the provider configuration (telling Terraform *where* to create resources) and the resource definition (telling Terraform *what* to create).

**Command:**
```bash
cd /home/bob/terraform
vi main.tf
```

**Content:**
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "nautilus-vpc"
  }
}
```

### 2. Initialize Terraform
<a name="2-initialize-terraform"></a>
Before Terraform can do anything, it needs to download the code that knows how to talk to AWS. This is the **AWS Provider**.

**Command:**
```bash
terraform init
```
* **Output:** "Terraform has been successfully initialized!"
* **What happened:** Terraform scanned `main.tf`, saw `provider "aws"`, and downloaded the AWS plugin into a hidden `.terraform/` directory.

### 3. Generate the Plan
<a name="3-generate-the-plan"></a>
This is a dry run. Terraform compares your `main.tf` against the *current state* of your AWS account (which is empty right now).

**Command:**
```bash
terraform plan
```
* **Output:** `Plan: 1 to add, 0 to change, 0 to destroy.`
* **Analysis:** Terraform calculates that to match your code, it needs to create one new VPC.

### 4. Apply the Configuration
<a name="4-apply-the-configuration"></a>
This executes the plan and actually talks to the AWS API to create the resource.

**Command:**
```bash
terraform apply
```
* **Prompt:** Type `yes` when asked.
* **Output:** `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`

---

## Deep Dive: How Terraform Works Internally
<a name="deep-dive-how-terraform-works-internally"></a>

You asked how Terraform talks to cloud providers and creates infrastructure. Here is the breakdown of the magic under the hood.

### Core Architecture
<a name="core-architecture"></a>
Terraform is split into two main parts:
1.  **Terraform Core:** The binary you download (`terraform`). It reads your configuration files (`.tf`) and manages the **State**. It essentially builds a dependency graph of your resources (e.g., "I need a VPC before I can create a Subnet").
2.  **Providers:** These are separate plugins (like the AWS Provider, Azure Provider, Google Provider) that act as translators.

### The Provider Plugin Model
<a name="the-provider-plugin-model"></a>
Terraform Core *doesn't know* what an AWS VPC is. It just knows "resource aws_vpc".
* When you run `terraform apply`, Core passes the configuration data to the **AWS Provider Plugin**.
* **The Provider's Job:** The AWS Provider is written in Go and contains the AWS SDK. It translates the Terraform configuration (`cidr_block = "10.0.0.0/16"`) into an actual **AWS API Call** (e.g., `ec2:CreateVpc`).
* **Authentication:** The provider handles the authentication using the credentials stored in your environment (`~/.aws/credentials` or environment variables) to sign these API requests securely.

### State Management (`terraform.tfstate`)
<a name="state-management"></a>
This is Terraform's brain.
* When you created the VPC, AWS returned an ID (e.g., `vpc-01234567`).
* Terraform *must* remember this ID. If it forgets, running `terraform apply` again would create a *second* VPC instead of updating the first one.
* It saves this mapping (Resource Name `aws_vpc.main` -> Real ID `vpc-01234567`) in a JSON file called `terraform.tfstate`.

### Execution Flow
<a name="execution-flow"></a>
1.  **Read Config:** Terraform reads `main.tf`.
2.  **Refresh State:** It checks `terraform.tfstate` and queries the real AWS API to see if the resources still exist.
3.  **Diff:** It compares **Config** vs. **Real World**.
    * *Config says:* VPC exists with CIDR 10.0.0.0/16.
    * *Real World says:* Nothing exists.
    * *Result:* Create (+).
4.  **Execute:** It calls the AWS Provider -> AWS Provider calls AWS API (`CreateVpc`) -> AWS creates the VPC.
5.  **Update State:** AWS returns the new VPC ID. Terraform writes this into `terraform.tfstate`.
   