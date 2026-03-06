# Terraform Level 1, Task 1: My First Step into Infrastructure as Code

Today was a major milestone in my DevOps journey. I moved away from manually clicking buttons in a cloud console and took my first step into the world of **Infrastructure as Code (IaC)** using Terraform. The task was simple—create an AWS EC2 Key Pair—but the concepts behind it are powerful and transformative.

I learned how to declare my desired infrastructure in a simple code file and use the core Terraform workflow (`init`, `plan`, `apply`) to make it a reality. I even ran into my first common error and learned how to debug it. This document is my detailed log of that entire experience, written for a complete beginner like myself.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [My First Failure: The "Duplicate provider" Error](#my-first-failure-the-duplicate-provider-error)
- [Why Did I Do This? (The "What & Why" of Terraform)](#why-did-i-do-this-the-what--why-of-terraform)
- [Deep Dive: Decoding My First Terraform Script](#deep-dive-decoding-my-first-terraform-script)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to create an AWS EC2 Key Pair using Terraform. The specific requirements were:
1.  The Terraform code had to be in a single file named `main.tf` inside the `/home/bob/terraform` directory.
2.  The key pair's name in AWS had to be `nautilus-kp`.
3.  The key had to be of type `rsa`.
4.  The generated private key file had to be saved locally on the machine at `/home/bob/nautilus-kp.pem`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process was a clear, three-phase workflow: write the code, execute the plan, and verify the result.

#### Phase 1: Writing the Code
Inside the `/home/bob/terraform` directory, I created a file named `main.tf` and wrote the following code. This code is declarative—it describes the *end state* I want, not the steps to get there.

```terraform
# 1. Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Generate a new private key locally
resource "tls_private_key" "nautilus_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 3. Create the key pair resource in AWS using the public key
resource "aws_key_pair" "nautilus_key_pair" {
  key_name   = "nautilus-kp"
  public_key = tls_private_key.nautilus_rsa.public_key_openssh
}

# 4. Save the generated private key to a local file
resource "local_file" "private_key_pem" {
  content         = tls_private_key.nautilus_rsa.private_key_pem
  filename        = "/home/bob/nautilus-kp.pem"
  file_permission = "0400" # Read-only for my user
}
```

#### Phase 2: The Terraform Workflow
In the terminal, from the `/home/bob/terraform` directory, I executed the three core commands.

1.  **Initialize:** This command prepares the directory for work by downloading the plugins for the providers I declared (AWS, TLS, and Local).
    ```bash
    terraform init
    ```

2.  **Plan:** This command is a "dry run." It showed me exactly what Terraform was going to create before it made any changes to my infrastructure. This is an essential safety step.
    ```bash
    terraform plan
    ```

3.  **Apply:** This command executes the plan. Terraform showed me the plan one more time and asked for confirmation.
    ```bash
    terraform apply
    ```
    I typed `yes` and hit Enter. Terraform then connected to AWS and created the resources.

#### Phase 3: Verification
The final and most satisfying step was to verify that the private key file was created as requested.
```bash
ls -l /home/bob/nautilus-kp.pem
```
Seeing the file in the output was the proof of success.

---

### My First Failure: The "Duplicate provider" Error
<a name="my-first-failure-the-duplicate-provider-error"></a>
My first attempt at running `terraform init` failed with an error:
`Error: Duplicate provider configuration`
`A default ... provider configuration for "aws" was already given at main.tf ...`

-   **Diagnosis:** The error message was incredibly helpful. It told me that I had defined the `provider "aws"` block in two separate files (`main.tf` and `provider.tf`). Terraform reads all `.tf` files in a directory as one big configuration, so it saw two conflicting definitions for the same thing.
-   **Solution:** The fix was simple. I deleted the extra file (`rm provider.tf`) and kept all my code in the `main.tf` file as the task required. After that, `terraform init` worked perfectly. This taught me that a Terraform configuration in a directory is a collection of all `.tf` files within it.

---

### Why Did I Do This? (The "What & Why" of Terraform)
<a name="why-did-i-do-this-the-what--why"></a>
-   **Infrastructure as Code (IaC):** This is the core concept. Instead of manually creating resources through a web UI, I am defining them in code. This brings all the benefits of software development to my infrastructure:
    -   **Automation:** I can create, update, and destroy my entire infrastructure with a few commands.
    -   **Version Control:** I can check my `.tf` files into Git, track every change, and collaborate with a team.
    -   **Reproducibility:** I can use this same code to create an identical environment for testing, staging, or production, eliminating the "it works on my machine" problem.
-   **Terraform:** This is the specific tool I used. It's an open-source IaC tool that is cloud-agnostic, meaning I can use it to manage infrastructure on AWS, Azure, Google Cloud, and many other platforms.
-   **Providers:** A "provider" is a plugin that teaches Terraform how to interact with a specific API. In my script, I used three:
    -   **`aws`**: Knows how to talk to the AWS API to create resources like key pairs.
    -   **`tls`**: A utility provider that can perform cryptographic tasks, like generating an RSA key.
    -   **`local`**: A utility provider that can interact with the local filesystem, like creating the `.pem` file.

---

### Deep Dive: Decoding My First Terraform Script
<a name="deep-dive-decoding-my-first-terraform-script"></a>
For a beginner, the Terraform code can look a bit magical. Here's my breakdown of what each piece does.



```terraform
# This is a provider block. It configures the "aws" provider.
# All resources that start with "aws_" will use this configuration.
provider "aws" {
  region = "us-east-1" # Sets the default AWS region for my resources.
}

# This is a resource block. It defines a piece of infrastructure.
# "tls_private_key" is the TYPE of resource.
# "nautilus_rsa" is the NAME I give it within my Terraform code.
resource "tls_private_key" "nautilus_rsa" {
  # These are the arguments, or settings, for this resource.
  algorithm = "RSA"
  rsa_bits  = 4096
}

# This is another resource block.
# Its type is "aws_key_pair" and its local name is "nautilus_key_pair".
resource "aws_key_pair" "nautilus_key_pair" {
  key_name   = "nautilus-kp" # The name of the key as it will appear in AWS.

  # This is the magic of Terraform! I'm referencing an output from another resource.
  # Terraform is smart enough to know it must create the tls_private_key first
  # to get its public_key_openssh value, and then pass it to this resource.
  public_key = tls_private_key.nautilus_rsa.public_key_openssh
}

# A third resource block to handle local file creation.
resource "local_file" "private_key_pem" {
  # Here I'm referencing the private key content from the tls resource.
  content  = tls_private_key.nautilus_rsa.private_key_pem
  filename = "/home/bob/nautilus-kp.pem" # The destination file path.
  file_permission = "0400" # Sets file permissions to be secure (read-only for the owner).
}
```

### Common Pitfalls
<a name="common-pitfalls"></a>

- **Forgetting terraform init**: A very common mistake is to write code and immediately run `plan` or `apply`. This will fail because Terraform doesn't have the necessary provider plugins downloaded yet.

- **Syntax Errors**: Since this is code, a missing quote or brace will cause a syntax error. Running terraform validate is a good way to check your code before running a `plan`.

- **Duplicate Definitions**: As I discovered, defining the same provider or resource twice in the same directory will cause a conflict.

Exploring the Commands Used
<a name="exploring-the-commands-used"></a>

- **`terraform init`**: Initializes the working directory. This is the first command you must run in any new Terraform project. It downloads providers and sets up the backend state.

- **`terraform plan`**: Creates an execution plan. Terraform determines what actions are needed to achieve the desired state defined in the code and shows you a summary. It's a "dry run."

- **`terraform apply`**: Applies the changes required to reach the desired state. This is the command that actually creates, updates, or deletes your infrastructure. It will ask for confirmation before proceeding.

- **`rm provider.tf`**: The standard Linux command I used to remove the duplicate file that was causing my initialization error.