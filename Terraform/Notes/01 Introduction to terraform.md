# Introduction to Terraform

<br>
<br>

- [Introduction to Terraform](#introduction-to-terraform)
  - [Understanding the Problem Terraform Solves](#understanding-the-problem-terraform-solves)
  - [What Terraform Actually Is](#what-terraform-actually-is)
  - [A Simple Real-World Analogy](#a-simple-real-world-analogy)
  - [Infrastructure Components Terraform Can Manage](#infrastructure-components-terraform-can-manage)
  - [Terraform Configuration Files](#terraform-configuration-files)
  - [Terraform Workflow](#terraform-workflow)
    - [1. Initialization](#1-initialization)
    - [2. Planning](#2-planning)
    - [3. Applying](#3-applying)
    - [4. Destroying Infrastructure](#4-destroying-infrastructure)
  - [Terraform State](#terraform-state)
  - [Local State vs Remote State](#local-state-vs-remote-state)
  - [Modules in Terraform](#modules-in-terraform)
  - [Variables in Terraform](#variables-in-terraform)
  - [Outputs in Terraform](#outputs-in-terraform)
  - [Dependency Management](#dependency-management)
  - [Idempotency in Terraform](#idempotency-in-terraform)
  - [Practical Real-World Scenario](#practical-real-world-scenario)
  - [Why Terraform Became Popular in DevOps](#why-terraform-became-popular-in-devops)
  - [Closing Understanding](#closing-understanding)


<br>
<br>

## Understanding the Problem Terraform Solves

- When infrastructure is created manually, systems slowly become difficult to manage. Imagine a situation where a team needs to deploy a web application. They log in to a cloud platform, create virtual machines, configure networks, attach storage, install software, and connect everything together. At first this seems manageable, but after some time the environment grows. There might be multiple servers, load balancers, databases, storage buckets, and networking rules.

- Now imagine that this same setup needs to be recreated in another region, or for another environment such as testing or staging. Repeating the entire process manually becomes slow and error-prone. One engineer might configure something slightly differently than another. Over time the infrastructure becomes inconsistent and difficult to reproduce.

- This problem led to the idea of **Infrastructure as Code**, often shortened as **IaC**. Infrastructure as Code means <mark><b>describing infrastructure using code files instead of creating it manually through graphical interfaces</b></mark>. The infrastructure becomes reproducible, version controlled, and easy to automate.

- This is where Terraform enters.

- Terraform is a tool that allows infrastructure to be defined using code, and then automatically created and managed by executing that code. Instead of manually clicking buttons in a cloud console, a developer writes configuration files describing the desired infrastructure. Terraform reads those files, compares them with the current state of the infrastructure, and performs the actions required to reach the desired state.

- In simple words, Terraform is a system that converts infrastructure descriptions written in code into real infrastructure in cloud platforms or data centers.

---

<br>
<br>

## What Terraform Actually Is

- Terraform is an open source Infrastructure as Code tool developed by the organization **HashiCorp**, a company known for creating tools focused on infrastructure automation.

- Terraform works by allowing users to describe infrastructure using a configuration language called **HCL**, which stands for **HashiCorp Configuration Language**. HCL is designed to be human readable and easy to understand.

- A Terraform configuration file might describe things such as:
  - A virtual server
  - A network
  - A storage bucket
  - A load balancer
  - Firewall rules
  - Databases

- Once the configuration is written, Terraform reads the configuration and determines what needs to be created, changed, or destroyed in order to match the desired infrastructure.

- This process is often described as **declarative infrastructure management**.
  - **Declarative** means that instead of writing step-by-step instructions, the user describes the final desired state. Terraform then determines the steps required to reach that state.

<br>

**For example, instead of writing instructions like:**
- "Create a server, then attach a disk, then configure networking..."

**the configuration simply declares:**
- "There should be one server with this disk and this network."

Terraform figures out the rest.

---

<br>
<br>

## A Simple Real-World Analogy

Imagine building a house.

**Traditional manual infrastructure creation is like hiring workers and telling them step by step:**

* Bring bricks
* Lay foundation
* Build walls
* Install windows
* Install roof

Every time you want to build another house, you must repeat the instructions and supervise the work.

Terraform is like providing a **complete blueprint of the house**.

**The blueprint describes:**
* number of rooms
* window positions
* electrical wiring
* plumbing
* structure

The construction system reads the blueprint and builds the house exactly according to that plan.

If later you update the blueprint to add another room, the builders only construct the additional part instead of rebuilding everything.

Terraform behaves in the same way with infrastructure.

---

<br>
<br>

## Infrastructure Components Terraform Can Manage

- Terraform can manage infrastructure across many platforms. These platforms are called **providers**.

- A <mark><b>provider</b></mark> is essentially *a plugin that allows Terraform to communicate with an external system*.

**Examples include:**
* AWS
* Azure
* Google Cloud
* Kubernetes
* Docker
* GitHub
* Databases
* Monitoring systems

For example, if Terraform needs to create an EC2 instance in AWS, it communicates with AWS using the AWS API.

An **API**, or Application Programming Interface, is simply a mechanism that allows software systems to talk to each other programmatically. Instead of clicking buttons in the AWS console, Terraform sends requests to AWS APIs to create resources.

---

<br>
<br>

## Terraform Configuration Files

Terraform works with configuration files written using HCL.

**These files typically use the extension:**

```bash
.tf
```

**A very small example of a Terraform configuration looks like this:**

```bash
provider "aws" {  # This block defines the provider, which in this case is AWS.
  region = "ap-south-1"  # This line specifies the region where resources will be created.
}

resource "aws_instance" "web_server" {  # This block defines the resource, which in this case is an EC2 instance.
  ami           = "ami-0abcdef123456"  # This line specifies the Amazon Machine Image (AMI) to use for the instance.
  instance_type = "t2.micro"  # This line specifies the type of instance to create.
}
```

- Even though this configuration is very small, it contains powerful instructions.

- The first block defines a **provider**, which tells Terraform which cloud or service it will interact with.

- The second block defines a **resource**.
  - A resource represents any infrastructure component managed by Terraform. In this case, the resource is an AWS EC2 instance, which is a virtual machine running in AWS.

- The resource block describes the desired properties of that instance, such as the Amazon Machine Image (AMI) and instance type.

- When Terraform runs, it reads this file and creates the EC2 instance accordingly.

---

<br>
<br>

## Terraform Workflow

Terraform usually follows a specific workflow consisting of several stages.

### 1. Initialization

- Before Terraform can start managing infrastructure, it must download the required providers.

**This is done using the command:**

```bash
terraform init
```

- Initialization prepares the working directory by downloading provider plugins and setting up internal files.

- These provider plugins are the components that allow Terraform to interact with external platforms such as AWS or Docker.

---

<br>
<br>

### 2. Planning

Once Terraform is initialized, the next step is to see what changes Terraform will make.

This is done using:

```bash
terraform plan
```

**The plan command analyzes:**

1. The configuration files written by the user
2. The current infrastructure state

<br>

Terraform then calculates the difference between the current state and the desired state.

This difference is called an **execution plan**.

**The plan clearly shows what Terraform intends to do, such as:**

* create resources
* modify resources
* destroy resources

This step is extremely important because it prevents accidental infrastructure changes.

---

### 3. Applying

Once the plan looks correct, Terraform can execute the changes.

```bash
terraform apply
```

Terraform then communicates with the provider APIs and performs the required operations.

**For example:**

* create servers
* configure networking
* attach storage
* configure security groups

After the process finishes, the infrastructure exists exactly as described in the configuration files.

---

<br>
<br>

### 4. Destroying Infrastructure

Sometimes infrastructure is temporary.

**For example:**

* development environments
* testing environments
* CI pipelines

Terraform can remove infrastructure completely using:

```bash
terraform destroy
```

This command reads the Terraform configuration and deletes all resources defined within it.

---

<br>
<br>

## Terraform State

One of the most important internal concepts of Terraform is **state**.

Terraform keeps track of the infrastructure it manages using a state file.

The state file is usually named:

```bash
terraform.tfstate
```

**This file contains a mapping between:**

* Terraform configuration
* Real infrastructure resources

**For example, if Terraform created an EC2 instance, the state file stores information such as:**

* instance ID
* resource attributes
* relationships with other resources

This allows Terraform to understand what already exists and what changes are needed.

Without state, Terraform would not know whether infrastructure already exists or needs to be created.

---

<br>
<br>

## Local State vs Remote State

By default, Terraform stores the state file locally.

However, when multiple engineers work on the same infrastructure, storing state locally becomes risky. Two engineers might accidentally overwrite each other's changes.

To solve this problem, Terraform supports **remote state**.

**Remote state means storing the state file in a shared location such as:**

* S3
* Terraform Cloud
* Azure Storage
* Google Cloud Storage

For example, storing the state file in an S3 bucket allows multiple engineers to collaborate safely.

Terraform also supports **state locking**, which prevents multiple people from modifying infrastructure at the same time.

---

<br>
<br>

## Modules in Terraform

- As infrastructure grows larger, configuration files become complex.

- Terraform solves this problem using **modules**.

- A module is simply a reusable Terraform configuration.

- Instead of writing the same infrastructure repeatedly, a module can be created once and reused many times.

**For example, a module might represent:**

* a standard VPC architecture
* a Kubernetes cluster
* a web application infrastructure
* a database setup

**Using modules improves:**

* reusability
* maintainability
* consistency

---

<br>
<br>

## Variables in Terraform

Infrastructure often needs customization.

**For example:**

* different instance sizes
* different regions
* different environment names

Terraform allows parameters to be defined using **variables**.

**Example:**

```bash
variable "instance_type" {  # This block defines a variable named "instance_type".
  default = "t2.micro"  # This line sets a default value for the variable, which is "t2.micro". If no value is provided when running Terraform, it will use this default.
}
```

The configuration can then use that variable.

```bash
instance_type = var.instance_type
```

This allows the same Terraform code to be reused across environments such as development, staging, and production.

---

<br>
<br>

## Outputs in Terraform

After infrastructure is created, certain information may need to be shared.

**For example:**

* server IP address
* load balancer DNS name
* database endpoint

Terraform provides **outputs** to expose such information.

**Example:**

```bash
output "server_ip" {  # This block defines an output variable named "server_ip".
  value = aws_instance.web_server.public_ip  # This line specifies that the value of this output should be the public IP address of the "web_server" instance defined in the AWS provider.
}
```

When Terraform finishes applying changes, it displays these outputs.

---

<br>
<br>

## Dependency Management

Infrastructure resources often depend on each other.

**For example:**

* a server cannot be created before a network exists
* a load balancer cannot connect to servers that do not exist yet

Terraform automatically detects these relationships using **dependency graphs**.

Internally, Terraform builds a graph of resource dependencies and executes operations in the correct order.

This means infrastructure is created efficiently and safely.

---

<br>
<br>

## Idempotency in Terraform

- Terraform follows an important principle called **idempotency**.

- Idempotency means that running the same configuration multiple times produces the same result without unintended changes.

- For example, if the configuration specifies one EC2 instance and that instance already exists, Terraform will not create another one.

- Instead, it confirms that the infrastructure already matches the desired state.

- This ensures infrastructure stability and predictability.

---

<br>
<br>

## Practical Real-World Scenario

Consider a real DevOps environment.

**A team needs to deploy a web application with the following architecture:**

* VPC network
* public and private subnets
* EC2 instances
* load balancer
* database
* monitoring tools

Without Terraform, engineers would manually create each component through the cloud console.

With Terraform, the entire infrastructure can be defined using code.

```bash
terraform apply
```

- Within minutes the entire architecture appears.

- If the team wants to replicate the same infrastructure in another region, they only need to change the region variable and run Terraform again.

- This ability to replicate infrastructure quickly and consistently is one of the main reasons Terraform is widely used in DevOps environments.

---

<br>
<br>

## Why Terraform Became Popular in DevOps

- Terraform became widely adopted because it solves several real infrastructure challenges.

- First, infrastructure becomes version controlled using tools like Git. Changes to infrastructure can be tracked exactly like application code.

- Second, infrastructure becomes reproducible. Any environment can be recreated using the same configuration files.

- Third, Terraform supports **multi-cloud environments**, meaning it can manage infrastructure across different cloud providers using a single tool.

- Finally, Terraform integrates naturally into **CI/CD pipelines**, allowing infrastructure to be automatically provisioned during application deployments.

---

<br>
<br>

## Closing Understanding

- Terraform fundamentally changes how infrastructure is created and managed. Instead of manually building infrastructure piece by piece, engineers describe the desired infrastructure in configuration files. Terraform interprets those files, calculates the difference between the current state and the desired state, and automatically performs the necessary actions to align them.

- This approach turns infrastructure into programmable, repeatable, and version controlled systems, which aligns perfectly with the automation goals of modern DevOps practices.
