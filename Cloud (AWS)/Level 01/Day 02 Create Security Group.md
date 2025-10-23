# Cloud (AWS) Level 1, Task 2: Creating a Security Group

Today's task was a deep dive into a fundamental and critical aspect of cloud security: the **EC2 Security Group**. My objective was to create a virtual firewall for my application servers, defining specific rules to allow web traffic and administrative access.

This was a fantastic exercise because it allowed me to compare the two primary ways of managing AWS resources: the programmatic **AWS Command Line Interface (CLI)** and the graphical **AWS Management Console (UI)**. I've documented both methods below, explaining the core principles of cloud firewalls and why they are the first line of defense for any server. This is my detailed, first-person guide to that entire process.

## Table of Contents
- [The Task](#the-task)
- [Solution 1: The AWS CLI Method (Automation)](#solution-1-the-aws-cli-method-automation)
- [Solution 2: The AWS Console Method (UI)](#solution-2-the-aws-console-method-ui)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Anatomy of a Security Group Rule](#deep-dive-the-anatomy-of-a-security-group-rule)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands and UI I Used](#exploring-the-commands-and-ui-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a new AWS EC2 Security Group with specific firewall rules. The requirements were:
1.  The security group's name had to be `devops-sg`.
2.  It needed a description: `Security group for Nautilus App Servers`.
3.  It required two inbound rules:
    -   Allow HTTP traffic on port 80 from the entire internet (`0.0.0.0/0`).
    -   Allow SSH traffic on port 22 from the entire internet (`0.0.0.0/0`).
4.  The operation had to be performed in the `us-east-1` region.

---

### Solution 1: The AWS CLI Method (Automation)
<a name="solution-1-the-aws-cli-method-automation"></a>
This method is fast, scriptable, and the standard for automation. It involves a two-step process: first creating the group, then adding rules to it.

#### Phase 1: Create the Security Group
1.  I logged into the `aws-client` host, where the AWS CLI was pre-configured.
2.  I ran the `aws ec2 create-security-group` command. This command creates the empty security group "shell" and returns its unique `GroupId`, which is essential for the next step. I used a `bash` variable to capture this ID.
    ```bash
    GROUP_ID=$(aws ec2 create-security-group \
        --group-name "devops-sg" \
        --description "Security group for Nautilus App Servers" \
        --query 'GroupId' \
        --output text)
    ```

#### Phase 2: Add the Inbound Rules
With the Group ID captured, I used the `authorize-security-group-ingress` command twice to add my firewall rules.
1.  **Add HTTP Rule:**
    ```bash
    aws ec2 authorize-security-group-ingress \
        --group-id $GROUP_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0
    ```
2.  **Add SSH Rule:**
    ```bash
    aws ec2 authorize-security-group-ingress \
        --group-id $GROUP_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0
    ```

#### Phase 3: Verification
The final step was to confirm that the group was created with the correct rules.
```bash
aws ec2 describe-security-groups --group-names devops-sg
```
The JSON output of this command clearly showed the two inbound `IpPermissions`, one for port 22 and one for port 80, both from `0.0.0.0/0`.

---

### Solution 2: The AWS Console Method (UI)
<a name="solution-2-the-aws-console-method-ui"></a>
This method uses the graphical web interface and is great for beginners or for one-off tasks.

1.  **Login to AWS Console:** I used the provided URL, username, and password to log in.
2.  **Navigate to EC2:** I used the search bar to find and navigate to the **EC2** service.
3.  **Navigate to Security Groups:** In the EC2 dashboard's left-hand navigation pane, under "Network & Security," I clicked on **Security Groups**.
4.  **Create Security Group:** I clicked the **"Create security group"** button.
5.  **Fill in Basic Details:**
    -   **Security group name:** `devops-sg`
    -   **Description:** `Security group for Nautilus App Servers`
6.  **Add Inbound Rules:** In the "Inbound rules" section, I clicked **"Add rule"**.
    -   **Rule 1 (HTTP):**
        -   **Type:** `HTTP` (this automatically fills in TCP and port 80).
        -   **Source:** `Anywhere-IPv4` (this automatically fills in `0.0.0.0/0`).
    -   I clicked **"Add rule"** again.
    -   **Rule 2 (SSH):**
        -   **Type:** `SSH` (this automatically fills in TCP and port 22).
        -   **Source:** `Anywhere-IPv4` (this automatically fills in `0.0.0.0/0`).
7.  **Create:** I scrolled down and clicked the final **"Create security group"** button. The group was then visible in my list.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Security Group (SG):** I learned to think of a security group as a **stateful virtual firewall** that is attached to an EC2 instance. It acts as a gatekeeper, controlling what network traffic is allowed to reach the server.
-   **Stateful Firewall:** This is a key concept. "Stateful" means that if I allow an inbound connection (like a user visiting my website on port 80), the security group automatically allows the return traffic for that connection to go back out to the user, without me needing to create a separate outbound rule.
-   **Inbound (`ingress`) vs. Outbound (`egress`) Rules:**
    -   **Inbound:** Rules for traffic *coming into* the server. By default, a security group blocks **all** inbound traffic. This is a secure default; nothing is accessible until I explicitly allow it. My task was to create these rules.
    -   **Outbound:** Rules for traffic *leaving* the server. By default, a security group allows **all** outbound traffic.
-   **`0.0.0.0/0` (CIDR Block):** This is a special network address that means "the entire internet." By specifying this as the source for my rules, I was allowing anyone from anywhere to connect to my server on ports 80 and 22. For a public web server (port 80), this is necessary. For administrative access (port 22), this is a major security risk in production; I would normally restrict the source to my specific office or VPN IP address.

---

### Deep Dive: The Anatomy of a Security Group Rule
<a name="deep-dive-the-anatomy-of-a-security-group-rule"></a>
This task was all about defining rules. Each inbound rule has three main components.

[Image of an AWS security group firewall diagram]

-   **1. Protocol:** This specifies the type of internet traffic. For web (HTTP) and administrative (SSH) access, the protocol is almost always **TCP** (Transmission Control Protocol), which is a reliable, connection-oriented protocol.
-   **2. Port Range:** This is the specific "door" on the server that the traffic is destined for. Services listen on standard ports: HTTP on `80`, HTTPS on `443`, and SSH on `22`. My rules opened these specific doors.
-   **3. Source:** This is the "who." It defines where the traffic is allowed to come from. This can be a specific IP address, a range of IP addresses (a CIDR block), or even another security group.

So, my SSH rule can be read as: "Allow traffic using the **TCP** protocol, destined for **port 22**, coming from **any IP address in the world**."

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting to Add Rules:** Creating a security group is not enough. If I create a group and attach it to an instance without adding any inbound rules, the instance will be completely unreachable.
-   **Using the Wrong Source CIDR:** A common and dangerous mistake is to accidentally restrict SSH access to the wrong IP address, effectively locking yourself out of your own server.
-   **Confusing Security Groups with Network ACLs:** In AWS, there is another firewall layer called a Network ACL, which operates at the subnet level. Security Groups operate at the instance level and are generally easier to manage and the first line of defense.

---

### Exploring the Commands and UI I Used
<a name="exploring-the-commands-and-ui-i-used"></a>
#### **AWS CLI Method**
-   `aws ec2 create-security-group --group-name "..." --description "..."`: The command to create the empty security group shell.
-   `aws ec2 authorize-security-group-ingress --group-id "..." --protocol "..." --port "..." --cidr "..."`: The command to add a new inbound (ingress) rule to an existing security group. I had to run this for each rule.
-   `aws ec2 describe-security-groups --group-names "..."`: My verification command, which shows a detailed JSON description of a security group and its rules.

#### **AWS Console (UI) Method**
-   **EC2 Dashboard > Network & Security > Security Groups**: The main navigation path to the security group management page.
-   **"Create security group" button**: The primary UI element that launches the creation wizard.
-   **"Inbound rules" > "Add rule"**: The section of the wizard where I defined my HTTP and SSH rules.
   