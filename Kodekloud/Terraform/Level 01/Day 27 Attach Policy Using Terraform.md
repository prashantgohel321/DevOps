# Terraform Level 1, Task 27: Attaching an IAM Policy to a User

Today's task was a crucial lesson in AWS security, and it was the logical conclusion to the previous IAM tasks. Before, I had created an IAM User and an IAM Policy separately. This task taught me how to **attach** the policy to the user, which is the step that actually grants the permissions.

My objective was to use Terraform to link an existing policy (`iampolicy_mariyam`) to an existing user (`iamuser_mariyam`). This was a fantastic exercise in managing the *relationships* between resources as code. This document is my very detailed, first-person guide to that entire process, with a deep dive into the code and the concept of "attachment" resources.

## Table of Contents
- [Terraform Level 1, Task 27: Attaching an IAM Policy to a User](#terraform-level-1-task-27-attaching-an-iam-policy-to-a-user)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Writing the Code](#phase-1-writing-the-code)
      - [Phase 2: The Terraform Workflow](#phase-2-the-terraform-workflow)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: A Line-by-Line Explanation of My `main.tf` Script](#deep-dive-a-line-by-line-explanation-of-my-maintf-script)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the Essential Terraform Commands](#exploring-the-essential-terraform-commands)

---

### The Task
<a name="the-task"></a>
My objective was to use Terraform to attach an existing IAM policy to an existing IAM user. The requirements were:
1.  All code had to be in a single `main.tf` file.
2.  The target IAM User was `iamuser_mariyam`.
3.  The target IAM Policy was `iampolicy_mariyam`.
4.  The resources were in the `us-east-1` region.
5.  I had to **update** the `main.tf` file to create this attachment.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved updating the existing `main.tf` file to add a new "attachment" resource that would link the other two resources.

#### Phase 1: Writing the Code
In the `/home/bob/terraform` directory, I opened the `main.tf` file provided by the lab. It already contained the `aws_iam_user` and `aws_iam_policy` resources. I added the new `aws_iam_user_policy_attachment` resource block to the end of the file.

```terraform
# (Provider block was in a separate provider.tf file)

# This block was already provided in main.tf
resource "aws_iam_user" "user" {
  name = "iamuser_mariyam"

  tags = {
    Name = "iamuser_mariyam"
  }
}

# This block was also provided in main.tf
resource "aws_iam_policy" "policy" {
  name        = "iampolicy_mariyam"
  description = "IAM policy allowing EC2 read actions for mariyam"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ec2:Read*"],
        Resource = "*"
      }
    ]
  })
}

# This is the new resource block I added to solve the task.
# It creates the link between the user and the policy.
resource "aws_iam_user_policy_attachment" "policy_attachment" {
  user       = aws_iam_user.user.name
  policy_arn = aws_iam_policy.policy.arn
}
```

#### Phase 2: The Terraform Workflow
From my terminal in the same directory, I executed the three core commands.
1.  **Initialize:** `terraform init`.
2.  **Plan:** `terraform plan`. The output was very clear. It showed `Plan: 3 to add, 0 to change, 0 to destroy.`. This confirmed Terraform would create the user, the policy, and the attachment all at once.
3.  **Apply:** `terraform apply`. After I confirmed with `yes`, Terraform executed the plan. It intelligently created the user and policy first, and then, once it had their attributes, it created the attachment. The success message confirmed the task was done.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **IAM (Identity and Access Management):** This is the core AWS service for managing users and permissions.
-   **IAM User:** This is the **"Who"**. It's the identity of the person or application.
-   **IAM Policy:** This is the **"What"**. It's a JSON document that defines a set of permissions (e.g., "Allow `ec2:Describe*`").
-   **The "Attachment" (The Core Lesson):** An IAM user and an IAM policy are useless on their own. They are like a person and a keycard. The person can't do anything until the keycard is programmed and given to them. The **`aws_iam_user_policy_attachment`** resource is the act of *giving the keycard to the person*. It's the "glue" resource that links the "Who" (the user) to the "What" (the policy).
-   **Implicit Dependencies:** This was the most important concept in this task. By referencing the other resources, Terraform automatically knew the correct order of operations. It understood it couldn't create the attachment until the user and the policy already existed.

---

### Deep Dive: A Line-by-Line Explanation of My `main.tf` Script
<a name="deep-dive-a-line-by-line-explanation-of-my-main.tf-script"></a>
This script shows how to build and connect a complete set of IAM resources.

[Image of an IAM Policy being attached to an IAM User]

```terraform
# This resource block defines the IAM user.
# "aws_iam_user" is the Resource TYPE.
# "user" is the local NAME I use to refer to this user.
resource "aws_iam_user" "user" {
  name = "iamuser_mariyam"
  # ...
}

# This resource block defines the permissions document.
# "aws_iam_policy" is the Resource TYPE.
# "policy" is the local NAME.
resource "aws_iam_policy" "policy" {
  name   = "iampolicy_mariyam"
  policy = jsonencode({
    # ... (JSON policy data) ...
  })
}

# This is the resource block I added. It creates the link.
# "aws_iam_user_policy_attachment" is the Resource TYPE.
# "policy_attachment" is the local NAME.
resource "aws_iam_user_policy_attachment" "policy_attachment" {
  
  # This argument requires the name of the user.
  # I'm dynamically pulling the 'name' attribute from the 'aws_iam_user'
  # resource that I named "user".
  user = aws_iam_user.user.name
  
  # This argument requires the ARN (Amazon Resource Name) of the policy.
  # I'm dynamically pulling the 'arn' attribute from the 'aws_iam_policy'
  # resource that I named "policy".
  policy_arn = aws_iam_policy.policy.arn
}
```
Because of the `aws_iam_user.user.name` and `aws_iam_policy.policy.arn` references, Terraform automatically creates an implicit dependency. It knows it must create the user and the policy *before* it can create the attachment.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting the Attachment:** A common mistake is to create both the user and the policy in the same file but forget to add the `aws_iam_user_policy_attachment` resource. In this case, no permissions would actually be granted.
-   **Using `data` vs. `resource`:** The task had me create the user and policy from scratch, so I used `resource` blocks. If the user and policy *already existed* in the AWS account, I would have used `data` blocks to look up their information instead.
-   **Policy ARN vs. Name:** The `aws_iam_user_policy_attachment` resource specifically requires the `policy_arn` (Amazon Resource Name) of the policy, not just its name. By referencing `aws_iam_policy.policy.arn`, I ensure I'm providing the correct, unique identifier.

---

### Exploring the Essential Terraform Commands
<a name="exploring-the-essential-terraform-commands"></a>
-   `terraform init`: Prepared my working directory by downloading the `aws` provider plugin.
-   `terraform plan`: The "dry run" command. It showed me a plan to add 3 new resources and correctly identified the implicit dependencies.
-   `terraform apply`: Executed the plan and created all three resources in the correct order after I confirmed with `yes`.
-   `terraform state list`: After the apply, this command would list all three resources that Terraform is now managing: `aws_iam_user.user`, `aws_iam_policy.policy`, and `aws_iam_user_policy_attachment.policy_attachment`.
-   `terraform destroy`: The command to destroy all three of these resources, which it would also do in the correct order (destroying the attachment before the user or policy).
   