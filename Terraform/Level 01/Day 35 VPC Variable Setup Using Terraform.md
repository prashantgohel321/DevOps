# Terraform Level 1, Task 35: Reusable Code with Input Variables

Today's task was a major step in making my Terraform code more professional, flexible, and reusable. My objective was to create an AWS VPC, but with a new requirement: the VPC's name had to be defined as an **input variable** in a separate file.

This was a fantastic lesson in decoupling my configuration (the "what," like a VPC name) from my logic (the "how," the `aws_vpc` resource block). I learned to create a `variables.tf` file to define my inputs and a `main.tf` file to consume them. This document is my detailed, first-person guide to that entire process, with a deep dive into the code and the core concepts of using variables in Terraform.

## Table of Contents
- [Terraform Level 1, Task 35: Reusable Code with Input Variables](#terraform-level-1-task-35-reusable-code-with-input-variables)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Writing the `variables.tf` File](#phase-1-writing-the-variablestf-file)
      - [Phase 2: Writing the `main.tf` File](#phase-2-writing-the-maintf-file)
      - [Phase 3: The Terraform Workflow](#phase-3-the-terraform-workflow)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: A Line-by-Line Explanation of My Terraform Files](#deep-dive-a-line-by-line-explanation-of-my-terraform-files)
      - [`variables.tf` (The "Definition")](#variablestf-the-definition)
      - [`main.tf` (The "Implementation")](#maintf-the-implementation)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the Essential Terraform Commands](#exploring-the-essential-terraform-commands)

---

### The Task
<a name="the-task"></a>
My objective was to use Terraform to create a new AWS VPC using a variable. The specific requirements were:
1.  Create a `variables.tf` file to define a variable named `KKE_vpc`.
2.  Store the VPC name `devops-vpc` in this variable.
3.  Create a `main.tf` file to provision the VPC.
4.  The `aws_vpc` resource in `main.tf` must use the `KKE_vpc` variable to set its `Name` tag.
5.  The VPC's CIDR block had to be `10.0.0.0/16`.
6.  The resources had to be created in the `us-east-1` region.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved creating two separate Terraform files and then running the standard workflow.

#### Phase 1: Writing the `variables.tf` File
In the `/home/bob/terraform` directory, I created my first file, `variables.tf`. This file's only job is to *define* the inputs my configuration will accept.
```terraform
# This block defines a new input variable for my configuration.
variable "KKE_vpc" {
  description = "The name of the VPC to be created."
  type        = string
  
  # I'm setting the default value here. This means if I run 'terraform apply'
  # without providing a value, it will automatically use "devops-vpc".
  default     = "devops-vpc"
}
```

#### Phase 2: Writing the `main.tf` File
Next, I created my `main.tf` file in the same directory. This file contains the logic and *refers* to the variable defined in the other file.
```terraform
# 1. Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Define the VPC Resource
resource "aws_vpc" "devops_vpc_resource" {
  cidr_block = "10.0.0.0/16"

  tags = {
    # This is the key to the task. Instead of hardcoding the name,
    # I am referencing the 'KKE_vpc' variable using the 'var.' prefix.
    Name = var.KKE_vpc
  }
}
```

#### Phase 3: The Terraform Workflow
From my terminal in the same directory, I executed the three core commands.
1.  **Initialize:** `terraform init`.
2.  **Plan:** `terraform plan`. The output showed me that Terraform would create one `aws_vpc` resource and that the `Name` tag would be set to `devops-vpc`, confirming it was correctly reading the default value from my `variables.tf` file.
3.  **Apply:** `terraform apply`. After I confirmed with `yes`, Terraform created the VPC with the correct name.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Input Variables**: This is the core concept of this task. A variable is a way to define a value *outside* of your main resource logic, making your code incredibly **reusable** and **flexible**.
-   **Reusability**: This is the biggest benefit. Now, I can use this same `main.tf` file to create a *different* VPC. For example, if I wanted to create a "prod-vpc," I wouldn't have to change my `main.tf` file at all. I would just run:
    `terraform apply -var="KKE_vpc=prod-vpc"`
    This command overrides the `default` value and runs the same logic with a new name, allowing me to create multiple VPCs from a single, clean template.
-   **Separation of Concerns**: This is a key software engineering principle.
    -   `main.tf` (The Logic): Contains the *how* (the `resource` blocks).
    -   `variables.tf` (The Data): Contains the *what* (the values to plug into the logic).
    This separation makes the code much cleaner, easier to read, and simpler to manage as it grows.
-   **`variables.tf` File**: This is a standard Terraform convention. While I *could* have put the `variable` block inside my `main.tf` file, it's a best practice to keep all variable definitions in their own dedicated `variables.tf` file for organization.

---

### Deep Dive: A Line-by-Line Explanation of My Terraform Files
<a name="deep-dive-a-line-by-line-explanation-of-my-terraform-files"></a>
This task showed me how the two files work together.

[Image of Terraform variables file feeding into main.tf]

#### `variables.tf` (The "Definition")
```terraform
# 'variable' is a special block type that defines an input variable.
# "KKE_vpc" is the name I'll use to reference it.
variable "KKE_vpc" {
  
  # 'description' is a best practice. It explains what the variable
  # is for, which is very helpful for my teammates.
  description = "The name of the VPC to be created."
  
  # 'type' is a constraint. It tells Terraform to only accept a 'string'
  # value. This prevents errors, like accidentally trying to use a number.
  type = string
  
  # 'default' is the value to use if no other value is provided.
  # This made my 'terraform apply' work without any extra flags.
  default = "devops-vpc"
}
```

#### `main.tf` (The "Implementation")
```terraform
# Standard provider configuration block.
provider "aws" {
  region = "us-east-1"
}

# This resource block defines my VPC.
resource "aws_vpc" "devops_vpc_resource" {
  
  # This argument is hardcoded because the task said to use this CIDR.
  cidr_block = "10.0.0.0/16"

  # The 'tags' block assigns a 'Name' tag to the VPC.
  tags = {
    
    # This is the variable reference. 'var.' is a special prefix
    # that tells Terraform to look up the value of the variable
    # named 'KKE_vpc', which it finds in 'variables.tf'.
    Name = var.KKE_vpc
  }
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Undefined Variable:** If I used `var.KKE_vpc` in `main.tf` but forgot to define it in `variables.tf`, the `terraform plan` would fail with an "Undefined variable" error.
-   **Typo in Variable Name:** The names must match exactly. If I defined `variable "KKE_vpc"` but used `var.KKE_VPC` (wrong case) in `main.tf`, it would also fail.
-   **Missing Value:** If I defined the variable but did **not** provide a `default` value, Terraform would stop during the `plan` or `apply` phase and *prompt me* to enter a value. This is fine for interactive use but bad for automation. Providing a `default` value (or a separate `terraform.tfvars` file) is the correct way.

---

### Exploring the Essential Terraform Commands
<a name="exploring-the-essential-terraform-commands"></a>
-   `terraform init`: Prepared my working directory and downloaded the `aws` provider plugin.
-   `terraform plan`: Read both `.tf` files, found the `default` value for `var.KKE_vpc`, and showed me a plan to create the VPC with the `Name` tag `devops-vpc`.
-   `terraform apply`: Executed the plan. Because I provided a `default` value, it ran non-interactively without prompting me for the variable.
-   `terraform apply -var="KKE_vpc=new-vpc-name"`: I didn't run this, but I learned this is how I would *override* the default value from the command line to create a VPC with a different name using the same code.
   