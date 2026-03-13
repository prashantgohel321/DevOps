# How Terraform Works Internally During `terraform apply`

## Understanding the Purpose of the Apply Stage

The `terraform apply` command is the stage where Terraform actually **executes infrastructure changes**. Until this moment Terraform has only analyzed configuration and calculated what should happen. The `plan` stage computes the execution plan, but no infrastructure is modified.

The `apply` stage takes that execution plan and performs the real operations required to make the infrastructure match the configuration.

Internally this stage is more complex than it appears because Terraform must carefully execute operations in the correct order, communicate with providers, monitor results, update state, and maintain consistency.

From a conceptual perspective, Terraform is performing the following transformation:

Desired Infrastructure (Configuration)
→ Compare with Current Infrastructure (State)
→ Generate Execution Plan
→ Execute Plan Safely

The `apply` command is where the final step happens.

---

# Stage 1 — Terraform CLI Initialization

When you run:

```
terraform apply
```

Terraform starts its CLI runtime again.

From logs:

```
Terraform version: 1.14.7
Go runtime version: go1.25.8
CLI args: []string{"terraform", "apply"}
```

Terraform loads its internal modules responsible for:

* parsing configuration
* managing state
* executing graphs
* communicating with providers

Just like `plan`, Terraform again loads internal libraries such as:

* HCL parser (reads Terraform configuration)
* CTY type system (internal data representation)
* Terraform core runtime

These components convert configuration files into internal structures that Terraform can analyze and execute.

---

# Stage 2 — CLI Configuration Lookup

Terraform again checks whether the CLI configuration file exists.

```
Attempting to open CLI config file: /root/.terraformrc
```

This file could contain provider mirrors or Terraform Cloud credentials. Since it does not exist, Terraform proceeds normally.

---

# Stage 3 — Provider Plugin Discovery

Terraform now searches for provider plugins.

The logs show Terraform scanning directories like:

```
terraform.d/plugins
/root/.terraform.d/plugins
/usr/local/share/terraform/plugins
```

These are standard directories where Terraform may locate provider binaries.

Since the AWS provider was already installed during `terraform init`, Terraform locates the plugin inside the project directory:

```
.terraform/providers/registry.terraform.io/hashicorp/aws/6.36.0
```

This is where Terraform keeps provider executables for the project.

---

# Stage 4 — Backend Starts Apply Operation

Next Terraform starts the backend execution stage.

From logs:

```
backend/local: starting Apply operation
```

The backend is the component responsible for storing and managing Terraform state.

Since your configuration did not specify a remote backend, Terraform is using the **local backend**, which stores the state file locally.

The backend now prepares the state management system that will track infrastructure changes.

---

# Stage 5 — Terraform Launches the Provider Plugin

Terraform now launches the AWS provider plugin.

```
starting plugin:
terraform-provider-aws_v6.36.0
```

Just like during planning, the provider runs as a **separate process**.

This architecture is intentional. Terraform Core does not contain code for managing AWS, Azure, Kubernetes, or other platforms. Instead, Terraform communicates with specialized provider plugins that contain platform-specific logic.

This separation allows providers to evolve independently without modifying Terraform Core.

---

# Stage 6 — RPC Communication Setup

After launching the plugin, Terraform establishes a communication channel.

From logs:

```
waiting for RPC address
plugin address: /tmp/plugin1940617563
```

Terraform communicates with providers using **RPC (Remote Procedure Calls)**.

A remote procedure call is a method that allows one process to execute functions in another process.

Although both processes run on the same machine, Terraform treats the provider like a remote service. This makes the architecture modular and scalable.

Communication occurs through a **Unix socket**.

Example path:

```
/tmp/plugin1940617563
```

Terraform sends requests such as:

* validate resource configuration
* create resource
* update resource
* delete resource
* read resource state

The provider receives these requests and executes the corresponding cloud API calls.

---

# Stage 7 — Configuration Validation

Terraform now begins validating the configuration again.

Logs show:

```
Building and walking validate graph
```

Terraform constructs a **validation graph**, which is an internal representation of resources and their dependencies.

Each resource becomes a node in the graph.

For example:

```
aws_s3_bucket.my_first_bucket
```

Terraform attaches the required provider to that node:

```
ProviderTransformer
```

This step ensures the resource is associated with the correct provider plugin.

Next Terraform resolves references between resources:

```
ReferenceTransformer
```

If one resource referenced another resource's output, Terraform would detect that dependency here.

---

# Stage 8 — Plan Calculation Inside Apply

One important internal behavior is that `terraform apply` runs a **plan internally**.

From logs:

```
backend/local: apply calling Plan
```

Terraform does this because the execution plan must always be recalculated unless the user provides a saved plan file.

Terraform again compares:

* configuration files
* Terraform state
* real infrastructure

This produces the execution plan that Terraform will execute.

In your case:

```
Plan: 1 to add, 0 to change, 0 to destroy
```

Terraform determines that the S3 bucket must be created.

---

# Stage 9 — User Approval

Terraform then asks for confirmation before performing actions.

```
Do you want to perform these actions?
```

This confirmation step prevents accidental infrastructure modifications.

Only when the user enters:

```
yes
```

does Terraform begin executing the apply phase.

---

# Stage 10 — Apply Graph Construction

After approval Terraform builds the **apply graph**.

From logs:

```
Building and walking apply graph
```

This graph represents the exact order in which resources must be created, updated, or destroyed.

Each node in the graph represents a resource operation.

Example:

```
aws_s3_bucket.my_first_bucket → create
```

Terraform walks through this graph to execute infrastructure operations in the correct dependency order.

If multiple resources are independent, Terraform can even execute them in parallel.

---

# Stage 11 — Provider Configuration

Terraform now configures the AWS provider.

From logs:

```
Retrieving credentials
Retrieved credentials from /root/.aws/credentials
```

Terraform loads AWS credentials from the AWS CLI configuration file:

```
~/.aws/credentials
```

Next Terraform verifies the identity of the credentials.

---

# Stage 12 — AWS Identity Verification

Terraform calls the AWS **Security Token Service (STS)**.

The request is:

```
GetCallerIdentity
```

This API verifies:

* the AWS account
* the IAM user or role
* the ARN of the identity

From logs:

```
Account: 859086474847
User: prashantgohel
```

This confirms that Terraform has valid AWS credentials and is authorized to perform operations.

---

# Stage 13 — Resource Creation Begins

Terraform now begins executing the planned action.

From logs:

```
aws_s3_bucket.my_first_bucket: Creating...
```

Terraform sends a request to the AWS provider:

```
ApplyResourceChange
```

This instructs the provider to perform the resource creation.

---

# Stage 14 — AWS API Request for Bucket Creation

The AWS provider constructs an HTTP request to the AWS S3 API.

From logs:

```
PUT https://prashant-terraform-demmo-bucket-001.s3.ap-south-1.amazonaws.com
```

This request contains:

* bucket name
* region
* configuration
* tags

Example payload:

```
<CreateBucketConfiguration>
  <LocationConstraint>ap-south-1</LocationConstraint>
</CreateBucketConfiguration>
```

Terraform sends this request using the AWS SDK.

---

# Stage 15 — AWS Creates the Resource

AWS processes the request and returns a success response.

From logs:

```
HTTP Response Received
StatusCode: 200
```

This indicates the S3 bucket was successfully created.

---

# Stage 16 — Terraform Verifies Resource State

After creating the bucket Terraform verifies that the resource actually exists.

Terraform performs several API calls such as:

```
HeadBucket
GetBucketPolicy
GetBucketAcl
GetBucketVersioning
GetBucketLogging
GetBucketEncryption
```

These API calls retrieve the configuration of the bucket.

Terraform performs these checks because the provider must determine the **final state of the resource**.

For example, AWS may automatically assign attributes such as:

* bucket ARN
* hosted zone ID
* encryption configuration

Terraform reads these values so it can store them in the state file.

---

# Stage 17 — Handling Missing Optional Configurations

Some API calls return errors such as:

```
NoSuchBucketPolicy
NoSuchCORSConfiguration
NoSuchWebsiteConfiguration
```

These are not failures.

They simply mean that optional configurations do not exist for the bucket.

Terraform expects this and continues normally.

---

# Stage 18 — State File Update

After the resource is successfully created Terraform updates the state file.

The state file contains mappings like:

```
resource: aws_s3_bucket.my_first_bucket
id: prashant-terraform-demmo-bucket-001
region: ap-south-1
arn: arn:aws:s3:::prashant-terraform-demmo-bucket-001
```

This file is stored as:

```
terraform.tfstate
```

The state file allows Terraform to know that the bucket now exists.

---

# Stage 19 — Provider Plugin Shutdown

After finishing the operation Terraform closes the provider plugin.

From logs:

```
provider: plugin process exited
```

Since the operation is complete, the provider process is terminated.

---

# Stage 20 — Final Result

Terraform prints the final execution result:

```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed
```

This means:

* one resource was successfully created
* no resources were modified
* no resources were deleted

Your AWS infrastructure now contains the S3 bucket defined in the configuration.

---

# Complete Internal Flow of `terraform apply`

Internally Terraform performs the following sequence:

1. Terraform CLI starts
2. Configuration files are parsed
3. Provider plugins are located
4. Backend initializes state management
5. Provider plugin process starts
6. RPC communication channel is established
7. Configuration validation graph is built
8. Terraform internally runs a planning phase
9. Execution plan is generated
10. User approval is requested
11. Apply dependency graph is constructed
12. Terraform executes resource operations
13. Provider sends API requests to AWS
14. AWS creates the resource
15. Terraform reads resulting resource attributes
16. Terraform updates the state file
17. Provider plugin shuts down
18. Terraform reports final results

---
