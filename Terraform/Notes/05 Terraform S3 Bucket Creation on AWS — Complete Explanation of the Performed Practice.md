# Terraform S3 Bucket Creation on AWS — Complete Explanation of the Performed Practice

## Understanding the Goal of the Practice

The activity performed demonstrates the complete lifecycle of creating infrastructure using Terraform on AWS. Instead of manually opening the AWS console and creating resources using graphical menus, infrastructure is defined using configuration code. Terraform reads that configuration, determines what infrastructure should exist, communicates with AWS APIs, and creates the required resources.

The main infrastructure created in this exercise is an **Amazon S3 bucket**.

Amazon S3 (Simple Storage Service) is an object storage system provided by AWS. Object storage means data is stored as objects inside buckets rather than as files in folders like a traditional filesystem. Each object contains data, metadata, and a unique identifier.

The bucket acts as a container that stores objects such as images, logs, backups, application assets, or configuration files.

The entire process followed a standard Terraform workflow.

Write Infrastructure Configuration
→ Initialize Terraform Environment
→ Preview Infrastructure Changes
→ Apply Infrastructure Creation
→ Verify Resource Existence
→ Track Infrastructure Using State

Each stage of this workflow corresponds to a specific command and internal behavior.

---

# Preparing the Environment

## Installing Terraform

The first step in the process is ensuring Terraform exists in the system.

The command used to verify installation is:

```
terraform -version
```

This command simply asks the Terraform binary to print the currently installed version.

Terraform is a compiled binary written in the Go programming language. When this command runs, the operating system searches for the Terraform executable in system paths and executes it.

If Terraform is installed successfully, it prints something similar to:

```
Terraform v1.x.x
```

If Terraform is not installed, the system must install it using the HashiCorp package repository.

Installation commands included:

```
sudo apt update
sudo apt install -y gnupg software-properties-common curl
```

`apt` is the package manager used in Ubuntu-based systems.
`apt update` refreshes the package list so the system knows which software versions are available.

`gnupg` provides cryptographic verification support. Package repositories sign their packages using cryptographic keys so the system can verify authenticity.

`software-properties-common` allows the system to add external package repositories.

`curl` is a tool used to download data from the internet.

Next the HashiCorp signing key is added:

```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
```

This downloads the public key used by HashiCorp to sign Terraform packages.
Adding this key allows Ubuntu to verify the downloaded packages are authentic.

Then the Terraform repository is added:

```
sudo apt-add-repository \
"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
```

`deb` means Debian-based package repository.

`arch=amd64` specifies the CPU architecture.

`$(lsb_release -cs)` dynamically inserts the Ubuntu codename of the current system.

After that the package list is refreshed again:

```
sudo apt update
```

Finally Terraform is installed:

```
sudo apt install terraform
```

This downloads the Terraform binary and places it in the system path.

---

# Configuring AWS CLI Authentication

Terraform communicates with AWS using AWS APIs. API stands for **Application Programming Interface**, which is essentially a programmatic interface that allows software to interact with cloud services.

To authenticate with AWS APIs, credentials are required.

Instead of placing credentials inside Terraform configuration files, the common practice is using AWS CLI authentication.

AWS CLI is installed using:

```
sudo apt install awscli -y
```

This installs the AWS command line interface which can communicate with AWS services.

Next credentials are configured:

```
aws configure
```

This command prompts for four values.

AWS Access Key ID
AWS Secret Access Key
Default Region
Default Output Format

These credentials correspond to an IAM user in AWS.

IAM stands for **Identity and Access Management**. IAM manages authentication and authorization for AWS accounts.

The access key pair acts as programmatic credentials that allow tools like Terraform and AWS CLI to interact with AWS services.

The credentials are stored locally in:

```
~/.aws/credentials
```

The region setting tells AWS CLI which AWS region to use by default.

For example:

```
ap-south-1
```

This represents the **Mumbai region**.

To verify credentials are working, the following command is used:

```
aws sts get-caller-identity
```

STS stands for **Security Token Service**.

The API call `GetCallerIdentity` returns information about the current authenticated identity such as:

* AWS Account ID
* IAM user ARN
* user identifier

If the command returns account details, it confirms the credentials are valid.

---

# Creating the Terraform Project

A project directory was created:

```
mkdir terraform-aws-practice
cd terraform-aws-practice
```

This directory becomes the Terraform working directory.

Terraform automatically reads all files ending with `.tf` inside the directory.

A configuration file was created:

```
touch main.tf
```

The `.tf` extension indicates Terraform configuration files written in HashiCorp Configuration Language.

---

# Terraform Configuration File Explanation (Line-by-Line)

The configuration file contents were:

```
provider "aws"{
        region = "ap-south-1"
}

resource "aws_s3_bucket" "my_first_bucket"{
        bucket = "prashant-terraform-demmo-bucket-001"

        tags = {
                Name = "TerraformDemoBucket"
                Environment = "Dev"
        }
}
```

Now each line can be explained.

---

## Provider Block

```
provider "aws"{
```

This line declares that Terraform will use the **AWS provider**.

A provider in Terraform is a plugin responsible for interacting with a specific platform.

Terraform itself does not know how to create AWS resources. Instead, provider plugins contain the logic required to interact with AWS APIs.

The string `"aws"` specifies the provider name.

When Terraform later runs `terraform init`, it will download the AWS provider plugin.

---

```
region = "ap-south-1"
```

This line specifies the AWS region where resources will be created.

AWS divides infrastructure globally into regions such as:

* us-east-1 (Virginia)
* eu-west-1 (Ireland)
* ap-south-1 (Mumbai)

By setting the region here, every resource defined in this configuration will be created inside that region.

If this line were changed to:

```
region = "us-east-1"
```

Terraform would create resources in the Virginia region instead.

---

```
}
```

This closes the provider block.

---

# Resource Block

```
resource "aws_s3_bucket" "my_first_bucket"{
```

The resource block describes infrastructure Terraform must create.

The syntax format is:

```
resource "<resource_type>" "<resource_name>"
```

`aws_s3_bucket` represents the type of AWS resource.

This tells Terraform to create an S3 bucket.

`my_first_bucket` is the Terraform logical name for this resource.

Terraform uses this name internally to reference the resource.

For example another resource could reference it like:

```
aws_s3_bucket.my_first_bucket.id
```

This would retrieve the bucket identifier.

---

```
bucket = "prashant-terraform-demmo-bucket-001"
```

This line specifies the bucket name.

S3 bucket names must be globally unique across all AWS accounts worldwide.

This means no other AWS account can already have a bucket with the same name.

If a duplicate name is used, AWS will reject the request.

---

```
tags = {
```

Tags are key-value metadata labels attached to AWS resources.

Tags help with organization, cost tracking, automation, and resource management.

Large companies often enforce tagging policies so resources are properly categorized.

---

```
Name = "TerraformDemoBucket"
```

This creates a tag with key `Name`.

AWS consoles often display this tag to identify resources.

---

```
Environment = "Dev"
```

This tag identifies the environment.

Typical environments include:

* Dev (development)
* Staging (testing)
* Prod (production)

This helps differentiate resources used for different purposes.

---

```
}
```

This closes the tags block.

---

```
}
```

This closes the resource block.

---

# Terraform Initialization

The next command executed was:

```
terraform init
```

Terraform initialization prepares the working directory.

Internally Terraform performs several operations.

First Terraform scans the directory for `.tf` files.

It detects the AWS provider requirement from the provider block.

Next Terraform connects to the Terraform Registry:

```
registry.terraform.io
```

This registry hosts provider plugins.

Terraform identifies the AWS provider and downloads the provider binary.

The provider binary is stored inside:

```
.terraform/providers/
```

Terraform also creates:

```
.terraform.lock.hcl
```

This lock file records the exact provider version installed.

The lock file ensures that every system running the configuration uses the same provider version.

---

# Terraform Plan

The command executed next was:

```
terraform plan
```

Terraform reads three things:

Configuration files
State file
Real infrastructure

Since this was the first run, the state file did not yet contain any resources.

Terraform compared the configuration with the state and determined that the S3 bucket does not exist.

Therefore Terraform generated the plan:

```
Plan: 1 to add, 0 to change, 0 to destroy
```

This means Terraform intends to create one resource.

---

# Terraform Apply

The command executed next was:

```
terraform apply
```

Terraform again calculates the plan internally.

It prints the actions that will occur and asks for confirmation.

After confirmation Terraform communicates with AWS APIs through the AWS provider.

The provider sends an HTTP request to the S3 service instructing AWS to create a bucket with the specified name and region.

AWS processes the request and returns a success response.

Terraform then records the resource details in the state file.

---

# Terraform State File

After successful creation a new file appears:

```
terraform.tfstate
```

This file is a JSON document that stores the current infrastructure state.

Example information inside the state file includes:

* resource type
* resource identifier
* region
* configuration values
* metadata

Terraform relies heavily on this state file to determine what infrastructure already exists.

Without this state Terraform would not know which resources it created earlier.

---

# Verifying Infrastructure Using AWS CLI

After the resource was created, verification commands were executed.

---

## List Buckets

```
aws s3 ls
```

This command requests a list of all buckets in the AWS account.

If the bucket appears in the output, it confirms AWS created the resource.

---

## Verify Bucket Region

```
aws s3api get-bucket-location \
--bucket prashant-terraform-demmo-bucket-001
```

This command retrieves the region where the bucket resides.

The expected response should show:

```
LocationConstraint: ap-south-1
```

---

## Check Bucket Metadata

```
aws s3api head-bucket \
--bucket prashant-terraform-demmo-bucket-001
```

This command checks if the bucket exists and is accessible.

If the bucket exists, the command returns a success response.

---

## Verify Bucket Tags

```
aws s3api get-bucket-tagging \
--bucket prashant-terraform-demmo-bucket-001
```

This command retrieves the tags applied to the bucket.

The expected output shows:

Name = TerraformDemoBucket
Environment = Dev

---

# Terraform State Verification

Terraform can also display tracked resources.

```
terraform state list
```

This command lists all resources Terraform manages.

Expected output:

```
aws_s3_bucket.my_first_bucket
```

Detailed state information can be displayed using:

```
terraform state show aws_s3_bucket.my_first_bucket
```

This shows attributes stored in the state file such as:

* bucket ARN
* region
* tags
* configuration parameters

---

# Destroying Infrastructure

Terraform can also delete infrastructure.

The command used is:

```
terraform destroy
```

Terraform calculates a plan to remove resources defined in the configuration.

After confirmation Terraform sends delete requests to AWS.

AWS then removes the resources.

---

# Understanding What Was Achieved

The full Terraform lifecycle was executed:

Infrastructure defined using code
Terraform environment initialized
Infrastructure changes previewed
Infrastructure created in AWS
Infrastructure tracked using state
Infrastructure verified using AWS CLI

This workflow is the foundation of Infrastructure as Code used in modern DevOps environments.

Instead of manually managing infrastructure, everything becomes declarative, reproducible, and version-controlled.
