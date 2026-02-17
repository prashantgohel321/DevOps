# Cloud (AWS) Level 1, Task 1: Creating an EC2 Key Pair

Today marked my first step into managing AWS infrastructure from the command line. My objective was to create an **EC2 Key Pair**, which I learned is the fundamental component for securely accessing virtual servers in the AWS cloud.

This task was a fantastic introduction to the AWS Command Line Interface (CLI) and the core security principles behind public-key cryptography. Instead of just clicking a button in the web console, I used a specific command to generate the key and save the private portion securely. This document is my detailed, first-person guide to that entire process.

## Table of Contents
- [The Task](#the-task)
- [Solution 1: AWS CLI Method (Automation)](#my-step-by-step-solution)
- [Solution 2: The AWS Console Method (UI)](#solution-2-the-aws-console-method-ui)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: How Public-Key Authentication Works](#deep-dive-how-public-key-authentication-works)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands I Used](#exploring-the-commands-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to create a new AWS EC2 Key Pair. The specific requirements were:
1.  The key pair's name had to be `devops-kp`.
2.  The key type had to be `rsa`.
3.  The operation had to be performed in the `us-east-1` region.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The process involved running a single AWS CLI command and securely saving its output.

#### Phase 1: The Command
1.  I logged into the `aws-client` host, where the AWS CLI was pre-configured.
2.  I ran the `aws ec2 create-key-pair` command. This command is designed to do two things: it tells AWS to generate a key pair, and it returns the **private key** material back to me just this one time.
3.  To capture this private key, I used a shell redirection (`>`). The query and output arguments are crucial for extracting only the key material itself.

    ```bash
    aws ec2 create-key-pair \
        --key-name devops-kp \
        --key-type rsa \
        --query 'KeyMaterial' \
        --output text > devops-kp.pem
    ```

#### Phase 2: Securing the Private Key
The `.pem` file that was just created is my secret key. It's critical to lock it down so that only I can read it.
1.  I used the `chmod` command to set the file permissions to `400` (read-only for the owner).
    ```bash
    chmod 400 devops-kp.pem
    ```

#### Phase 3: Verification
The final step was to confirm that the file was created and had the correct permissions.
1.  I used the `ls -l` command.
    ```bash
    ls -l devops-kp.pem
    # Output: -r-------- 1 bob bob 2048 Oct 17 07:45 devops-kp.pem
    ```
2.  The `-r--------` permissions string confirmed that only the owner could read the file, and no one could write to or execute it. This was the definitive proof of success.

---

### Solution 2: The AWS Console Method (UI)
<a name="solution-2-the-aws-console-method-ui"></a> This method uses the graphical web interface and is great for beginners.

- **Login to AWS Console**: I used the provided URL, username, and password to log in.

- **Navigate to EC2**: In the main console, I used the search bar to find and navigate to the EC2 service.

- **Navigate to Key Pairs**: In the EC2 dashboard's left-hand navigation pane, under "Network & Security," I clicked on Key Pairs.

- **Create Key Pair**: I clicked the "Create key pair" button in the top right.

- **Fill in Details:**

    - **Name**: devops-kp

    - **Key pair type**: I selected RSA.

    - **Private key file format**: I left the default, .pem, which is the standard for use with SSH on Linux and macOS.

- **Create and Download**: I clicked the "Create key pair" button. The browser immediately downloaded the devops-kp.pem file. This is the only time I would be able to download this private key.

- **Secure the File**: Just like with the CLI method, after downloading the file, I would need to run chmod 400 devops-kp.pem on my local machine to set the correct permissions.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **EC2 (Elastic Compute Cloud):** This is the AWS service for creating virtual servers, which are called "instances."
-   **Key Pair:** This is the standard and secure way to control access to Linux-based EC2 instances. It is far more secure than using passwords. A key pair consists of two related cryptographic keys:
    1.  **Public Key (The "Lock"):** This is the part that I give to AWS. When I launch an EC2 instance, I tell it to install this public key. It acts like a custom-made lock on the server's door.
    2.  **Private Key (The "Key"):** This is the secret part that the `create-key-pair` command returns. I must download and keep this file safe. It is the only key in the world that can open the lock I placed on the server. I use this private key file with my SSH client to log in.

-   **AWS CLI:** The AWS Command Line Interface is a powerful tool that allows me to manage all my AWS services from a terminal. It's an essential tool for automation and scripting, as it allows me to do everything I could do in the web console, but in a repeatable, programmatic way.

---

### Deep Dive: How Public-Key Authentication Works
<a name="deep-dive-how-public-key-authentication-works"></a>
This task was a perfect demonstration of public-key cryptography, which is the foundation of modern secure communication.


1.  **The Connection:** When I try to SSH into my EC2 instance, my SSH client presents my private key (`devops-kp.pem`).
2.  **The Challenge:** The server has my public key. It generates a random, one-time-use message and encrypts it using this public key. It then sends this encrypted "challenge" back to my client.
3.  **The Response:** This encrypted message can **only** be decrypted by my corresponding private key. My client decrypts the message.
4.  **Proof of Identity:** My client sends the decrypted message back to the server.
5.  **Access Granted:** The server sees that I successfully decrypted the message, which mathematically proves I must be the owner of the private key. It grants me access without ever needing a password to be sent over the network.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Losing the Private Key:** The AWS `create-key-pair` command gives you the private key material **only once**. If you fail to save it to a file, you can never retrieve it again. You would have to delete the key pair in AWS and create a new one.
-   **Incorrect Private Key Permissions:** SSH is very strict for security reasons. If the permissions on my `.pem` file are too open (e.g., readable by other users), SSH will refuse to use the key and will give a "Permissions too open" error. `chmod 400` is the standard way to prevent this.
-   **Key Pair Name Conflict:** Key pair names must be unique within an AWS region. If a key pair named `devops-kp` already existed, my command would have failed.

---

### Exploring the Commands I Used
<a name="exploring-the-commands-i-used"></a>
-   `aws ec2 create-key-pair ...`: The main AWS CLI command for this task.
    -   `aws ec2`: Specifies that I want to interact with the EC2 service.
    -   `create-key-pair`: The specific action I want to perform.
    -   `--key-name devops-kp`: A required flag to name the key pair.
    -   `--key-type rsa`: A flag to specify the cryptographic algorithm.
    -   `--query 'KeyMaterial'`: This is a powerful feature of the AWS CLI. It filters the large JSON output that the command normally produces and extracts only the value of the `KeyMaterial` field (the private key itself).
    -   `--output text`: This formats the output as plain text instead of JSON, which is necessary to save it cleanly to a file.
-   `> devops-kp.pem`: This is a standard shell redirection operator. It takes the text output from the `aws` command and redirects it, saving it into a new file named `devops-kp.pem`.
-   `chmod 400 devops-kp.pem`: The Linux command to **ch**ange the permission **mod**e of a file. The octal code `400` translates to "read permission for the owner, and no permissions for anyone else," which is the standard, secure setting for a private SSH key.
-   `ls -l [file]`: The standard Linux command to **l**i**s**t a file in **l**ong format, which I used to view the permissions string and verify my `chmod` command was successful.

---

### AWS Console (UI) Method
- **EC2 Dashboard**: The central hub for managing all virtual server resources.

- **Network & Security > Key Pairs**: The specific section in the EC2 console where key pairs are managed.

- **"Create key pair" button**: The primary UI element that initiates the key creation wizard.