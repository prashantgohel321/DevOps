# Cloud (AWS) Level 1, Task 3: Creating a GP3 EBS Volume

Today's task was about provisioning a fundamental component of any cloud server: a persistent storage volume. My objective was to create a new **AWS EBS Volume**, which I learned is like a virtual hard drive for my EC2 instances.

This was a great exercise because it's a very common task, and the requirements were specific about the volume type (`gp3`) and size. I've documented both the fast, scriptable AWS CLI method and the visual AWS Console (UI) method, along with a detailed explanation of the concepts I learned. This is my first-person guide to that process.

## Table of Contents
- [Cloud (AWS) Level 1, Task 3: Creating a GP3 EBS Volume](#cloud-aws-level-1-task-3-creating-a-gp3-ebs-volume)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [Solution 1: The AWS CLI Method (Automation)](#solution-1-the-aws-cli-method-automation)
      - [Phase 1: The Command](#phase-1-the-command)
      - [Phase 2: Verification](#phase-2-verification)
    - [Solution 2: The AWS Console Method (UI)](#solution-2-the-aws-console-method-ui)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The Anatomy of the `create-volume` CLI Command](#deep-dive-the-anatomy-of-the-create-volume-cli-command)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the Commands and UI I Used](#exploring-the-commands-and-ui-i-used)
      - [**AWS CLI Method**](#aws-cli-method)
      - [**AWS Console (UI) Method**](#aws-console-ui-method)

---

### The Task
<a name="the-task"></a>
My objective was to create a new AWS EBS (Elastic Block Store) Volume with specific parameters. The requirements were:
1.  The volume's name tag had to be `nautilus-volume`.
2.  The volume type had to be `gp3`.
3.  The volume size had to be `2 GiB`.
4.  The operation had to be performed in the `us-east-1` region.

---

### Solution 1: The AWS CLI Method (Automation)
<a name="solution-1-the-aws-cli-method-automation"></a>
This method is fast, scriptable, and my preferred approach for repeatable tasks. It involves running a single command from the `aws-client` host.

#### Phase 1: The Command
1.  I logged into the `aws-client` host.
2.  I ran the `aws ec2 create-volume` command. This single command specifies all the requirements: size, volume type, the Availability Zone (a volume must exist in one AZ), and the name tag.
    ```bash
    aws ec2 create-volume \
        --size 2 \
        --volume-type gp3 \
        --availability-zone us-east-1a \
        --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=nautilus-volume}]'
    ```
    *(Note: I had to pick an Availability Zone within my `us-east-1` region. `us-east-1a` is a standard choice.)*

#### Phase 2: Verification
The command itself outputs a JSON block describing the newly created volume. This output is the confirmation of success. I could also have run `aws ec2 describe-volumes --filters Name=tag:Name,Values=nautilus-volume` to find it.

---

### Solution 2: The AWS Console Method (UI)
<a name="solution-2-the-aws-console-method-ui"></a>
This method uses the graphical web interface and is great for visualizing the process.

1.  **Login to AWS Console:** I used the provided URL, username (`kk_labs_user_192329`), and password to log in.
2.  **Navigate to EC2:** In the main console, I used the search bar to find and navigate to the **EC2** service.
3.  **Navigate to Volumes:** In the EC2 dashboard's left-hand navigation pane, under "Elastic Block Store," I clicked on **Volumes**.
4.  **Create Volume:** I clicked the **"Create volume"** button in the top right.
5.  **Fill in Details:**
    -   **Volume type:** I selected `General Purpose SSD (gp3)`.
    -   **Size (GiB):** I entered `2`.
    -   **Availability Zone:** I selected `us-east-1a`.
    -   **Tags:** I added a tag with `Key: Name` and `Value: nautilus-volume`.
6.  **Create:** I clicked the final **"Create volume"** button. The volume appeared in my dashboard in a "creating" state and then quickly became "available."

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **EBS (Elastic Block Store) Volume:** I learned to think of an EBS volume as a **virtual hard drive in the cloud**. It's a raw block storage device that I can attach to an EC2 instance. Once attached, I can format it with a filesystem (like `ext4` or `xfs`) and mount it, just like a physical disk.
-   **Persistence (The Core Concept):** The most critical feature of an EBS volume is that its lifecycle is **independent of any server**. The main disk of an EC2 instance is often *ephemeral* (it's deleted when the instance is terminated). An EBS volume, however, is **persistent**. If my server fails, I can terminate it, launch a new one, and attach the exact same EBS volume to the new server, and all my data will still be there. This makes EBS essential for any stateful application, such as:
    -   Databases (like MySQL or PostgreSQL).
    -   Application log storage.
    -   File servers or user upload directories.
-   **`gp3` Volume Type:** AWS offers different EBS types. `gp3` is the latest generation of General Purpose SSD volumes. It's the recommended choice for most workloads because it provides an excellent baseline performance and, unlike its predecessor `gp2`, allows me to scale performance (IOPS and throughput) independently from the disk size.

---

### Deep Dive: The Anatomy of the `create-volume` CLI Command
<a name="deep-dive-the-anatomy-of-the-create-volume-cli-command"></a>
This task was a perfect demonstration of the power of the AWS CLI.

[Image of an EBS volume being attached to an EC2 instance]

```bash
aws ec2 create-volume \
    --size 2 \
    --volume-type gp3 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=nautilus-volume}]'
```
-   `aws ec2 create-volume`: The main command, telling the AWS API that I want to create a new volume in the EC2 service.
-   `--size 2`: A required argument specifying the size in GiB.
-   `--volume-type gp3`: A required argument specifying the performance profile.
-   `--availability-zone us-east-1a`: A required argument that tells AWS *which datacenter* within the `us-east-1` region to create the volume in. This is a crucial choice, as the volume can **only** be attached to an EC2 instance in the same Availability Zone.
-   `--tag-specifications '...'`: This is the standard, structured way to add tags to a resource upon creation. The `ResourceType=volume` specifies I'm tagging the volume itself, and the `Tags` list contains my `Name` tag.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Availability Zone (AZ) Mismatch:** The most common real-world error is creating a volume in one AZ (e.g., `us-east-1a`) and trying to attach it to an EC2 instance in another AZ (e.g., `us-east-1b`). This will always fail.
-   **Forgetting to Attach:** Creating a volume is just the first step. It doesn't do anything until it's attached to an instance, formatted, and mounted by the operating system.
-   **Cost of Unused Volumes:** An EBS volume that is `available` (not attached) still incurs storage costs. It's crucial to delete any unneeded volumes to avoid surprise bills.

---

### Exploring the Commands and UI I Used
<a name="exploring-the-commands-and-ui-i-used"></a>
#### **AWS CLI Method**
-   `aws ec2 create-volume --size ... --volume-type ... --availability-zone ...`: The primary command for this task. It provisions a new, persistent block storage device with the specified parameters.
-   `aws ec2 describe-volumes`: A useful verification command to list all volumes in my account and check their state (`creating`, `available`, `in-use`).

#### **AWS Console (UI) Method**
-   **EC2 Dashboard > Elastic Block Store > Volumes**: The main navigation path to the volumes management page.
-   **"Create volume" button**: The primary UI element that launches the creation wizard, where I filled in the form with all the required specifications.
   