# Cloud (AWS) Level 1, Task 4: Creating a VPC Subnet

Today's task was the logical next step in building my AWS network foundation. After learning what a VPC is, my objective was to create a **Subnet** inside that VPC. This is like taking the plot of land I've fenced off (the VPC) and dividing it into smaller, usable sections (the subnets) where I can actually build my resources.

This was a great exercise because it required me to first *find* the default VPC and then *create* a new subnet within its IP address range. I've documented both the fast, scriptable AWS CLI method and the visual AWS Console (UI) method, along with a detailed explanation of the concepts I learned. This is my first-person guide to that process.

## Table of Contents
- [Cloud (AWS) Level 1, Task 4: Creating a VPC Subnet](#cloud-aws-level-1-task-4-creating-a-vpc-subnet)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [Solution 1: The AWS CLI Method (Automation)](#solution-1-the-aws-cli-method-automation)
      - [Phase 1: Find the Default VPC ID](#phase-1-find-the-default-vpc-id)
      - [Phase 2: Create the Subnet](#phase-2-create-the-subnet)
      - [Phase 3: Verification](#phase-3-verification)
    - [Solution 2: The AWS Console Method (UI)](#solution-2-the-aws-console-method-ui)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: Public vs. Private Subnets](#deep-dive-public-vs-private-subnets)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the Commands and UI I Used](#exploring-the-commands-and-ui-i-used)
      - [**AWS CLI Method**](#aws-cli-method)
      - [**AWS Console (UI) Method**](#aws-console-ui-method)

---

### The Task
<a name="the-task"></a>
My objective was to create a new AWS EC2 Subnet. The requirements were:
1.  The subnet's name tag had to be `datacenter-subnet`.
2.  It had to be created inside the **default VPC**.
3.  The operation had to be performed in the `us-east-1` region.

---

### Solution 1: The AWS CLI Method (Automation)
<a name="solution-1-the-aws-cli-method-automation"></a>
This method is fast and scriptable. It's a two-step process: first, find the ID of the default VPC, and second, create the subnet within it.

#### Phase 1: Find the Default VPC ID
1.  I logged into the `aws-client` host.
2.  I used the `aws ec2 describe-vpcs` command with a filter to find the default VPC. This command returns a lot of data, so I used the `--query` flag to extract only the VPC ID.
    ```bash
    aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
    ```
    This command returned the VPC ID, which I copied (e.g., `vpc-12345678`).

#### Phase 2: Create the Subnet
Now that I had the `VpcId`, I could create the subnet. I also had to choose a valid CIDR block for my subnet that was *within* the VPC's main range (e.g., `172.31.0.0/16`). A good, standard choice for a new subnet is `172.31.80.0/24`.
```bash
aws ec2 create-subnet \
    --vpc-id vpc-12345678 \
    --cidr-block 172.31.80.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=datacenter-subnet}]' \
    --region us-east-1
```
*(Note: I had to specify an Availability Zone, as a subnet exists in only one AZ.)*

#### Phase 3: Verification
The command itself outputs a JSON block describing the newly created subnet. I could also have run `aws ec2 describe-subnets --filters "Name=tag:Name,Values=datacenter-subnet"` to find it.

---

### Solution 2: The AWS Console Method (UI)
<a name="solution-2-the-aws-console-method-ui"></a>
This method uses the graphical web interface and is very intuitive.

1.  **Login to AWS Console:** I used the provided URL, username (`kk_labs_user_904617`), and password to log in.
2.  **Navigate to VPC:** In the main console, I ensured my region was set to `us-east-1` (North Virginia). I then used the search bar to find and navigate to the **VPC** service.
3.  **Navigate to Subnets:** In the VPC dashboard's left-hand navigation pane, I clicked on **Subnets**.
4.  **Create Subnet:** I clicked the **"Create subnet"** button in the top right.
5.  **Fill in Details:**
    -   **VPC ID:** I clicked the dropdown and selected the **Default VPC**. The console helpfully showed its name and CIDR block (e.g., `172.31.0.0/16`).
    -   **Subnet name:** I entered `datacenter-subnet`.
    -   **Availability Zone:** I selected an AZ from the dropdown, like `us-east-1a`.
    -   **IPv4 CIDR block:** I entered a valid, non-overlapping subnet range, such as `172.31.80.0/24`.
6.  **Create:** I scrolled down and clicked the final **"Create subnet"** button. The subnet appeared in my dashboard.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **VPC (Virtual Private Cloud):** This is my private, isolated network in the AWS cloud. It's the "plot of land."
-   **Subnet (Subnetwork):** This is the most important concept of this task. A VPC is a large IP address range, but it's not usable on its own. It **must** be divided into smaller sections called **subnets**. A subnet is a "room" or "fenced-in area" within my VPC where I can actually place my resources, like EC2 instances.
-   **Why Subdivide?**
    1.  **Availability:** A subnet exists in a single **Availability Zone** (AZ), which is a physically separate datacenter. To build a highly-available application, I would create multiple subnets in different AZs (e.g., `subnet-a` in `us-east-1a` and `subnet-b` in `us-east-1b`) and place my servers in both.
    2.  **Security:** This is the most common reason. I can create different subnets for different security purposes. I can have **public subnets** for my web servers that are open to the internet, and **private subnets** for my databases that are completely locked down.
-   **Default VPC:** Every AWS account comes with a "default VPC" in each region. Its purpose is to make it easy for beginners to launch resources without having to manually configure a network from scratch. It's pre-configured with public subnets and an internet gateway.

---

### Deep Dive: Public vs. Private Subnets
<a name="deep-dive-public-vs-private-subnets"></a>
This task had me create a subnet, but what makes a subnet "public" or "private"? I learned it's not a setting on the subnet itself.
-   A subnet is **Public** if its associated **Route Table** has a route to an **Internet Gateway** (`0.0.0.0/0 -> igw-...`).
-   A subnet is **Private** if its Route Table does **not** have a route to an Internet Gateway.

By default, the *default VPC* has a main route table that sends traffic to an Internet Gateway, so any new subnet I create in it (like `datacenter-subnet`) is automatically a public subnet.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting the VPC ID:** The `vpc-id` is a required parameter for the CLI command. I had to look it up first.
-   **Invalid CIDR Block:** The most common error is choosing a CIDR block that is not a valid subset of the VPC's main CIDR. For example, if the VPC is `172.31.0.0/16`, my subnet CIDR **must** start with `172.31.x.x`.
-   **Overlapping CIDR Blocks:** If a subnet with the range `172.31.80.0/24` already existed, my command to create another one with the same range would fail. Each subnet in a VPC must have a unique IP range.

---

### Exploring the Commands and UI I Used
<a name="exploring-the-commands-and-ui-i-used"></a>
#### **AWS CLI Method**
-   `aws ec2 describe-vpcs --filters "Name=isDefault,Values=true"`: The command I used to find the ID of the default VPC.
-   `aws ec2 create-subnet --vpc-id ... --cidr-block ... --availability-zone ...`: The primary command for this task. It provisions a new network segment within a VPC.
-   `aws ec2 describe-subnets`: A useful verification command to list all subnets and check their state.

#### **AWS Console (UI) Method**
-   **VPC Dashboard > Subnets**: The main navigation path to the subnet management page.
-   **"Create subnet" button**: The primary UI element that launches the creation wizard, where I filled in the form with all the required specifications.
   