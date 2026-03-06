# Terraform Level 1, Task 7: Launching My First EC2 Instance

Today was the moment all the previous Terraform tasks were building up to. I finally used Infrastructure as Code to provision a complete, running virtual server—an AWS EC2 instance. This was an incredibly satisfying task because it brought together multiple resources (a key pair and the instance itself) and showed me how Terraform handles dependencies between them.

I learned how to declare a server in code, specifying everything from its operating system and hardware size to its security configuration. This document is my detailed, first-person guide to that entire process, with a deep dive into every line of the code and the concepts behind it.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: A Line-by-Line Explanation of My `main.tf` Script](#deep-dive-a-line-by-line-explanation-of-my-main.tf-script)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands I Used](#exploring-the-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to use Terraform to launch a new AWS EC2 instance with a specific configuration. The requirements were:
1.  All code had to be in a single `main.tf` file.
2.  The instance's name tag in AWS had to be `xfusion-ec2`.
3.  The operating system had to be a specific Amazon Linux AMI: `ami-0c101f26f147fa7fd`.
4.  The hardware size (instance type) had to be `t2.micro`.
5.  A new RSA key pair named `xfusion-kp` had to be created and attached to the instance for access.
6.  The instance had to use the default security group.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved writing a more complex Terraform file that defined multiple, dependent resources, and then running the standard three-step workflow.

#### Phase 1: Writing the Code
In the `/home/bob/terraform` directory, I created my `main.tf` file. I wrote the following code, which first defines the key pair and then defines the instance that uses that key pair.

```terraform
# 1. Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Generate a new RSA private key locally
resource "tls_private_key" "xfusion_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 3. Create the key pair in AWS using the public key
resource "aws_key_pair" "xfusion_key_pair" {
  key_name   = "xfusion-kp"
  public_key = tls_private_key.xfusion_rsa.public_key_openssh
}

# 4. Define the EC2 Instance Resource
resource "aws_instance" "xfusion_instance" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t2.micro"
  
  # This line tells the instance to use the key pair created above.
  # Terraform automatically understands this dependency.
  key_name      = aws_key_pair.xfusion_key_pair.key_name

  tags = {
    Name = "xfusion-ec2"
  }
}
```

#### Phase 2: The Terraform Workflow
From my terminal in the same directory, I executed the three core commands.

1.  **Initialize:** This downloaded the `aws` and `tls` provider plugins.
    ```bash
    terraform init
    ```

2.  **Plan:** The "dry run" command showed me a preview, confirming that Terraform would create a `tls_private_key`, an `aws_key_pair`, and finally an `aws_instance`.
    ```bash
    terraform plan
    ```

3.  **Apply:** This command executed the plan. After I confirmed with `yes`, Terraform created the resources in the correct order.
    ```bash
    terraform apply
    ```
    The success message, `Apply complete! Resources: 3 added, 0 changed, 0 destroyed.`, was my confirmation that the task was done.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **EC2 (Elastic Compute Cloud):** This is the heart of AWS's "Infrastructure as a Service" (IaaS) offering. An EC2 instance is simply a **virtual server in the cloud**. It's the primary resource where I will run my applications, databases, and other services.
-   **AMI (Amazon Machine Image):** An AMI is the template for an EC2 instance. It defines the initial state of the server, including the Operating System (Amazon Linux in my case), and any pre-installed software. The AMI ID (`ami-0c101f26f147fa7fd`) is a unique identifier for a specific version of that template.
-   **Instance Type:** This defines the "hardware" specs of my virtual server—how much vCPU, memory (RAM), and the type of network performance it has. `t2.micro` is a small, general-purpose instance type that is perfect for small websites or development environments and is part of the AWS Free Tier.
-   **Default Security Group:** Every VPC comes with a "default" security group. If you don't specify a security group when launching an instance, AWS automatically attaches this one. By omitting the `vpc_security_group_ids` argument in my Terraform code, I was relying on this default behavior, which fulfilled the task's requirement.

---

### Deep Dive: A Line-by-Line Explanation of My `main.tf` Script
<a name="deep-dive-a-line-by-line-explanation-of-my-main.tf-script"></a>
This script showed me the true power of Terraform: managing dependencies between resources automatically.

[Image of an AWS EC2 instance icon]

```terraform
# Standard provider configuration block.
provider "aws" {
  region = "us-east-1"
}

# This resource from the 'tls' provider doesn't create anything in the cloud.
# It runs locally to generate a new 4096-bit RSA private key in memory.
resource "tls_private_key" "xfusion_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# This resource takes the PUBLIC portion of the key generated above and
# sends it to the AWS API to create an EC2 Key Pair resource.
resource "aws_key_pair" "xfusion_key_pair" {
  key_name   = "xfusion-kp"
  
  # This is the dependency link. The 'public_key' argument is being given the
  # value of the 'public_key_openssh' attribute from the 'tls_private_key'
  # resource named 'xfusion_rsa'. Terraform sees this and knows it must
  # create the private key first.
  public_key = tls_private_key.xfusion_rsa.public_key_openssh
}

# This is the main resource that creates the virtual server.
resource "aws_instance" "xfusion_instance" {

  # The AMI ID is a required argument. It tells AWS what OS to install.
  ami           = "ami-0c101f26f147fa7fd"
  
  # The instance_type is also required, defining the server's hardware.
  instance_type = "t2.micro"
  
  # This is another dependency link. The 'key_name' argument tells AWS to
  # attach a key pair to the instance so I can SSH into it.
  # I'm referencing the 'key_name' attribute from the 'aws_key_pair'
  # resource named 'xfusion_key_pair' that I defined above.
  key_name      = aws_key_pair.xfusion_key_pair.key_name

  # Standard tagging to give the instance a recognizable name.
  tags = {
    Name = "xfusion-ec2"
  }
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Incorrect AMI ID:** AMI IDs are unique to each AWS region. Using an AMI ID from a different region would cause the `apply` command to fail with an "AMI not found" error.
-   **Instance Type Not Available:** Not all instance types are available in all regions or Availability Zones. Using an invalid or unavailable type would cause the `apply` to fail.
-   **Key Pair Not Found:** If I had tried to reference a key pair that didn't exist (e.g., if I forgot to create the `aws_key_pair` resource), the plan would fail because the dependency couldn't be satisfied.
-   **Missing Security Group:** While the default security group was sufficient for this task, in a real-world scenario with a custom VPC, forgetting to define and attach a security group would leave the instance isolated and unreachable.

---

### Exploring the Commands I Used
<a name="exploring-the-commands-i-used"></a>
The workflow was the standard, three-step Terraform process:
-   `terraform init`: Prepared my working directory by downloading the `aws` and `tls` provider plugins.
-   `terraform plan`: Showed me a "dry run" plan, confirming that it would create three new resources in the correct order.
-   `terraform apply`: Executed the plan and launched my virtual server in the cloud after I confirmed with `yes`.
  