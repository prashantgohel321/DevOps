# Terraform Level 1, Task 16: Defining Permissions as Code with IAM Policies

Today's task was a deep dive into the heart of cloud security: defining permissions. After creating IAM users and groups, the logical next step was to create an **IAM Policy**. This is the document that actually defines *what* a user or group is allowed to do.

My objective was to use Terraform to create a policy that grants read-only access to AWS EC2. This was a fantastic exercise because it introduced me to writing JSON policy documents and embedding them within my Terraform code. It's the ultimate expression of "Security as Code." This document is my very detailed, first-person guide to that entire process.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: A Line-by-Line Explanation of the IAM Policy Resource](#deep-dive-a-line-by-line-explanation-of-the-iam-policy-resource)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands I Used](#exploring-the-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to use Terraform to create a new AWS IAM Policy with a specific set of permissions. The requirements were:
1.  The policy's name had to be `iampolicy_john`.
2.  The policy must grant **read-only access** to the EC2 console, allowing a user to view instances, AMIs, and snapshots.
3.  The resource had to be created in the `us-east-1` region.
4.  All code had to be in a single `main.tf` file.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved writing a Terraform file that defined the policy resource, including an embedded JSON policy document.

#### Phase 1: Writing the Code
In the `/home/bob/terraform` directory, I created my `main.tf` file and wrote the following code.
```terraform
# 1. Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Define the IAM Policy Resource
resource "aws_iam_policy" "john_policy_resource" {
  name        = "iampolicy_john"
  description = "Policy for read-only access to EC2 console resources"

  # The policy document itself, written in JSON format.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ec2:Describe*",
        ],
        Resource = "*"
      }
    ]
  })
}
```

#### Phase 2: The Terraform Workflow
From my terminal, I ran the three core commands.
-   `terraform init`: This downloaded the AWS provider plugin.
-   `terraform plan`: This showed me a preview, confirming that Terraform would create one `aws_iam_policy` resource with the JSON document I defined.
-   `terraform apply`: After I confirmed with `yes`, this command created the policy in my AWS account. The success message confirmed the task was complete.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **IAM Policy**: This is the most important concept. A policy is a JSON document that explicitly defines a set of permissions. It is the fundamental building block of all access control in AWS. A policy itself does nothing until it is **attached** to an identity (a user, group, or role).
-   **Principle of Least Privilege**: This task is a perfect example of this security principle. Instead of giving a user a powerful, pre-made policy like `AdministratorAccess` or even `EC2FullAccess`, I created a custom policy that grants *only* the permissions needed for a specific task (viewing resources). The `ec2:Describe*` action is the key: it allows the user to *describe* (view) resources, but not to *create*, *modify*, or *delete* them.
-   **Security as Code**: By defining my permission policies in a Terraform file, I am treating my security rules as code. This means they are:
    -   **Version-Controlled:** I can track every change to my permissions in Git.
    -   **Auditable:** It's easy to see exactly who has what permissions by reading the code.
    -   **Reusable:** I can use the same policy definition in multiple environments.

---

### Deep Dive: A Line-by-Line Explanation of the IAM Policy Resource
<a name="deep-dive-a-line-by-line-explanation-of-the-iam-policy-resource"></a>
Understanding the structure of the `aws_iam_policy` resource and the JSON document inside it was the core of this task.

[Image of an IAM Policy document]

```terraform
# Standard provider configuration block.
provider "aws" {
  region = "us-east-1"
}

# This is the resource block that defines my IAM Policy.
# "aws_iam_policy" is the Resource TYPE.
# "john_policy_resource" is the local NAME I use to refer to this policy.
resource "aws_iam_policy" "john_policy_resource" {
  
  # The 'name' argument sets the unique name for the policy within my AWS account.
  name        = "iampolicy_john"
  description = "Policy for read-only access to EC2 console resources"

  # The 'policy' argument is where the magic happens. It requires a JSON string.
  # The 'jsonencode' function is a built-in Terraform function that takes a
  # Terraform map/object and correctly converts it into a properly formatted JSON string.
  policy = jsonencode({
    # 'Version' is a required field for all IAM policies. '2012-10-17' is the current, standard version.
    Version = "2012-10-17",
    # A policy contains a list of one or more 'Statement' blocks.
    Statement = [
      # This is my one and only statement block.
      {
        # 'Effect' specifies whether the statement allows or denies access.
        Effect   = "Allow",
        # 'Action' is a list of the specific API calls that are being allowed.
        # The wildcard 'ec2:Describe*' is a powerful shortcut. It matches all EC2
        # actions that start with "Describe", like DescribeInstances, DescribeImages,
        # DescribeSnapshots, etc. This is exactly what "read-only" means.
        Action   = [
          "ec2:Describe*",
        ],
        # 'Resource' specifies which resources the action can be performed on.
        # The wildcard '*' means this action is allowed on ALL resources.
        Resource = "*"
      }
    ]
  })
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Invalid JSON:** The policy document must be valid JSON. A missing comma or brace would cause a syntax error. Using `jsonencode` helps prevent this, as Terraform will validate the structure before converting it.
-   **Being Too Permissive:** It's easy to use a wildcard like `ec2:*` by mistake. This would grant the user full control over all EC2 actions, not just read-only access, violating the principle of least privilege.
-   **Forgetting to Attach the Policy:** Creating a policy is only the first step. For it to have any effect, it must be attached to a user, group, or role. This would be done with a separate Terraform resource, like `aws_iam_user_policy_attachment`. My task was only to create the policy itself.

---

### Exploring the Commands I Used
<a name="exploring-the-commands-i-used"></a>
The workflow was the standard, three-step Terraform process:
-   `terraform init`: Prepared my working directory by downloading the `aws` provider plugin.
-   `terraform plan`: Showed me a "dry run" plan, confirming that it would create one `aws_iam_policy` resource with my specified JSON document.
-   `terraform apply`: Executed the plan and created the IAM policy in my AWS account after I confirmed with `yes`.
  