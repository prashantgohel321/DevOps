# Day 01: My First Steps with Terraform and AWS CLI

Welcome to my Day 01 Terraform and AWS learning journal! Today I started my journey into infrastructure as code, and it was quite an adventure. Let's dive right into everything I practiced, exploring each command, error, and concept in detail. The entire session started right at the terminal, eager to get things building. First things first, I needed to check if I had Terraform installed and what version I was working with.

```bash
terraform --version
```

The terminal told me I was running Terraform version 1.14.3 on a Linux AMD64 environment. It also kindly reminded me that my version was slightly out of date compared to the latest 1.14.8, providing the official HashiCorp link to update. But for our learning purposes today, version 1.14.3 was perfectly fine to proceed with. After confirming the installation, I decided to set up a clean workspace. I created a brand new folder named terraform and navigated straight into it.

```bash
mkdir terraform
cd terraform/
```

Now that I had a dedicated directory, it was time to write my very first piece of Terraform configuration. I fired up the nano text editor and created a file named provider.tf. This file is crucial because it tells Terraform exactly which cloud provider we want to talk to and where to find the necessary plugins.

```hcl
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>5.0"
        }
    }
}
```

Inside this file, I set up the `required_providers` block under the main `terraform` configuration block. This specific code tells Terraform that I want to use the AWS provider, that it should be sourced directly from the official HashiCorp registry, and that it should specifically download a version matching 5.0 or higher. The registry is basically the public terraform registry, the official repository where terraform provider plugins are hosted and distributed by hashicorp. With the provider defined, I was ready to initialize my project.

```bash
terraform init
```

Running the initialization command kicked off a beautiful sequence of events. Terraform scanned my configuration file, recognized the AWS provider requirement, and reached out to the registry to find the matching versions. It successfully installed hashicorp/aws version 5.100.0. During this process, something very important happened in the background. Terraform created a hidden directory named `.terraform` and a lock file named `.terraform.lock.hcl`. This lock file is completely fascinating because it records the exact provider versions selected during initialization, guaranteeing that future initializations will make the exact same selections, preventing unexpected breaking changes. Let's take a deep dive into the hidden `.terraform` directory to see what magic happened.

```bash
cd .terraform/
cd providers/registry.terraform.io/hashicorp/aws/5.100.0/linux_amd64/
ls -la
```

Navigating through this deeply nested folder structure revealed exactly how Terraform manages its plugins. Inside the `linux_amd64` folder, I discovered the actual executable binary file for the AWS provider named `terraform-provider-aws_v5.100.0_x5`. This is the literal plugin that does the heavy lifting to communicate with AWS APIs on my behalf. I even used the `file` command to inspect it, confirming it was an ELF 64-bit LSB statically linked executable. Feeling satisfied with my understanding of the initialization process, I backed out of those hidden directories and headed to the root of my project folder. 

Before getting back to Terraform, I realized I needed the official AWS command line interface installed on my system so I could manually verify the resources Terraform was going to create. I quickly grabbed the proper installation package straight from Amazon.

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Upon successful installation, I quickly ran `aws --version` and received confirmation that I was packing `aws-cli/2.34.29`. Getting the CLI installed was only half the battle though; I still needed to authenticate it so my system could securely talk to my AWS account. 

```bash
aws configure
```

The configuration process prompted me for a series of important details. First, I carefully provided my AWS Access Key ID, and then my secret AWS Secret Access Key. I decided to make my default region "ap-south-1" because deploying resources closer to me makes the most sense. Finally, I chose "json" as my default output format so everything returning from the command line is easily readable and nicely structured. Just to completely understand how the AWS CLI works under the hood, I navigated to my home directory and peaked into the `.aws` folder.

```bash
cd ~/.aws
cat config
cat credentials
```

It was so cool to see how my inputs from the configure command were cleanly separated into two distinct files. The `config` file peacefully stored my default region and JSON output preferences, while the `credentials` file securely held my access keys. Knowing my command line was ready to rock, I jumped straight back into my terraform project directory to start writing the real infrastructure code.

```bash
nano main.tf
```

It was time to get my hands dirty. Inside the `main.tf` file, I crafted my very first resource block to create an Amazon S3 storage bucket.

```hcl
resource "aws_s3_bucket" "aws_s3_bucket" {
    bucket = "PrashantGohel1609"
    acl = "private"
}
```

This resource block is super interesting to dissect. The first word, `resource`, tells Terraform I want to manage an infrastructure object. The second string is the precise type of the resource, which in this case is `aws_s3_bucket`. The third string is a local reference name that I can use to refer to this specific resource elsewhere in my configuration. Inside the block, I specified the actual name of the bucket I wanted to create, alongside what I thought was an appropriate access control list setting. Excited by my work, I wanted to see what Terraform thought about it before pulling any triggers.

```bash
terraform plan
```

The plan command generated a fantastic speculative execution plan. It showed a green plus sign next to my s3 bucket resource, clearly indicating that it planned to create it from scratch. It also displayed a massive list of attributes that would be "known after apply", letting me know there were plenty of properties AWS would generate for me dynamically. Along with the joyful creation news, Terraform also smoothly delivered a helpful warning, notifying me that the `acl` argument was deprecated and hinting that I should be using the independent `aws_s3_bucket_acl` resource instead. I gracefully accepted the warning and proceeded to formally apply my configuration.

```bash
terraform apply
```

Terraform ran the plan one more time and explicitly stopped to ask me if I really wanted to perform these actions. I excitedly typed "yes", but then immediately smacked into an error wall.

```text
Error: validating S3 Bucket (PrashantGohel1609) name: only lowercase alphanumeric characters and hyphens allowed in "PrashantGohel1609"
```

A wonderful learning moment! Terraform and AWS loudly reminded me that S3 bucket names cannot contain uppercase letters; they must be strictly lowercase alphanumeric characters and hyphens. I quickly opened my `main.tf` file back up and changed the bucket name to the completely lowercase string "prashantgohel1609". Crossing my fingers, I ran the apply command a second time, typing "yes" at the prompt. This time, Terraform cheerfully announced that the creation was completing, and practically two seconds later, it was totally finished! I successfully created an S3 bucket purely using code. Immediately after the successful application, I ran a standard listing command and noticed some new files magically appeared in my directory.

```bash
ls -la
```

Sitting proudly next to my configuration files were `terraform.tfstate` and `terraform.tfstate.backup`. These files are the absolute heartbeat of Terraform functionality. When I actually applied my changes, Terraform reached out to AWS, created the bucket, and then wrote all the metadata about that fresh deployment straight into this local state file. This state file tracks exactly what currently exists in the real world environment. Whenever I run further modifications to my code, Terraform will religiously check this state file to figure out precisely what needs to be created, what needs to be altered, and what already matches the desired configuration. I wanted to verify the health of my layout so I executed another helpful command.

```bash
terraform validate
```

Validation ran locally, skipping remote API calls, and simply checked the overall syntactical correctness of my code and structural configuration. Aside from the friendly reminder about my deprecated ACL attribute, the configuration perfectly passed validation. Wanting an even deeper view of my newly established empire, I dug into some local state commands.

```bash
terraform state list
```

This simple command outputted my `aws_s3_bucket.aws_s3_bucket` local reference, confirming Terraform was actively tracking it. Wanting the rich details, I pushed deeper into the state.

```bash
terraform show
```

The output from this command was phenomenally detailed. It spit out the exact human-readable representation of my bucket right from the state file. I could see the full Amazon Resource Name, the explicit hosted zone ID uniquely assigned to my bucket, and confirmation that the region was indeed the "ap-south-1" choice I desired. The configuration side of things looked completely perfect, but I still needed the ultimate independent verification to ensure it truly existed out in the cloud. It was time to pull out the AWS CLI commands.

```bash
aws s3 ls
```

This instantly pulled the massive list of buckets attached to my account, showcasing my newly created "prashantgohel1609" bucket alongside its fresh timestamp. My code absolutely worked. Wanting to squeeze out a bit more information, I dove into the specialized AWS S3 API commands.

```bash
aws s3api get-bucket-location --bucket prashantgohel1609
```

This correctly confirmed my ap-south-1 LocationConstraint. Out of sheer curiosity, I tested a couple of other configuration flags like checking the active bucket policy with `aws s3api get-bucket-policy` and looking for any website setup with `aws s3api get-bucket-website`. In both cases, the API correctly responded that neither a policy nor a website configuration existed yet. With all of my deep validations complete, I ran `terraform apply` one final time. It aggressively refreshed the state and happily informed me that "No changes" were needed because my infrastructure perfectly matched the configuration.

My bucket was empty and sad, so I decided to learn how to actively populate bucket data directly using the AWS CLI synchronization tools. I created a cute little `tempDir` directory, and copied my `main.tf`, `provider.tf`, and `terraform.tfstate` files straight into it. I jumped into that new folder and prepared for my first cross-cloud copy operation.

```bash
aws s3 sync . s3://prashantgohel1609/my-cfg
aws s3 cp main.tf s3://prashantgohel1609
```

The synchronization process was remarkably clean. The command neatly grabbed all three files from my local directory and gracefully pushed them securely into a subfolder playfully named "my-cfg" sitting right inside my AWS bucket. I additionally copied the bare main file to the root bucket level just to test out the singular copy command. After pushing out the data, I naturally needed to verify my handiwork.

```bash
aws s3 ls s3://prashantgohel1609 --recursive --summarize --human-readable
```

Adding these phenomenal flags to the listing command radically changed the output. I was suddenly staring at a fully detailed report, beautifully showing a root-level main file alongside the three synced files nesting safely within the my-cfg prefix. The summarize and human-readable flags provided a lovely bottom-line summary letting me know there were basically four distinct objects soaking up a grand total of exactly 6.8 KiB in storage space. 

It had been an entirely productive learning path, but it was finally time to clean up my toys. I decided to destroy the bucket explicitly using the AWS CLI remove bucket command rather than relying on terraform for this specific destruction phase.

```bash
aws s3 rb s3://prashantgohel1609
```

I expected a clean break, but AWS quickly threw an error explicitly rejecting my attempt stating that the "bucket you tried to delete is not empty". And of course, checking earlier confirmed I shoved exactly four tiny files inside there. To overcome this safety check, I needed to leverage the almighty force flag.

```bash
aws s3 rb s3://prashantgohel1609 --force
```

Adding the force flag totally commanded my CLI to completely purge the contents. The console happily echoed the progressive deletion of every single file tucked inside the bucket structure, sequentially deleting the state file, the provider file, both versions of the main configuration file, and concluding by removing the bucket itself entirely form existence. The great Day 01 session was officially complete, leaving me incredibly excited for whatever the next chapter in my DevOps learning path decides to throw my way!
