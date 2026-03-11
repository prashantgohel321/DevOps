# DevOps Day 07 — Password‑less SSH Authentication (Detailed Explanation)

<br>
<br>

- [DevOps Day 07 — Password‑less SSH Authentication (Detailed Explanation)](#devops-day-07--passwordless-ssh-authentication-detailed-explanation)
  - [Real Scenario](#real-scenario)
- [Understanding the Infrastructure](#understanding-the-infrastructure)
- [Step 1 — Generating an SSH Key Pair](#step-1--generating-an-ssh-key-pair)
- [Why No Passphrase Was Used](#why-no-passphrase-was-used)
- [Step 2 — Copying the Public Key to Remote Servers](#step-2--copying-the-public-key-to-remote-servers)
- [What ssh-copy-id Does Internally](#what-ssh-copy-id-does-internally)
- [Step 3 — Verifying Password‑less Login](#step-3--verifying-passwordless-login)
- [How Public Key Authentication Works Internally](#how-public-key-authentication-works-internally)
- [Why Password‑less SSH Is Secure](#why-passwordless-ssh-is-secure)
- [Important SSH Files Involved](#important-ssh-files-involved)
- [Common Problems During Setup](#common-problems-during-setup)
- [Useful SSH Commands](#useful-ssh-commands)
- [Practical Outcome](#practical-outcome)


<br>
<br>

## Real Scenario

- In DevOps environments, automation tools frequently connect to remote servers to deploy applications, run configuration scripts, collect logs, or perform health checks. These operations often occur without human interaction.

- If remote access required manual password entry every time, automation would fail. Scripts cannot type passwords, and storing plaintext passwords inside scripts would create serious security risks.

- To solve this problem, Linux systems support **SSH public key authentication**, which allows machines to authenticate securely without passwords.

- In this task, the goal was to configure the `thor` user on a central **jump host** so it could connect to three application servers without needing to enter a password.

---

<br>
<br>

# Understanding the Infrastructure

The environment contained four systems.

```bash
jump_host
stapp01
stapp02
stapp03
```

The connections needed to work as follows:

```bash
thor@jump_host  →  tony@stapp01
thor@jump_host  →  steve@stapp02
thor@jump_host  →  banner@stapp03
```

- The `jump_host` acts as a central access machine used by administrators or automation systems to reach internal servers.

- This architecture is commonly used in production environments because it limits direct external access to internal servers.

---

<br>
<br>

# Step 1 — Generating an SSH Key Pair

The first step was creating a cryptographic identity for the `thor` user.

```bash
ssh-keygen -t rsa
```

This command generates a **pair of cryptographic keys**.

When executed, SSH creates two files inside the user's `.ssh` directory.

```bash
~/.ssh/id_rsa
~/.ssh/id_rsa.pub
```

---

- **Private Key**

```bash
~/.ssh/id_rsa
```

- The private key must remain secret and should never be shared with other systems.

- This key proves the identity of the user during authentication.

---

- **Public Key**

```bash
~/.ssh/id_rsa.pub
```

- The public key can be safely shared with remote servers.

- It acts like a lock that allows the matching private key to authenticate.

---

<br>
<br>

# Why No Passphrase Was Used

- During key generation the command prompts for a passphrase.

- In personal environments adding a passphrase increases security.

- However, automation scripts cannot enter passphrases.

Therefore automation accounts typically leave the passphrase empty so SSH connections can occur automatically.

---

<br>
<br>

# Step 2 — Copying the Public Key to Remote Servers

- Once the key pair exists, the public key must be installed on each remote server.

- The easiest way to perform this task is with the `ssh-copy-id` command.

Example:

```bash
ssh-copy-id tony@stapp01
ssh-copy-id steve@stapp02
ssh-copy-id banner@stapp03
```

During this step the password is requested **one final time** so the remote server can authorize the key installation.

---

<br>
<br>

# What ssh-copy-id Does Internally

The command performs several actions automatically.

1. It connects to the remote server using SSH.
2. It creates the `.ssh` directory in the user's home folder if it does not exist.
3. It appends the public key to the file:

```bash
~/.ssh/authorized_keys
```

4. It sets strict permissions required by SSH security rules.

**Example permissions:**

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

If these permissions are incorrect, SSH will refuse key authentication.

---

<br>
<br>

# Step 3 — Verifying Password‑less Login

After copying the keys, SSH connections should work without passwords.

Testing the connection:

```bash
ssh tony@stapp01
ssh steve@stapp02
ssh banner@stapp03
```

If configuration is correct, the login occurs immediately.

The SSH client uses the private key automatically during authentication.

---

<br>
<br>

# How Public Key Authentication Works Internally

Public key authentication follows a **challenge‑response mechanism**.

The process works as follows.

---

**Step 1 — Connection Request**: The SSH client contacts the remote server and announces that it wants to authenticate using a public key.

---

**Step 2 — Server Challenge**: The SSH server checks whether the user's public key exists inside:

```bash
~/.ssh/authorized_keys
```

If the key exists, the server generates a random challenge message.

This message is encrypted using the public key.

---

**Step 3 — Client Decryption**
- Only the private key stored on the client machine can decrypt this message.
- The SSH client decrypts the message using the private key.

---

**Step 4 — Proof of Ownership**

- The decrypted response is sent back to the server.

- If the server verifies the response successfully, it proves the client owns the private key.

- Access is granted.

---

<br>
<br>

# Why Password‑less SSH Is Secure

- Even though it removes passwords from the login process, this method is actually **more secure**.

**Reasons include:**

* Keys are extremely long and difficult to brute‑force
* Private keys never leave the client machine
* No password travels across the network

---

<br>
<br>

# Important SSH Files Involved

**Client Side**

```bash
~/.ssh/id_rsa
~/.ssh/id_rsa.pub
```

---

**Server Side**

```bash
~/.ssh/authorized_keys
```

This file stores public keys allowed to authenticate.

---

<br>
<br>

# Common Problems During Setup

**Incorrect Permissions**
- SSH requires strict permission rules.

**Example correct configuration:**

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

**Copying the Wrong Key**
- Only the **public key** should be copied to servers.
- The private key must remain secret.

---

**Using Passphrases in Automation**: Passphrases prevent automated login because scripts cannot unlock private keys.

---

<br>
<br>

# Useful SSH Commands

**Generate modern ED25519 key:**

```bash
ssh-keygen -t ed25519
```

**View existing SSH keys:**

```bash
ls ~/.ssh
```

**Test connection with verbose output:**

```bash
ssh -v user@host
```

**Manually add public key to authorized_keys:**

```bash
cat id_rsa.pub >> ~/.ssh/authorized_keys
```

---

<br>
<br>

# Practical Outcome

After completing this configuration:

* The `thor` user can SSH into all application servers without entering passwords
* Automation scripts can connect to servers reliably
* Infrastructure management becomes easier and more secure

Password‑less SSH authentication is a fundamental building block for many DevOps tools such as **Ansible, Jenkins, and CI/CD pipelines** because it enables secure automated access across multiple servers.
