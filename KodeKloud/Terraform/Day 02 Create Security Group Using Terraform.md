# Terraform Level 1, Task 2: Building a Virtual Firewall with Code

Building on my first experience with Terraform, today's task was to create a foundational piece of cloud security: an AWS Security Group. This was a perfect next step because it moved from a simple resource to one with a more complex, nested structure, including rules for network traffic.

I learned how to translate security requirements (like "allow HTTP and SSH traffic") into a declarative Terraform script. This process of codifying security rules is a core practice in DevOps, ensuring that my infrastructure's firewall is as version-controlled and reproducible as the servers it protects.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Decoding the `aws_security_group` Resource](#deep-dive-decoding-the-aws_security_group-resource)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to use Terraform to create a new AWS Security Group with specific firewall rules. The requirements were:
1.  All code must be in a single `main.tf` file.
2.  The security group's name must be `nautilus-sg`.
3.  It needed a specific description: `Security group for Nautilus App Servers`.
4.  It required two inbound rules:
    -   Allow HTTP traffic on port 80 from the entire internet (`0.0.0.0/0`).
    -   Allow SSH traffic on port 22 from the entire internet (`0.0.0.0/0`).

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process followed the standard, predictable Terraform workflow.

#### Phase 1: Writing the Code
In the `/home/bob/terraform` directory, I created my `main.tf` file and wrote the following declarative code to define my security group.

```terraform
# 1. Configure the AWS Provider to set the region
provider "aws" {
  region = "us-east-1"
}

# 2. Define the Security Group Resource
resource "aws_security_group" "nautilus_sg_resource" {
  name        = "nautilus-sg"
  description = "Security group for Nautilus App Servers"

  # 3. Define the Inbound Rule for HTTP
  ingress {
    description = "Allow HTTP inbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 4. Define the Inbound Rule for SSH
  ingress {
    description = "Allow SSH inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

#### Phase 2: The Terraform Workflow
From my terminal in the same directory, I executed the three essential commands.

1.  **Initialize:** This downloaded the AWS provider plugin.
    ```bash
    terraform init
    ```

2.  **Plan:** This showed me a "dry run" preview, confirming that Terraform intended to create one `aws_security_group` resource with the rules I defined.
    ```bash
    terraform plan
    ```

3.  **Apply:** This command actually built the resource in my AWS account.
    ```bash
    terraform apply
    ```
    After I confirmed by typing `yes`, Terraform created the security group and reported success: `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`

This successful output was the primary verification that my task was complete.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Security Group (SG):** This is the fundamental building block of network security for AWS EC2 instances. It acts as a **virtual firewall** at the server level. By defining rules, I am controlling exactly what kind of traffic is allowed to reach my server.
-   **`ingress` (Inbound) Rules:** These rules apply to traffic *coming into* the server. By default, an SG blocks all inbound traffic. I had to explicitly create rules to open the "doors" for web and SSH traffic.
-   **`egress` (Outbound) Rules:** These rules apply to traffic *leaving* the server. By default, an SG allows all outbound traffic. I didn't need to define any egress rules for this task.
-   **`0.0.0.0/0` (CIDR Block):** This is a special network address that means "the entire internet." By specifying this as the source `cidr_blocks`, I was allowing anyone from anywhere to connect to my server on ports 80 and 22. In a real production environment, I would restrict the SSH source to a much smaller, trusted IP range (like my office or a VPN) for better security.

---

### Deep Dive: Decoding the `aws_security_group` Resource
<a name="deep-dive-decoding-the-aws_security_group-resource"></a>
Understanding the structure of this Terraform resource was the core of the task.



```terraform
# This is the resource block.
# "aws_security_group" is the Resource TYPE, telling Terraform what to create.
# "nautilus_sg_resource" is the local NAME, which I use to refer to this resource
# within my Terraform code. It doesn't affect the name in AWS.
resource "aws_security_group" "nautilus_sg_resource" {
  
  # This is the 'name' argument. This IS the name that will appear
  # in the AWS console.
  name        = "nautilus-sg"
  description = "Security group for Nautilus App Servers"

  # This is an 'ingress' block, defining an inbound rule.
  # I can have multiple ingress blocks for multiple rules.
  ingress {
    description = "Allow HTTP inbound" # A helpful comment for the rule.
    from_port   = 80                   # The start of the port range.
    to_port     = 80                   # The end of the port range. For a single port, they are the same.
    protocol    = "tcp"                # The network protocol (most web traffic is TCP).
    cidr_blocks = ["0.0.0.0/0"]        # A list of source IP ranges to allow.
  }

  ingress {
    description = "Allow SSH inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

### Common Pitfalls
<a name="common-pitfalls"></a>

- **Conflicting Security Group Names**: Security group names must be unique within a single AWS VPC. If a group named nautilus-sg already existed, my terraform apply command would have failed.

- **Forgetting cidr_blocks**: The cidr_blocks argument is a list. Even for a single entry, it must be enclosed in square brackets []. Forgetting them would cause a syntax error.

- **Typos in Protocol Names**: Using "TCP" instead of the required lowercase "tcp" would cause an error during the plan or apply phase.

- **Mixing up name and the local resource name**: It's important to remember that the name argument inside the resource block is what sets the name in AWS, while the name after the resource type (nautilus_sg_resource) is just for use within Terraform.

----

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>

- **`terraform init`**: The first command to run. It prepares the working directory by downloading the necessary provider plugins (in this case, the aws provider).

- **`terraform plan`**: A "dry run" command. It reads my code, compares it to the current state of my infrastructure in AWS, and shows me a detailed plan of what it will create, change, or destroy.

- **`terraform apply`**: The command that executes the plan. It builds the infrastructure as defined in the code, asking for a final yes for safety before making any changes.