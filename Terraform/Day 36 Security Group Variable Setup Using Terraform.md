# Terraform Level 1, Task 36: Provisioning a Security Group with Variables

Today's task was a key exercise in making my Terraform code cleaner and more professional. My objective was to create an AWS **Security Group**, but with a twist: the name of the Security Group had to be defined as an **input variable** in a separate file, rather than being hardcoded.

This reinforced the best practice of decoupling configuration (values) from logic (resource definitions). I created a `variables.tf` file to store my inputs and a `main.tf` file to use them. This document is my detailed, first-person guide to that process.

## Table of Contents
- [Terraform Level 1, Task 36: Provisioning a Security Group with Variables](#terraform-level-1-task-36-provisioning-a-security-group-with-variables)
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
My objective was to use Terraform to create a new AWS Security Group using a variable. The specific requirements were:
1.  Create a `variables.tf` file to define a variable named `KKE_sg`.
2.  Store the Security Group name `xfusion-sg` in this variable.
3.  Create a `main.tf` file to provision the Security Group.
4.  The `aws_security_group` resource in `main.tf` must use the `KKE_sg` variable to set its `Name` tag.
5.  The Terraform working directory was `/home/bob/terraform`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved creating two separate Terraform files and then running the standard workflow.

#### Phase 1: Writing the `variables.tf` File
In the `/home/bob/terraform` directory, I created my first file, `variables.tf`. This file's only job is to *define* the inputs my configuration will accept.
```terraform
# This block defines a new input variable for my configuration.
variable "KKE_sg" {
  description = "The name of the Security Group to be created."
  type        = string
  
  # I'm setting the default value here. This means if I run 'terraform apply'
  # without providing a value, it will automatically use "xfusion-sg".
  default     = "xfusion-sg"
}
```

#### Phase 2: Writing the `main.tf` File
Next, I created my `main.tf` file in the same directory. This file contains the logic and *refers* to the variable defined in the other file.
```terraform
# 1. Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Define the Security Group Resource
resource "aws_security_group" "xfusion_sg_resource" {
  name        = var.KKE_sg  # Using variable for the SG name
  description = "Security Group managed by Terraform"

  # The 'tags' block assigns a 'Name' tag to the Security Group.
  tags = {
    # This is the key to the task. Instead of hardcoding the name,
    # I am referencing the 'KKE_sg' variable using the 'var.' prefix.
    Name = var.KKE_sg
  }
}
```

#### Phase 3: The Terraform Workflow
From my terminal in the same directory, I executed the three core commands.
1.  **Initialize:** `terraform init`.
2.  **Plan:** `terraform plan`. The output showed me that Terraform would create one `aws_security_group` resource and that the `Name` tag (and the SG name) would be set to `xfusion-sg`, confirming it was correctly reading the default value from my `variables.tf` file.
3.  **Apply:** `terraform apply`. After I confirmed with `yes`, Terraform created the Security Group with the correct name.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Security Group:** An AWS Security Group acts as a virtual firewall for your EC2 instances to control incoming and outgoing traffic.
-   **Input Variables**: This is the core concept of this task. A variable is a way to define a value *outside* of your main resource logic, making your code **reusable** and **flexible**.
-   **Reusability**: Just like with the VPC task, this structure allows me to reuse the same `main.tf` to create different Security Groups just by changing the variable input.
-   **Separation of Concerns**: Keeping definitions (`variables.tf`) separate from logic (`main.tf`) is a software engineering best practice that keeps code organized and maintainable.

---

### Deep Dive: A Line-by-Line Explanation of My Terraform Files
<a name="deep-dive-a-line-by-line-explanation-of-my-terraform-files"></a>
This task reinforced how the two files work together.

[Image of Terraform variables feeding into main.tf]

#### `variables.tf` (The "Definition")
```terraform
# 'variable' defines the input.
# "KKE_sg" is the reference name.
variable "KKE_sg" {
  type    = string
  
  # 'default' is critical here. It holds the value "xfusion-sg" required by the task.
  default = "xfusion-sg"
}
```

#### `main.tf` (The "Implementation")
```terraform
provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "xfusion_sg_resource" {
  
  # I'm using the variable for the actual AWS resource name parameter.
  name = var.KKE_sg 

  tags = {
    # I'm ALSO using the variable for the 'Name' tag, which is what appears in the console UI.
    # 'var.KKE_sg' tells Terraform to look up the value "xfusion-sg".
    Name = var.KKE_sg
  }
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Undefined Variable:** Using `var.KKE_sg` in `main.tf` without defining `variable "KKE_sg"` in `variables.tf` will cause an error.
-   **Typo in Variable Name:** Variable references are case-sensitive. `var.kke_sg` would fail if the definition is `KKE_sg`.
-   **Missing Value:** If no `default` value is set and no input is provided at runtime, Terraform will interactively ask for the value, which breaks automated pipelines.

---

### Exploring the Essential Terraform Commands
<a name="exploring-the-essential-terraform-commands"></a>
-   `terraform init`: Initializes the directory and downloads providers.
-   `terraform plan`: shows a preview of the resources to be created, including the resolved values of variables.
-   `terraform apply`: Executes the plan.
-   `terraform apply -var="KKE_sg=new-sg-name"`: Allows overriding the default variable value from the command line.
   