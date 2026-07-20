# Terraform Level 1, Task 29: Running AWS CLI Commands with Terraform

Today's task was a very interesting and unconventional use of Terraform. Instead of using Terraform's native resources to manage infrastructure, my objective was to use Terraform as a script runner to execute **AWS CLI commands** for a one-time cleanup task.

This was a fantastic lesson in the power and flexibility of Terraform's provisioners. I learned how to use a `null_resource` in combination with a `local-exec` provisioner to back up an S3 bucket's contents to my local machine and then delete the bucket from AWS, all within a single `terraform apply`.

## Table of Contents
- [Terraform Level 1, Task 29: Running AWS CLI Commands with Terraform](#terraform-level-1-task-29-running-aws-cli-commands-with-terraform)
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
My objective was to perform a two-step cleanup operation using Terraform to run AWS CLI commands. The requirements were:
1.  All code had to be in a single `main.tf` file.
2.  Copy the contents of an existing S3 bucket (`xfusion-bck-31356`) to a local directory (`/opt/s3-backup/`).
3.  After the copy, delete the S3 bucket (`xfusion-bck-31356`).

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved writing a Terraform file that defined a `null_resource` to act as a trigger for the AWS CLI commands.

#### Phase 1: Writing the Code
In the `/home/bob/terraform` directory, I created my `main.tf` file. I wrote the following declarative code.
```terraform
# 1. Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Define a null_resource to run our script
resource "null_resource" "s3_cleanup_operation" {
  
  # A provisioner block defines an action to take
  provisioner "local-exec" {
    
    # The 'command' argument specifies the script to run on the machine
    # where 'terraform apply' is executed.
    # I'm using a 'heredoc' string (<<-EOT) to write a multi-line script.
    command = <<-EOT
      
      # First, create the local backup directory. The -p flag is safe
      # and won't error if the directory already exists.
      echo "Creating backup directory..."
      mkdir -p /opt/s3-backup/
      
      # Use 'aws s3 sync' to recursively copy the bucket contents.
      # 'sync' is safer and faster than 'cp -r' as it only copies new or changed files.
      echo "Backing up S3 bucket: s3://xfusion-bck-31356"
      aws s3 sync s3://xfusion-bck-31356 /opt/s3-backup/
      
      # Use 'aws s3 rb' (remove bucket) to delete the bucket.
      # The '--force' flag is essential as it deletes all objects in
      # the bucket first, which is required before a bucket can be deleted.
      echo "Deleting S3 bucket: s3://xfusion-bck-31356"
      aws s3 rb s3://xfusion-bck-31356 --force
      
      echo "Cleanup complete."
    EOT
  }
}
```

#### Phase 2: The Terraform Workflow
From my terminal in the same directory, I executed the three core commands.
1.  **Initialize:** `terraform init`.
2.  **Plan:** `terraform plan`. The output showed that Terraform would create one `null_resource.s3_cleanup_operation`.
3.  **Apply:** `terraform apply`. This was the main step. After I confirmed with `yes`, Terraform executed the `local-exec` provisioner. I saw the `echo` messages from my script in the output, followed by the output of the AWS CLI commands, confirming the backup and deletion were successful.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Terraform as a Script Runner:** This task showed me a "non-standard" but powerful way to use Terraform. Instead of just defining resources, I used it to orchestrate a sequence of **imperative commands** (like `aws s3 sync` and `aws s3 rb`).
-   **`null_resource`**: This is a special, empty resource that does nothing on its own. It's a powerful tool in Terraform because it acts as a **"dummy" resource** that I can attach provisioners to. It's often used to run one-time scripts or to trigger actions that don't have a dedicated Terraform resource.
-   **`provisioner "local-exec"`**: This is the key to this task. A provisioner is a block of code that executes actions. The `local-exec` provisioner runs a command **on the local machine** that is running the `terraform apply` command. In this case, it ran my AWS CLI script on the `terraform-client` host.
-   **Why use this method?** While I *could* have just written a bash script (`backup.sh`) and run it, the task required me to use Terraform. In a real-world scenario, you might do this to integrate a one-off scripting task into a larger, existing Terraform workflow. For example, I might run a `local-exec` provisioner to run a database migration script *after* a new `aws_db_instance` resource has been created.

---

### Deep Dive: A Line-by-Line Explanation of My `main.tf` Script
<a name="deep-dive-a-line-by-line-explanation-of-my-main.tf-script"></a>
This script uses a provisioner, which is an advanced Terraform feature.



```terraform
# Standard provider configuration block.
provider "aws" {
  region = "us-east-1"
}

# This is the resource block that defines my "dummy" resource.
# "null_resource" is the Resource TYPE.
# "s3_cleanup_operation" is the local NAME I use to refer to this operation.
resource "null_resource" "s3_cleanup_operation" {
  
  # This 'provisioner' block defines a script to be run.
  # "local-exec" specifies the type: run a command locally.
  provisioner "local-exec" {
    
    # The 'command' argument contains the script to run.
    # The '<<-EOT' (Heredoc) syntax allows me to write a
    # user-friendly, multi-line shell script.
    command = <<-EOT
      
      # Create the local backup directory
      mkdir -p /opt/s3-backup/
      
      # Use the AWS CLI 's3 sync' command to copy the data
      # s3://[bucket_name] is the source
      # /opt/s3-backup/ is the destination
      aws s3 sync s3://xfusion-bck-31356 /opt/s3-backup/
      
      # Use the AWS CLI 's3 rb' (remove bucket) command
      # s3://[bucket_name] is the target
      # '--force' is critical; it empties the bucket before deleting it.
      aws s3 rb s3://xfusion-bck-31356 --force
      
    EOT # 'EOT' (End Of Text) marks the end of the heredoc.
  }
}
```

### Common Pitfalls
<a name="common-pitfalls"></a>

- **Provisioners are a Last Resort**: The official Terraform documentation states that provisioners should be a last resort. The "Terraform-native" way to do this would be to use a data "aws_s3_bucket_objects" source to get a list of files and resource "local_file" to copy them, and then to terraform destroy an aws_s3_bucket resource. However, the task specifically required using the AWS CLI.

- **Missing Dependencies**: This local-exec provisioner relies on the AWS CLI being installed and configured on the machine running Terraform. In this lab, it was pre-configured. In a new environment, I would have to install it myself.

- **State File Contains No Infrastructure**: After this apply, my terraform.tfstate file will contain a null_resource. If I run terraform destroy, it will destroy this null_resource, but it will not run the AWS CLI commands in reverse to restore the bucket. This was a one-way, one-time operation.

### Exploring the Essential Terraform Commands
<a name="exploring-the-essential-terraform-commands"></a>

- **`terraform init`**: Prepared my working directory. This command is always required, even if the providers are simple (like null).

- **`terraform plan`**: Showed me a "dry run" plan, confirming that it would create one null_resource and run the associated local-exec provisioner.

- **`terraform apply`**: Executed the plan. This is the command that actually triggered my AWS CLI script to run, performing the backup and deletion.