# Terraform Level 1, Task 6: Provisioning a Static Public IP (Elastic IP)

Today's task was to provision another essential piece of public-facing infrastructure: an AWS Elastic IP (EIP). This was a great lesson in understanding the difference between dynamic and static public IPs and why having a permanent, reliable address is critical for any serious web service.

I learned how to declare an `aws_eip` resource in my Terraform code and provision it using the standard `init`, `plan`, `apply` workflow. This document is my detailed, beginner-friendly explanation of that process, breaking down the concepts and every line of code.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Decoding the `aws_eip` Resource](#deep-dive-decoding-the-aws_eip-resource)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to use Terraform to allocate a new AWS Elastic IP address. The specific requirements were:
1.  All code had to be in a single `main.tf` file.
2.  The EIP's name tag in AWS had to be `nautilus-eip`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process followed the now-familiar three-phase Terraform workflow.

#### Phase 1: Writing the Code
In the `/home/bob/terraform` directory, I created my `main.tf` file, making sure no other `.tf` files were present. I wrote the following simple and declarative code to define the EIP.

```terraform
# 1. Configure the AWS Provider to set the region
provider "aws" {
  region = "us-east-1"
}

# 2. Define the Elastic IP Resource
resource "aws_eip" "nautilus_eip_resource" {
  tags = {
    Name = "nautilus-eip"
  }
}
```

#### Phase 2: The Terraform Workflow
From my terminal in the same directory, I executed the three core commands.

1.  **Initialize:** This downloaded the AWS provider plugin.
    ```bash
    terraform init
    ```

2.  **Plan:** The "dry run" command showed me a preview, confirming that Terraform intended to create one `aws_eip` resource.
    ```bash
    terraform plan
    ```

3.  **Apply:** This command executed the plan. After I confirmed with `yes`, Terraform allocated the EIP in my AWS account.
    ```bash
    terraform apply
    ```
    The success message, `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`, was my confirmation that the task was done.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Dynamic vs. Static IPs:**
    -   By default, when you launch an AWS EC2 instance (a virtual server), it gets a **dynamic** public IP address. This address is temporary. If you stop and then start the instance, **it will get a new, different public IP address.** This is a huge problem for a web server, because any DNS records (like `www.myapp.com`) pointing to the old IP would break.
    -   An **Elastic IP (EIP)** solves this by giving you a **static** public IP address. It's a permanent address that belongs to your AWS account, not to a specific server.

-   **Elastic IP (EIP):** I learned to think of an EIP as a permanent, reserved parking spot for my application on the internet.
    -   **Flexibility (The "Elastic" part):** I can "point" or "associate" this EIP to any EC2 instance in my account. If my primary web server fails, I can launch a new, healthy one and simply re-associate the same EIP to the new server. My users, who are still going to the same static IP address, will experience minimal downtime and won't even know the underlying server has changed.
    -   **Stability:** It provides a stable, predictable public endpoint for my services, which is essential for DNS, whitelisting, and customer access.

-   **Terraform `aws_eip` Resource:** This is the specific resource type in the Terraform AWS provider that allows me to provision an Elastic IP address as code.

---

### Deep Dive: Decoding the `aws_eip` Resource
<a name="deep-dive-decoding-the-aws_eip-resource"></a>
The code for this task was very concise, but it's important to understand what each part does.

[Image of an Elastic IP being re-associated from a failed to a healthy server]

```terraform
# The provider block configures the "aws" provider to work in the correct region.
provider "aws" {
  region = "us-east-1"
}

# This is the resource block that defines my Elastic IP.
# "aws_eip" is the Resource TYPE, telling Terraform I want an EIP.
# "nautilus_eip_resource" is the local NAME I use to refer to this EIP
# within my Terraform code (for example, if I wanted to associate it
# with an EC2 instance in a later step).
resource "aws_eip" "nautilus_eip_resource" {
  
  # The 'tags' argument is a map of key-value pairs. This is how I
  # label my resources in the cloud for easy identification and cost tracking.
  tags = {
    # The "Name" tag is special. Its value is used as the display name
    # in the AWS Console.
    Name = "nautilus-eip"
  }
}
```
*An important note is that I didn't have to specify that this EIP was for a VPC. By default, the `aws_eip` resource creates a VPC-scoped EIP, which is the modern standard.*

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Cost of Unused EIPs:** This is the biggest "gotcha" with Elastic IPs. AWS provides an EIP for **free** as long as it is **attached to a running EC2 instance**. However, if you allocate an EIP and leave it unattached, or attach it to a stopped instance, **AWS will start charging you for it**. This is to encourage efficient use of the limited IPv4 address pool. It's crucial to always release EIPs you are no longer using (`terraform destroy`).
-   **Regional Scope:** Elastic IPs are tied to a specific AWS region. An EIP created in `us-east-1` cannot be attached to an instance in `us-west-2`.
-   **VPC vs. EC2-Classic:** The `aws_eip` resource defaults to creating a VPC-scoped EIP. For the very old "EC2-Classic" platform, you would need to add the argument `vpc = false`, but this is almost never required today.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
The workflow was the standard, three-step Terraform process:
-   `terraform init`: Prepared my working directory by downloading the `aws` provider plugin.
-   `terraform plan`: Showed me a "dry run" plan, confirming that it would create one `aws_eip` resource.
-   `terraform apply`: Executed the plan and allocated the static IP address in my AWS account after I confirmed with `yes`.
-   `terraform destroy`: While not used in the task, this would be the command to run to de-allocate the EIP and stop any potential charges.
  