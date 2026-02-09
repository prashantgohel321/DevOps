# Cloud (AWS) Day 01: Create Key Pair

This document outlines the solution for the first task in the AWS migration strategy: creating a secure Key Pair. This credential is vital for securely connecting to future EC2 instances.

We will cover two methods to achieve this:
1.  **AWS Management Console (UI)** - Best for beginners and visual verification.
2.  **AWS Command Line Interface (CLI)** - Best for automation and scripts.

---

## Task Requirements
* **Resource:** Key Pair
* **Name:** `devops-kp`
* **Type:** `RSA`
* **Region:** `us-east-1` (N. Virginia)

---

## Glossary of Terms

Before diving in, here are explanations of the specific terms used in this task:

* **Key Pair:** A set of security credentials used to prove your identity when connecting to an instance (virtual server). It consists of a **Private Key** (stored by you) and a **Public Key** (stored by AWS). You cannot log into an EC2 instance without the private key.
* **RSA (Rivest–Shamir–Adleman):** A standard type of public-key encryption algorithm. It is the default and most widely supported type for SSH keys.
* **PEM (.pem):** A file format for storing the private key. This is typically used for Linux/Mac terminals (OpenSSH).
* **PPK (.ppk):** A file format used specifically by the Windows tool **PuTTY**.
* **Region:** A physical location around the world where AWS clusters data centers (e.g., `us-east-1` is in Northern Virginia). Resources created in one region are not automatically visible in others.

---

## Method 1: Using the AWS Management Console (UI)

This method involves clicking through the web interface.

### Step 1: Login
1.  Open the **Console URL** provided in the credentials.
2.  Enter the **Username** and **Password**.
3.  Ensure you are in the **N. Virginia (us-east-1)** region. You can check this in the top-right corner of the page.

### Step 2: Navigate to EC2
1.  In the search bar at the top, type `EC2`.
2.  Click on **EC2** under "Services".

### Step 3: Create the Key Pair
1.  In the left-hand navigation pane, scroll down to the **Network & Security** section.
2.  Click **Key Pairs**.
3.  Click the orange **Create key pair** button (top right).
4.  **Configuration:**
    * **Name:** Enter `devops-kp`.
    * **Key pair type:** Select `RSA`.
    * **Private key file format:**
        * Choose `.pem` if you are on Linux/Mac or using PowerShell.
        * Choose `.ppk` if you plan to use PuTTY on Windows.
5.  Click **Create key pair**.

### Step 4: Save the Key
* The browser will automatically download the private key file (`devops-kp.pem`).
* **Crucial:** Save this file securely. AWS **does not** keep a copy of the private key. If you lose this file, you cannot recover it.

---

## Method 2: Using the AWS CLI

This method is faster and allows you to stay in the terminal (`aws-client` host).

### Step 1: Configure Credentials (If needed)
If your terminal is not yet authenticated, run:
```bash
aws configure
```
* Enter `AWS Access Key ID` and `Secret Access Key` (found in the "IAM" section of the console or `showcreds` command output).
* **Default region name:** `us-east-1`
* **Default output format:** `json`

### Step 2: Create the Key Pair
Run the following command. This tells AWS to create the key and immediately saves the private key material to a file named `devops-kp.pem`.

```bash
aws ec2 create-key-pair \
    --key-name devops-kp \
    --key-type rsa \
    --query 'KeyMaterial' \
    --output text > devops-kp.pem
```

**Command Breakdown:**
* `aws ec2`: Calls the EC2 service.
* `create-key-pair`: The specific API action.
* `--key-name devops-kp`: Sets the name of the key in AWS.
* `--key-type rsa`: Specifies the encryption algorithm.
* `--query 'KeyMaterial'`: Filters the output to only show the private key text (ignores metadata like Fingerprint).
* `--output text`: Ensures the key is printed as plain text, not JSON strings (which would break the key format).
* `> devops-kp.pem`: Redirects that text into a physical file on your machine.

### Step 3: Secure the Key
Private keys must be protected. If the permissions are too open, SSH clients will refuse to use them.

```bash
chmod 400 devops-kp.pem
```
* **chmod 400:** Sets permissions so that only the owner can read the file. No one else can read or write to it.

### Step 4: Verification
To verify the key exists in AWS:

```bash
aws ec2 describe-key-pairs --key-names devops-kp
```

**Output**
```bash
{
    "KeyPairs": [
        {
            "KeyPairId": "key-0e1b5eaa5392022ba",
            "KeyType": "rsa",
            "Tags": [],
            "CreateTime": "2026-02-09T05:33:58.829Z",
            "KeyName": "devops-kp",
            "KeyFingerprint": "b1:ff:aa:db:a2:78:94:48:aa:f3:38:25:68:07:ae:8e:84:8d:58:df"
        }
    ]
}
```

showcreds output:
```bash
╒══════════════════════╤═════════════════════════════════════════════════════════════════════╕
│ Name                 │ Value                                                               │
╞══════════════════════╪═════════════════════════════════════════════════════════════════════╡
│ AWS Console URL      │ https://852719973844.signin.aws.amazon.com/console?region=us-east-1 │
├──────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ AWS User Name        │ kk_labs_user_183442                                                 │
├──────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ AWS Password         │ ceQ@Zu5G%X0Z                                                        │
├──────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ AWS Session End Time │ 2026-02-09T06:26:34Z                                                │
╘══════════════════════╧═════════════════════════════════════════════════════════════════════╛
```
