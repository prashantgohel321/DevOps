# Linux Lab 14: SSH and SCP - Secure Remote Access

This lab covers the essential skills for managing remote servers securely. You will learn about the SSH protocol, how to connect to servers, how to set up password-less authentication for automation and ease of use, and how to transfer files securely using SCP.

## Table of Contents
- [Linux Lab 14: SSH and SCP - Secure Remote Access](#linux-lab-14-ssh-and-scp---secure-remote-access)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. SSH Default Port](#1-ssh-default-port)
      - [2. Identifying the SSH User](#2-identifying-the-ssh-user)
      - [3. Password-less SSH Setup Overview](#3-password-less-ssh-setup-overview)
      - [4. Generating SSH Keys (ssh-keygen)](#4-generating-ssh-keys-ssh-keygen)
      - [5. Locating the Public Key](#5-locating-the-public-key)
      - [6. Copying the Key to the Server (ssh-copy-id)](#6-copying-the-key-to-the-server-ssh-copy-id)
      - [7. Understanding Authorized Keys](#7-understanding-authorized-keys)
      - [8. Transferring Files with SCP](#8-transferring-files-with-scp)
    - [Command Reference](#command-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **SSH (Secure Shell):** A cryptographic network protocol for operating network services securely over an unsecured network. It is the standard for remote server administration.
* **Port 22:** The standard TCP port assigned to the SSH protocol.
* **Key Pair:** A pair of cryptographic keys used for authentication.
    * **Private Key (`id_rsa`):** Kept secret on your local machine. It proves your identity.
    * **Public Key (`id_rsa.pub`):** Shared with remote servers. It allows them to verify your identity.
* **`ssh-copy-id`:** A utility that simplifies the process of copying your public key to a remote server's `authorized_keys` file.
* **SCP (Secure Copy Protocol):** A means of securely transferring computer files between a local host and a remote host or between two remote hosts.

[Image of ssh key authentication process]

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. SSH Default Port
<a name="1-ssh-default-port"></a>
**Question:** Which port number does the SSH service use by default?
**Answer:** `22`

**Explanation:**
SSH listens on port 22 by default. This is a well-known port reserved for this service. You can verify this by looking at `/etc/ssh/sshd_config` or `/etc/services`.

#### 2. Identifying the SSH User
<a name="2-identifying-the-ssh-user"></a>
**Question:** If you run `ssh devapp01`, which user are you using to connect?
**Answer:** `bob`

**Explanation:**
If you do not specify a username (e.g., `ssh user@host`), SSH defaults to using the **current username** of the local session. Since you are logged into `caleston-lp10` as `bob`, `ssh devapp01` attempts to connect as `bob@devapp01`.

#### 3. Password-less SSH Setup Overview
<a name="3-password-less-ssh-setup-overview"></a>
**Goal:** Connect to `devapp01` without typing the password `caleston123` every time.
**Method:** Use RSA key-based authentication.

#### 4. Generating SSH Keys (ssh-keygen)
<a name="4-generating-ssh-keys-ssh-keygen"></a>
**Task:** Generate an RSA key pair.
**Command:**
```bash
ssh-keygen -t RSA
```
* `-t RSA`: Specifies the type of key to create.
* **Prompts:** You can press Enter through all prompts (file location and passphrase) to accept defaults for this lab.
* **Result:** Creates a private key (`~/.ssh/id_rsa`) and a public key (`~/.ssh/id_rsa.pub`).

#### 5. Locating the Public Key
<a name="5-locating-the-public-key"></a>
**Question:** What is the path to the public key created?
**Answer:** `/home/bob/.ssh/id_rsa.pub`

**Explanation:**
The output of the `ssh-keygen` command explicitly states: `Your public key has been saved in /home/bob/.ssh/id_rsa.pub.`

#### 6. Copying the Key to the Server (ssh-copy-id)
<a name="6-copying-the-key-to-the-server-ssh-copy-id"></a>
**Task:** Install the public key on `devapp01`.
**Command:**
```bash
ssh-copy-id bob@devapp01
```
**Explanation:**
* This script logs into the remote server (you will need to enter the password `caleston123` one last time).
* It automatically appends your public key to the remote user's `~/.ssh/authorized_keys` file.
* It sets the correct permissions on the file and directory.

**Verification:**
Run `ssh bob@devapp01`. You should log in immediately without a password prompt.

#### 7. Understanding Authorized Keys
<a name="7-understanding-authorized-keys"></a>
**Question:** Which file on the target server is the public key copied into?
**Answer:** `authorized_keys`

**Explanation:**
The SSH daemon (`sshd`) on the remote server looks at the `~/.ssh/authorized_keys` file to find a list of public keys that are allowed to access that account. `ssh-copy-id` manages this file for you.

#### 8. Transferring Files with SCP
<a name="8-transferring-files-with-scp"></a>
**Task:** Copy `/home/bob/caleston-code.tar.gz` to `devapp01` in Bob's home directory.
**Command:**
```bash
scp /home/bob/caleston-code.tar.gz devapp01:/home/bob
```

**Explanation:**
* **`scp`**: The command (Secure Copy).
* **Source:** `/home/bob/caleston-code.tar.gz` (Local file).
* **Destination:** `devapp01:/home/bob` (Remote host : Remote path).
* Since password-less SSH is set up, this transfer happens instantly without prompting for a password.

---

### Command Reference
<a name="command-reference"></a>

| Command | Purpose | Example |
| :--- | :--- | :--- |
| `ssh user@host` | Connect to a remote server | `ssh bob@devapp01` |
| `ssh-keygen -t RSA` | Generate a new SSH key pair | `ssh-keygen -t RSA` |
| `ssh-copy-id user@host` | Copy public key to remote server for password-less login | `ssh-copy-id bob@devapp01` |
| `scp source dest` | Securely copy files between hosts | `scp file.txt user@host:/tmp` |
| `ls -a ~/.ssh` | List SSH configuration files (hidden) | `ls -la ~/.ssh` |

   