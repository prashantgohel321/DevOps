# Terraform Level 1, Task 37: Provisioning an Elastic IP with Variables

Today's task was another great exercise in decoupling configuration from resource logic. My objective was to create an AWS **Elastic IP (EIP)**, but with the specific requirement that its name (tag) be defined as an **input variable** in a separate file.

This reinforces the Terraform best practice of using `variables.tf` for inputs and `main.tf` for resource definitions. This document is my detailed, first-person guide to that process.

## Table of Contents
- [Terraform Level 1, Task 37: Provisioning an Elastic IP with Variables](#terraform-level-1-task-37-provisioning-an-elastic-ip-with-variables)
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
My objective was to use Terraform to create a new AWS Elastic IP using a variable. The specific requirements were:
1.  Create a `variables.tf` file to define a variable named `KKE_eip`.
2.  Store the Elastic IP name `nautilus-eip` in this variable.
3.  Create a `main.tf` file to provision the Elastic IP.
4.  The `aws_eip` resource in `main.tf` must use the `KKE_eip` variable to set its `Name` tag.
5.  The Terraform working directory was `/home/bob/terraform`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved creating two separate Terraform files and then running the standard workflow.

#### Phase 1: Writing the `variables.tf` File
In the `/home/bob/terraform` directory, I created my first file, `variables.tf`. This file's only job is to *define* the inputs my configuration will accept.
```terraform
# This block defines a new input variable for my configuration.
variable "KKE_eip" {
  description = "The name tag for the Elastic IP."
  type        = string
  
  # I'm setting the default value here. This means if I run 'terraform apply'
  # without providing a value, it will automatically use "nautilus-eip".
  default     = "nautilus-eip"
}
```

#### Phase 2: Writing the `main.tf` File
Next, I created my `main.tf` file in the same directory. This file contains the logic and *refers* to the variable defined in the other file.
```terraform
# 1. Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Define the Elastic IP Resource
resource "aws_eip" "nautilus_eip_resource" {
  # Elastic IPs usually need to be in a VPC
  domain = "vpc"

  # The 'tags' block assigns a 'Name' tag to the EIP.
  tags = {
    # This is the key to the task. Instead of hardcoding the name,
    # I am referencing the 'KKE_eip' variable using the 'var.' prefix.
    Name = var.KKE_eip
  }
}
```

#### Phase 3: The Terraform Workflow
From my terminal in the same directory, I executed the three core commands.
1.  **Initialize:** `terraform init`.
2.  **Plan:** `terraform plan`. The output showed me that Terraform would create one `aws_eip` resource and that the `Name` tag would be set to `nautilus-eip`, confirming it was correctly reading the default value from my `variables.tf` file.
3.  **Apply:** `terraform apply`. After I confirmed with `yes`, Terraform allocated the Elastic IP with the correct name tag.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Elastic IP (EIP):** An Elastic IP address is a static IPv4 address designed for dynamic cloud computing. It allows you to mask the failure of an instance or software by rapidly remapping the address to another instance in your account.
-   **Input Variables**: This is the core concept of this task. A variable is a way to define a value *outside* of your main resource logic, making your code **reusable** and **flexible**.
-   **Reusability**: This structure allows me to reuse the same `main.tf` to create different EIPs (e.g., for different environments like dev, staging, prod) just by changing the variable input, without touching the code itself.
-   **Separation of Concerns**: Keeping definitions (`variables.tf`) separate from logic (`main.tf`) is a software engineering best practice that keeps code organized and maintainable.

---

### Deep Dive: A Line-by-Line Explanation of My Terraform Files
<a name="deep-dive-a-line-by-line-explanation-of-my-terraform-files"></a>
This task reinforced how the two files work together.

[Image of Terraform variables referencing main.tf]

#### `variables.tf` (The "Definition")
```terraform
# 'variable' defines the input.
# "KKE_eip" is the reference name I'll use in main.tf.
variable "KKE_eip" {
  type    = string
  
  # 'default' is critical here. It holds the value "nautilus-eip" required by the task.
  default = "nautilus-eip"
}
```

#### `main.tf` (The "Implementation")
```terraform
provider "aws" {
  region = "us-east-1"
}

resource "aws_eip" "nautilus_eip_resource" {
  
  # domain = "vpc" is the modern way to specify a VPC EIP (replacing vpc = true)
  domain = "vpc" 

  tags = {
    # I'm using the variable for the 'Name' tag, which is what appears in the console UI.
    # 'var.KKE_eip' tells Terraform to look up the value "nautilus-eip".
    Name = var.KKE_eip
  }
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Undefined Variable:** Using `var.KKE_eip` in `main.tf` without defining `variable "KKE_eip"` in `variables.tf` will cause an error.
-   **Typo in Variable Name:** Variable references are case-sensitive. `var.kke_eip` would fail if the definition is `KKE_eip`.
-   **Missing Value:** If no `default` value is set and no input is provided at runtime, Terraform will interactively ask for the value, which breaks automated pipelines.

---

### Exploring the Essential Terraform Commands
<a name="exploring-the-essential-terraform-commands"></a>
-   `terraform init`: Initializes the directory and downloads providers.
-   `terraform plan`: Shows a preview of the resources to be created, including the resolved values of variables.
-   `terraform apply`: Executes the plan.
-   `terraform apply -var="KKE_eip=new-eip-name"`: Allows overriding the default variable value from the command line.
   