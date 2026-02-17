# Terraform Level 1, Task 38: Provisioning an IAM User with Variables

Today's task was another excellent practice in making Terraform configurations reusable and professional. My objective was to create an AWS **IAM User**, but with the specific requirement that the username be defined as an **input variable** in a separate file.

This reinforces the modular approach to Infrastructure as Code: defining *what* you want (variables) separately from *how* you build it (resources). This document is my detailed, first-person guide to that process.

## Table of Contents
- [Terraform Level 1, Task 38: Provisioning an IAM User with Variables](#terraform-level-1-task-38-provisioning-an-iam-user-with-variables)
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
My objective was to use Terraform to create a new AWS IAM User using a variable. The specific requirements were:
1.  Create a `variables.tf` file to define a variable named `KKE_user`.
2.  Store the IAM User name `iamuser_kirsty` in this variable.
3.  Create a `main.tf` file to provision the IAM User.
4.  The `aws_iam_user` resource in `main.tf` must use the `KKE_user` variable to set its `name` argument.
5.  The Terraform working directory was `/home/bob/terraform`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved creating two separate Terraform files and then running the standard workflow.

#### Phase 1: Writing the `variables.tf` File
In the `/home/bob/terraform` directory, I created my first file, `variables.tf`. This file's only job is to *define* the inputs my configuration will accept.
```terraform
# This block defines a new input variable for my configuration.
variable "KKE_user" {
  description = "The name of the IAM User to be created."
  type        = string
  
  # I'm setting the default value here. This means if I run 'terraform apply'
  # without providing a value, it will automatically use "iamuser_kirsty".
  default     = "iamuser_kirsty"
}
```

#### Phase 2: Writing the `main.tf` File
Next, I created my `main.tf` file in the same directory. This file contains the logic and *refers* to the variable defined in the other file.
```terraform
# 1. Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Define the IAM User Resource
resource "aws_iam_user" "kirsty_user_resource" {
  # This is the key to the task. Instead of hardcoding the name "iamuser_kirsty",
  # I am referencing the 'KKE_user' variable using the 'var.' prefix.
  name = var.KKE_user

  tags = {
    Name = var.KKE_user
  }
}
```

#### Phase 3: The Terraform Workflow
From my terminal in the same directory, I executed the three core commands.
1.  **Initialize:** `terraform init`.
2.  **Plan:** `terraform plan`. The output showed me that Terraform would create one `aws_iam_user` resource and that its name would be `iamuser_kirsty`, confirming it was correctly reading the default value from my `variables.tf` file.
3.  **Apply:** `terraform apply`. After I confirmed with `yes`, Terraform created the user with the correct name.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **IAM User:** An IAM User is an entity that you create in AWS to represent the person or application that uses it to interact with AWS.
-   **Input Variables**: This is the core concept of this task. A variable is a way to define a value *outside* of your main resource logic, making your code **reusable** and **flexible**.
-   **Reusability**: This structure allows me to reuse the same `main.tf` to create hundreds of different users just by changing the variable input, without touching the code itself.
-   **Separation of Concerns**: Keeping definitions (`variables.tf`) separate from logic (`main.tf`) is a software engineering best practice that keeps code organized and maintainable.

---

### Deep Dive: A Line-by-Line Explanation of My Terraform Files
<a name="deep-dive-a-line-by-line-explanation-of-my-terraform-files"></a>
This task reinforced how the two files work together.



#### `variables.tf` (The "Definition")
```terraform
# 'variable' defines the input.
# "KKE_user" is the reference name I'll use in main.tf.
variable "KKE_user" {
  type    = string
  
  # 'default' is critical here. It holds the value "iamuser_kirsty" required by the task.
  default = "iamuser_kirsty"
}
```

#### `main.tf` (The "Implementation")
```terraform
provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_user" "kirsty_user_resource" {
  
  # I'm using the variable for the actual AWS resource name parameter.
  # 'var.KKE_user' tells Terraform to look up the value "iamuser_kirsty".
  name = var.KKE_user 

  tags = {
    # I'm also tagging it with the name for easier identification in the console.
    Name = var.KKE_user
  }
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Undefined Variable:** Using `var.KKE_user` in `main.tf` without defining `variable "KKE_user"` in `variables.tf` will cause an error.
-   **Typo in Variable Name:** Variable references are case-sensitive. `var.kke_user` would fail if the definition is `KKE_user`.
-   **Missing Value:** If no `default` value is set and no input is provided at runtime, Terraform will interactively ask for the value, which breaks automated pipelines.

---

### Exploring the Essential Terraform Commands
<a name="exploring-the-essential-terraform-commands"></a>
-   `terraform init`: Initializes the directory and downloads providers.
-   `terraform plan`: Shows a preview of the resources to be created, including the resolved values of variables.
-   `terraform apply`: Executes the plan.
-   `terraform apply -var="KKE_user=new-user-name"`: Allows overriding the default variable value from the command line.
    