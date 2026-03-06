# Terraform Level 1, Task 25: Modifying Live Infrastructure with Terraform

Today's task was a powerful lesson in the true purpose of Terraform. So far, I've been using it to *create* new resources. This task taught me how to use Terraform to **manage and update** resources that already exist. My objective was to change the instance type of a running EC2 server from `t2.micro` to `t2.nano`, all by making a one-line change in my code.

This was a fantastic demonstration of "Infrastructure as Code" as a "living" document, not just a one-time script. I learned how Terraform uses its state file to understand what it's already managing and how `terraform plan` can intelligently figure out *what* to change instead of trying to create a new, duplicate server. This document is my very detailed, first-person guide to that entire process.

## Table of Contents
- [Terraform Level 1, Task 25: Modifying Live Infrastructure with Terraform](#terraform-level-1-task-25-modifying-live-infrastructure-with-terraform)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Editing the Code](#phase-1-editing-the-code)
      - [Phase 2: The Terraform Workflow](#phase-2-the-terraform-workflow)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: A Line-by-Line Explanation of the Change](#deep-dive-a-line-by-line-explanation-of-the-change)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the Essential Terraform Commands](#exploring-the-essential-terraform-commands)

---

### The Task
<a name="the-task"></a>
My objective was to use Terraform to modify an existing EC2 instance. The requirements were:
1.  Find the existing instance `nautilus-ec2` in my Terraform code.
2.  Change its instance type from `t2.micro` to `t2.nano`.
3.  Ensure the instance was left in a running state.
4.  All this had to be done by **updating** the `main.tf` file.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved a simple code change, followed by the `plan` and `apply` workflow.

#### Phase 1: Editing the Code
1.  I connected to the `iac-server` and navigated to the `/home/bob/terraform` directory.
2.  I opened the existing `main.tf` file, which already contained the definition for the `nautilus-ec2` instance.
3.  I located the `aws_instance` resource block for `nautilus-ec2`.
4.  I found the line `instance_type = "t2.micro"` and simply changed it to `instance_type = "t2.nano"`.

**Before (in `main.tf`):**
```terraform
resource "aws_instance" "nautilus_ec2" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t2.micro" # <-- This was the old line
  tags = {
    Name = "nautilus-ec2"
  }
}
```

**After (in `main.tf`):**
```terraform
resource "aws_instance" "nautilus_ec2" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t2.nano" # <-- This is the only line I changed
  tags = {
    Name = "nautilus-ec2"
  }
}
```

#### Phase 2: The Terraform Workflow
From my terminal, I executed the core commands.
1.  **Initialize:** `terraform init`. This was just a good habit to ensure providers were loaded.
2.  **Plan:** `terraform plan`. This was the most insightful step. The plan *did not* say "1 to add." Instead, it showed `~ 1 to change`. This `~` symbol means an **in-place update**. It confirmed that Terraform knew the instance already existed and just needed to be modified.
3.  **Apply:** `terraform apply`. After I confirmed with `yes`, Terraform connected to AWS and performed the change. This involved AWS stopping the instance, modifying its type, and starting it again. Terraform waited for this entire process to complete before reporting success.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Managing Change (The Core of IaC):** This task demonstrated the real power of Infrastructure as Code. The code in my `main.tf` file is not just a one-time script; it is the **single source of truth** for my desired infrastructure. When I need to change my infrastructure (like resizing a server), I don't log into the AWS console and click buttons. I **change the code**.
-   **Terraform State (`terraform.tfstate`)**: How did Terraform know not to create a *new* server? Because of the **state file** (`terraform.tfstate`). This is a JSON file that Terraform maintains in the same directory. It's a database that maps the resources in my code (like `aws_instance.nautilus_ec2`) to the real-world resources in my cloud account (like the instance ID `i-12345abcdef`).
-   **How `plan` Works:** When I run `terraform plan`, Terraform does a three-way comparison:
    1.  **The Code (Desired State):** What I *want* (e.g., a `t2.nano`).
    2.  **The State File (Recorded State):** What Terraform *thinks* exists (e.g., a `t2.micro`).
    3.  **The Real World (Actual State):** What AWS reports is *actually* running (e.g., a `t2.micro`).
    Terraform saw a difference between my desired state (code) and the recorded state, so it created a plan to update the resource from `t2.micro` to `t2.nano`.

---

### Deep Dive: A Line-by-Line Explanation of the Change
<a name="deep-dive-a-line-by-line-explanation-of-the-change"></a>
The change was just one line, but it triggered a complex series of events.

[Image of Terraform state file comparing desired vs. actual state]

```terraform
# Standard provider configuration block.
provider "aws" {
  region = "us-east-1"
}

# This is the resource block I edited.
resource "aws_instance" "nautilus-ec2" {
  
  ami           = "ami-0c101f26f147fa7fd"
  
  # This is the line I changed.
  # Terraform sees this 'instance_type' argument now has a new value.
  # It checks the AWS provider documentation and knows that changing
  # this argument on an existing instance requires a stop and a start.
  instance_type = "t2.nano"
  
  tags = {
    Name = "nautilus-ec2"
  }
}
```
When I ran `terraform apply`, Terraform communicated with the AWS API and performed the equivalent of me doing the following in the web console:
1.  Selecting the `nautilus-ec2` instance.
2.  Choosing "Instance State" -> "Stop instance".
3.  Waiting for it to stop.
4.  Choosing "Actions" -> "Instance Settings" -> "Change instance type".
5.  Selecting `t2.nano` and clicking "Apply".
6.  Choosing "Instance State" -> "Start instance".
Terraform automated this entire, multi-step, manual process with a single command.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting Downtime:** The biggest pitfall is assuming this change is instant. Modifying an instance's type requires a **reboot**, which means my application will have **downtime**. This is a critical consideration in a production environment.
-   **Incompatible Instance Types:** I can't just change to any type. For example, changing from an Intel-based instance to a new ARM-based (Graviton) instance would fail because the AMI is not compatible. The change must be within a compatible "family" of instances.
-   **Manually Changing the Server:** The biggest sin in an IaC workflow is to log into the AWS console and change the instance type manually. The next time I run `terraform plan`, Terraform will detect this **drift** and try to change it back to what's in the code, causing confusion and potential outages. The code must always be the single source of truth.

---

### Exploring the Essential Terraform Commands
<a name="exploring-the-essential-terraform-commands"></a>
-   `terraform init`: Initializes the directory, downloading providers.
-   `terraform plan`: **The most important command for this task.** It showed me a `~` (change) symbol instead of a `+` (create) symbol, which confirmed my understanding that Terraform would *update* the existing resource.
-   `terraform apply`: Executed the plan and performed the stop/modify/start operations.
-   `terraform state list`: A useful command to see all the resources Terraform is currently managing in its state file (e.g., `aws_instance.nautilus-ec2`).
-   `terraform state show 'aws_instance.nautilus-ec2'`: A very useful command to see all the attributes of a resource *as they are recorded in the state file*. I could have used this before my change to see `instance_type = "t2.micro"` and after my change to see `instance_type = "t2.nano"`.
   