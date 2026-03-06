# Terraform Level 1, Task 39: Provisioning an IAM Role with Variables

Today's task was another excellent practice in making Terraform configurations reusable and professional. My objective was to create an AWS **IAM Role**, but with the specific requirement that the role name be defined as an **input variable** in a separate file.

This reinforces the modular approach to Infrastructure as Code: defining *what* you want (variables) separately from *how* you build it (resources). This document is my detailed, first-person guide to that process.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: A Line-by-Line Explanation of My Terraform Files](#deep-dive-a-line-by-line-explanation-of-my-terraform-files)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Essential Terraform Commands](#exploring-the-essential-terraform-commands)

---

### The Task
<a name="the-task"></a>
My objective was to use Terraform to create a new AWS IAM Role using a variable. The specific requirements were:
1.  Create a `variables.tf` file to define a variable named `KKE_iamrole`.
2.  Store the IAM Role name `iamrole_ammar` in this variable.
3.  Create a `main.tf` file to provision the IAM Role.
4.  The `aws_iam_role` resource in `main.tf` must use the `KKE_iamrole` variable to set its `name` argument.
5.  The Terraform working directory was `/home/bob/terraform`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved creating two separate Terraform files and then running the standard workflow.

#### Phase 1: Writing the `variables.tf` File
In the `/home/bob/terraform` directory, I created my first file, `variables.tf`. This file's only job is to *define* the inputs my configuration will accept.
```terraform
# This block defines a new input variable for my configuration.
variable "KKE_iamrole" {
  description = "The name of the IAM Role to be created."
  type        = string
  
  # I'm setting the default value here. This means if I run 'terraform apply'
  # without providing a value, it will automatically use "iamrole_ammar".
  default     = "iamrole_ammar"
}
```

#### Phase 2: Writing the `main.tf` File
Next, I created my `main.tf` file in the same directory. This file contains the logic and *refers* to the variable defined in the other file. I also included a basic `assume_role_policy` since IAM roles require one.
```terraform
# 1. Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Define the IAM Role Resource
resource "aws_iam_role" "ammar_role_resource" {
  # This is the key to the task. Instead of hardcoding the name "iamrole_ammar",
  # I am referencing the 'KKE_iamrole' variable using the 'var.' prefix.
  name = var.KKE_iamrole

  # IAM Roles MUST have an Assume Role Policy (Trust Policy).
  # This JSON defines WHO can assume this role. Here, I'm allowing EC2 instances.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = var.KKE_iamrole
  }
}
```

#### Phase 3: The Terraform Workflow
From my terminal in the same directory, I executed the three core commands.
1.  **Initialize:** `terraform init`.
2.  **Plan:** `terraform plan`. The output showed me that Terraform would create one `aws_iam_role` resource and that its name would be `iamrole_ammar`, confirming it was correctly reading the default value from my `variables.tf` file.
3.  **Apply:** `terraform apply`. After I confirmed with `yes`, Terraform created the role with the correct name.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **IAM Role:** An IAM Role is an identity with permission policies that determine what the identity can and cannot do in AWS. Unlike a user, a role isn't associated with a specific person. It is intended to be assumable by anyone who needs it.
-   **Input Variables**: This is the core concept of this task. A variable is a way to define a value *outside* of your main resource logic, making your code **reusable** and **flexible**.
-   **Reusability**: This structure allows me to reuse the same `main.tf` to create hundreds of different roles just by changing the variable input, without touching the code itself.
-   **Separation of Concerns**: Keeping definitions (`variables.tf`) separate from logic (`main.tf`) is a software engineering best practice that keeps code organized and maintainable.

---

### Deep Dive: A Line-by-Line Explanation of My Terraform Files
<a name="deep-dive-a-line-by-line-explanation-of-my-terraform-files"></a>
This task reinforced how the two files work together.

[Image of Terraform variables referencing main.tf]

#### `variables.tf` (The "Definition")
```terraform
# 'variable' defines the input.
# "KKE_iamrole" is the reference name I'll use in main.tf.
variable "KKE_iamrole" {
  type    = string
  
  # 'default' is critical here. It holds the value "iamrole_ammar" required by the task.
  default = "iamrole_ammar"
}
```

#### `main.tf` (The "Implementation")
```terraform
provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "ammar_role_resource" {
  
  # I'm using the variable for the actual AWS resource name parameter.
  # 'var.KKE_iamrole' tells Terraform to look up the value "iamrole_ammar".
  name = var.KKE_iamrole 

  assume_role_policy = jsonencode({
      # ... (Standard Trust Policy) ...
  })

  tags = {
    # I'm also tagging it with the name for easier identification in the console.
    Name = var.KKE_iamrole
  }
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Undefined Variable:** Using `var.KKE_iamrole` in `main.tf` without defining `variable "KKE_iamrole"` in `variables.tf` will cause an error.
-   **Typo in Variable Name:** Variable references are case-sensitive. `var.kke_iamrole` would fail if the definition is `KKE_iamrole`.
-   **Missing Assume Role Policy:** Unlike Users or Groups, creating an IAM Role **requires** an `assume_role_policy` argument. The resource creation will fail without it.

---

### Exploring the Essential Terraform Commands
<a name="exploring-the-essential-terraform-commands"></a>
-   `terraform init`: Initializes the directory and downloads providers.
-   `terraform plan`: Shows a preview of the resources to be created, including the resolved values of variables.
-   `terraform apply`: Executes the plan.
-   `terraform apply -var="KKE_iamrole=new-role-name"`: Allows overriding the default variable value from the command line.
   