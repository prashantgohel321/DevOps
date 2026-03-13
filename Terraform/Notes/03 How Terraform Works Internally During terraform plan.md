# How Terraform Works Internally During `terraform plan`

## What the Plan Stage Actually Means

The `terraform plan` command is the stage where Terraform performs **analysis of infrastructure** without actually creating or modifying anything. The purpose of this stage is to calculate what actions must occur in order to transform the current infrastructure into the desired infrastructure described in the configuration files.

At this moment Terraform is doing something very similar to how a compiler prepares an execution plan before running a program. It reads configuration, loads existing state, queries providers, builds dependency graphs, and calculates the difference between the current state and the desired state.

This difference is called the **execution plan**.

The execution plan is essentially Terraform saying:

“Based on your configuration and the current infrastructure, here is exactly what I will do.”

Nothing is created yet. Terraform is only computing the actions.

---

# Stage 1 — Terraform CLI Starts Again

When the command runs

```
terraform plan
```

Terraform starts its command-line runtime again.

From your logs:

```
Terraform version: 1.14.7
Go runtime version: go1.25.8
CLI args: []string{"terraform", "plan"}
```

Terraform again loads its internal libraries and prepares the execution environment. The libraries shown in logs such as `hcl`, `go-tfe`, and `cty` are internal packages used by Terraform.

For example:

**HCL library**

This library parses Terraform configuration files written in HashiCorp Configuration Language. It converts configuration text into an internal structure Terraform can analyze.

**CTY library**

CTY is Terraform’s internal type system. It represents values like strings, numbers, lists, objects, and maps.

For example the value:

```
bucket = "prashant-terraform-demmo-bucket-001"
```

is internally converted into a CTY string type.

Terraform uses this internal data structure to compute plans.

---

# Stage 2 — CLI Configuration Check

Terraform again checks the optional CLI configuration file.

From logs:

```
Attempting to open CLI config file: /root/.terraformrc
File doesn't exist, but doesn't need to. Ignoring.
```

This file could contain settings such as:

* credentials for Terraform Cloud
* provider mirrors
* plugin caching rules

Since it doesn't exist, Terraform simply continues.

---

# Stage 3 — Provider Plugin Discovery

Terraform again checks provider plugin directories.

```
ignoring non-existing provider search directory
```

Even though providers were already downloaded during `terraform init`, Terraform still checks the known directories to locate plugins.

Eventually Terraform identifies the provider inside the project directory:

```
.terraform/providers/registry.terraform.io/hashicorp/aws/6.36.0
```

This plugin was installed earlier during initialization.

---

# Stage 4 — Terraform Starts the Backend Plan Operation

The next line in your logs is important:

```
backend/local: starting Plan operation
```

This means Terraform is starting the **planning phase inside the configured backend**.

Your backend is **local**, which means Terraform will read and store state files in the local filesystem.

The backend is responsible for:

* loading the current Terraform state
* coordinating plan calculations
* managing state locking (in remote backends)

---

# Stage 5 — Terraform Launches the Provider Plugin

Terraform now starts the AWS provider plugin.

From logs:

```
starting plugin:
.terraform/providers/.../terraform-provider-aws_v6.36.0
```

This means Terraform launches the provider as a **separate process**.

This is a very important internal design of Terraform.

Terraform does not embed providers directly into the main binary. Instead, providers run as **independent plugins**.

This architecture provides several advantages:

* providers can be updated independently
* crashes inside providers do not crash Terraform itself
* Terraform can support thousands of providers without growing huge

---

# Stage 6 — RPC Communication Between Terraform and Provider

After starting the plugin, Terraform establishes communication with it.

From logs:

```
waiting for RPC address
plugin address: address=/tmp/plugin1463399216 network=unix
```

Terraform communicates with providers using **RPC**, which stands for Remote Procedure Call.

A Remote Procedure Call is a mechanism where one process asks another process to execute a function.

Even though both processes run on the same machine, they communicate through an interface that behaves like network communication.

Terraform and the provider communicate through:

```
Unix socket
```

in your case:

```
/tmp/plugin1463399216
```

Terraform sends requests like:

* validate resource configuration
* read resource state
* calculate resource changes

The provider responds with structured data.

---

# Stage 7 — Provider Initialization

Next the provider initializes itself.

From logs:

```
Creating Terraform AWS Provider
Initializing Terraform AWS Provider
```

The AWS provider loads its internal logic that understands how to manage AWS services.

For example it loads code responsible for resources such as:

* aws_instance
* aws_s3_bucket
* aws_vpc
* aws_security_group

Each of these resources has internal logic describing:

* required arguments
* optional attributes
* API calls required to create the resource

---

# Stage 8 — Validation Graph Construction

Now Terraform begins building something very important internally.

From logs:

```
Building and walking validate graph
```

Terraform represents infrastructure using a **directed graph**, called a **dependency graph**.

A graph is a structure consisting of nodes and edges.

In Terraform:

Nodes represent resources.

Edges represent dependencies between resources.

Example:

```
aws_vpc → aws_subnet → aws_instance
```

This means:

VPC must exist before subnet, and subnet must exist before instance.

Terraform constructs this graph by analyzing references inside the configuration.

Example:

```
subnet_id = aws_subnet.public.id
```

This tells Terraform that the instance depends on the subnet.

Terraform then performs validation across the graph.

From logs:

```
ProviderTransformer
ReferenceTransformer
```

These internal components attach providers and resolve references between resources.

---

# Stage 9 — Graph Walk for Validation

After building the validation graph Terraform begins walking through it.

From logs:

```
Starting graph walk: walkValidate
```

Graph walking means Terraform visits each node in the dependency graph and validates it.

During this stage Terraform checks things like:

* whether required arguments exist
* whether attribute types are correct
* whether references are valid

If something is incorrect Terraform stops here and shows an error.

---

# Stage 10 — Plan Graph Construction

Once validation succeeds Terraform builds another graph.

From logs:

```
Building and walking plan graph for NormalMode
```

The **plan graph** determines what Terraform must do to reach the desired infrastructure state.

Terraform compares three things:

1. Configuration files
2. Current state file
3. Real infrastructure

The difference between them determines the plan.

---

# Stage 11 — Provider Configuration

Now Terraform configures the provider using the provider block in your configuration.

```
provider "aws" {
  region = "ap-south-1"
}
```

The logs show this stage:

```
Configuring Terraform AWS Provider
Resolving credentials provider
Retrieving credentials
```

Terraform loads AWS credentials.

From logs:

```
credentials_source = SharedConfigCredentials: /root/.aws/credentials
```

This means Terraform found credentials in:

```
~/.aws/credentials
```

This file is part of AWS CLI configuration.

---

# Stage 12 — AWS Identity Verification

Next the provider verifies the AWS identity.

From logs:

```
Retrieving caller identity from STS
```

Terraform calls the AWS **STS API**.

STS stands for **Security Token Service**.

This API allows applications to verify the identity of the credentials being used.

The API call:

```
GetCallerIdentity
```

returns information such as:

* AWS account ID
* IAM user or role
* ARN (Amazon Resource Name)

From logs:

```
Account: 859086474847
User: prashantgohel
```

This confirms that Terraform has valid AWS credentials.

---

# Stage 13 — State Inspection

Terraform now checks whether the resource already exists in state.

From logs:

```
Resource instance state not found
```

This means Terraform checked the state file and found no existing resource named:

```
aws_s3_bucket.my_first_bucket
```

Because this is the first run, the state file does not yet contain this resource.

---

# Stage 14 — Refresh Phase

Terraform normally refreshes resource state from the real infrastructure.

However your logs show:

```
no state, so not refreshing
```

Since the resource does not yet exist in state, Terraform skips refresh.

---

# Stage 15 — Plan Calculation

Now Terraform calculates the execution plan.

Terraform determines that the resource does not exist but is defined in configuration.

Therefore the required action is:

```
+ create
```

Your plan output shows:

```
aws_s3_bucket.my_first_bucket will be created
```

Terraform now calculates all attributes that will exist after creation.

Some values are known immediately:

```
bucket = "prashant-terraform-demmo-bucket-001"
region = "ap-south-1"
```

Other attributes will only exist after AWS creates the bucket.

For example:

```
arn
bucket_domain_name
hosted_zone_id
```

Terraform shows these as:

```
known after apply
```

---

# Stage 16 — Apply Graph Simulation

Before finishing, Terraform builds the **apply graph**.

From logs:

```
building apply graph to check for errors
```

This simulates the resource creation sequence.

Terraform ensures that dependency order is correct and no circular dependencies exist.

If a circular dependency existed Terraform would fail here.

---

# Stage 17 — Final Plan Output

Finally Terraform prints the execution plan.

```
Plan: 1 to add, 0 to change, 0 to destroy
```

This means:

* one resource will be created
* no existing resources will change
* nothing will be deleted

Terraform then displays the exact resource configuration it plans to create.

---

# Important Note About Plan Files

Your output ends with this message:

```
You didn't use the -out option
```

This refers to saving the plan.

Example:

```
terraform plan -out=tfplan
```

This saves the execution plan into a binary file.

Later Terraform can apply exactly that plan:

```
terraform apply tfplan
```

This ensures that the exact plan you reviewed is executed without recalculating it.

---

# Full Internal Flow of `terraform plan`

Internally the process looks like this:

1. Terraform CLI starts
2. Configuration files are parsed using HCL
3. Provider plugins are located
4. Backend loads Terraform state
5. Provider plugin process starts
6. RPC communication channel is established
7. Provider configuration is loaded
8. Credentials are retrieved
9. AWS identity is verified using STS
10. Terraform builds validation graph
11. Terraform builds plan graph
12. State file is inspected
13. Infrastructure refresh occurs if state exists
14. Terraform computes resource changes
15. Apply graph is simulated
16. Execution plan is printed

---
