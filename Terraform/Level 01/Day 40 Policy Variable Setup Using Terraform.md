# Terraform Level 1, Task 40: Provisioning an IAM Policy with Variables

Today's task was the final exercise in this series of Terraform variables tasks. My objective was to create an AWS **IAM Policy**, with the specific requirement that the policy name be defined as an **input variable** in a separate file.

This reinforces the modular approach to Infrastructure as Code: defining *what* you want (variables) separately from *how* you build it (resources). This document is my detailed, first-person guide to that process.

## Table of Contents
- [Terraform Level 1, Task 40: Provisioning an IAM Policy with Variables](#terraform-level-1-task-40-provisioning-an-iam-policy-with-variables)
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
My objective was to use Terraform to create a new AWS IAM Policy using a variable. The specific requirements were:
1.  Create a `variables.tf` file to define a variable named `KKE_iampolicy`.
2.  Store the IAM Policy name `iampolicy_rose` in this variable.
3.  Create a `main.tf` file to provision the IAM Policy.
4.  The `aws_iam_policy` resource in `main.tf` must use the `KKE_iampolicy` variable to set its `name` argument.
5.  The Terraform working directory was `/home/bob/terraform`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved creating two separate Terraform files and then running the standard workflow.

#### Phase 1: Writing the `variables.tf` File
In the `/home/bob/terraform` directory, I created my first file, `variables.tf`. This file's only job is to *define* the inputs my configuration will accept.
```terraform
# This block defines a new input variable for my configuration.
variable "KKE_iampolicy" {
  description = "The name of the IAM Policy to be created."
  type        = string
  
  # I'm setting the default value here. This means if I run 'terraform apply'
  # without providing a value, it will automatically use "iampolicy_rose".
  default     = "iampolicy_rose"
}
```

#### Phase 2: Writing the `main.tf` File
Next, I created my `main.tf` file in the same directory. This file contains the logic and *refers* to the variable defined in the other file. I included a standard JSON policy document to make the resource valid.
```terraform
# 1. Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Define the IAM Policy Resource
resource "aws_iam_policy" "rose_policy_resource" {
  # This is the key to the task. Instead of hardcoding the name "iampolicy_rose",
  # I am referencing the 'KKE_iampolicy' variable using the 'var.' prefix.
  name        = var.KKE_iampolicy
  description = "IAM policy created via Terraform with variables"

  # IAM Policies require a JSON document defining the permissions.
  # This is a basic policy allowing read-only access to EC2.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:Describe*"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
```

#### Phase 3: The Terraform Workflow
From my terminal in the same directory, I executed the three core commands.
1.  **Initialize:** `terraform init`.
2.  **Plan:** `terraform plan`. The output showed me that Terraform would create one `aws_iam_policy` resource and that its name would be `iampolicy_rose`, confirming it was correctly reading the default value from my `variables.tf` file.
3.  **Apply:** `terraform apply`. After I confirmed with `yes`, Terraform created the policy with the correct name.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **IAM Policy:** An IAM Policy is a document that defines permissions. It can be attached to users, groups, or roles to grant them the ability to perform actions in AWS.
-   **Input Variables**: This is the core concept of this task. A variable is a way to define a value *outside* of your main resource logic, making your code **reusable** and **flexible**.
-   **Reusability**: This structure allows me to reuse the same `main.tf` to create many different policies just by changing the variable input, without touching the code itself.
-   **Separation of Concerns**: Keeping definitions (`variables.tf`) separate from logic (`main.tf`) is a software engineering best practice that keeps code organized and maintainable.

---

### Deep Dive: A Line-by-Line Explanation of My Terraform Files
<a name="deep-dive-a-line-by-line-explanation-of-my-terraform-files"></a>
This task reinforced how the two files work together.



#### `variables.tf` (The "Definition")
```terraform
# 'variable' defines the input.
# "KKE_iampolicy" is the reference name I'll use in main.tf.
variable "KKE_iampolicy" {
  type    = string
  
  # 'default' is critical here. It holds the value "iampolicy_rose" required by the task.
  default = "iampolicy_rose"
}
```

#### `main.tf` (The "Implementation")
```terraform
provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_policy" "rose_policy_resource" {
  
  # I'm using the variable for the actual AWS resource name parameter.
  # 'var.KKE_iampolicy' tells Terraform to look up the value "iampolicy_rose".
  name = var.KKE_iampolicy 

  policy = jsonencode({
      # ... (Standard Policy Document) ...
  })
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Undefined Variable:** Using `var.KKE_iampolicy` in `main.tf` without defining `variable "KKE_iampolicy"` in `variables.tf` will cause an error.
-   **Typo in Variable Name:** Variable references are case-sensitive. `var.kke_iampolicy` would fail if the definition is `KKE_iampolicy`.
-   **Missing Policy Document:** Creating an `aws_iam_policy` resource requires a `policy` argument containing valid JSON. The resource creation will fail without it.

---

### Exploring the Essential Terraform Commands
<a name="exploring-the-essential-terraform-commands"></a>
-   `terraform init`: Initializes the directory and downloads providers.
-   `terraform plan`: Shows a preview of the resources to be created, including the resolved values of variables.
-   `terraform apply`: Executes the plan.
-   `terraform apply -var="KKE_iampolicy=new-policy-name"`: Allows overriding the default variable value from the command line.
   