# DevOps Day 7: Enabling Automation with Password-less SSH

Today's task was a major step forward. I moved from running commands manually to setting up the infrastructure needed for true automation. The objective was to configure password-less SSH access from a central jump host to all application servers. Without this, any automated script would fail the moment it needed to connect to a remote server, as it would be stuck waiting for a password.

This task introduced me to public key authentication, a more secure and script-friendly alternative to traditional password-based logins.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: How Public Key Authentication Works](#deep-dive-how-public-key-authentication-works)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My goal was to configure the `thor` user on the `jump_host` to be able to SSH into all three app servers without needing a password. The connections had to be made to the specific sudo user on each server:
- `thor@jump_host` -> `tony@stapp01`
- `thor@jump_host` -> `steve@stapp02`
- `thor@jump_host` -> `banner@stapp03`

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The entire process was performed as the `thor` user on the `jump_host`.

#### Step 1: Generate an SSH Key Pair
First, I needed to create a unique identity for the `thor` user. This is done by generating a pair of cryptographic keys: one private, one public.
```bash
# Run from the jump_host as user thor
ssh-keygen -t rsa
```
I pressed `Enter` three times to accept the default file location (`~/.ssh/id_rsa`), to set no passphrase (which is essential for automation), and to confirm.

#### Step 2: Copy the Public Key to Each App Server
Next, I distributed my public key to each of the target servers. The `ssh-copy-id` command is built specifically for this and is the most reliable method. It automatically appends the key to the `~/.ssh/authorized_keys` file on the remote server and sets the correct file permissions.

I was prompted for each user's password **one final time** to authorize the key transfer.
```bash
# Copy key to App Server 1
ssh-copy-id tony@stapp01

# Copy key to App Server 2
ssh-copy-id steve@stapp02

# Copy key to App Server 3
ssh-copy-id banner@stapp03
```

#### Step 3: Verification
The final and most important step was to test the password-less connection to each server.
```bash
ssh tony@stapp01
# I was logged in instantly without a password.
exit

ssh steve@stapp02
# Logged in instantly.
exit

ssh banner@stapp03
# Logged in instantly.
exit
```

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Password-less is not "No Security"**: It's actually **stronger security**. Instead of a password that can be guessed or stolen, this method relies on a pair of very long, complex cryptographic keys.
-   **Public Key Authentication**: This is the name of the security mechanism. It works on a lock-and-key principle:
    -   **Private Key (`~/.ssh/id_rsa`)**: This is your secret key. It stays on the machine you are connecting *from* (the jump host). You **never** share it.
    -   **Public Key (`~/.ssh/id_rsa.pub`)**: This is the lock. You can copy this key to any machine you want to connect *to* (the app servers).
-   **Automation is Impossible with Passwords**: Scripts need to run without human interaction. If a script that connects to 100 servers has to stop and ask for a password on each one, it's not automated. Public key authentication allows scripts to connect seamlessly.

---

### Deep Dive: How Public Key Authentication Works
<a name="deep-dive-how-public-key-authentication-works"></a>
The process is an elegant challenge-response protocol that never exposes a password over the network.

1.  **Connection Request**: My `jump_host` contacts `stapp01` and says, "I'm user `tony` and I want to log in using public key authentication."
2.  **The Challenge**: `stapp01` looks up the public key I provided in its `~/.ssh/authorized_keys` file. It then generates a random, one-time-use message and encrypts it using my public key. It sends this encrypted message back to me.
3.  **The Response**: This encrypted message can **only** be decrypted by my corresponding private key, which is safe on my `jump_host`. My machine decrypts the message.
4.  **Proof of Identity**: My `jump_host` sends the decrypted message back to `stapp01`.
5.  **Access Granted**: `stapp01` sees that I successfully decrypted the message, which proves I must be the owner of the private key. It grants me access without ever needing a password.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Setting a Passphrase:** `ssh-keygen` asks for a passphrase. While this is a good idea for personal laptops to add another layer of security to your private key, it defeats the purpose of automation. A script can't enter a passphrase, so for service accounts like this, the passphrase must be left empty.
-   **Incorrect Permissions:** A common manual error is to copy the key but have the wrong file permissions on the remote server's `.ssh` directory or `authorized_keys` file. SSH is very strict: if permissions are too open, it will refuse to use the keys. The `ssh-copy-id` command prevents this by setting the correct permissions automatically.
-   **Copying the Wrong Key:** A beginner mistake is to accidentally copy the private `id_rsa` key. This should never be done. Only the public `id_rsa.pub` key is meant to be distributed.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `ssh-keygen -t rsa`: **Gen**erates a new SSH **key** pair. `-t rsa` specifies the type of encryption algorithm to use, which is a widely supported standard.
-   `ssh-copy-id [user]@[host]`: The hero of this task. It connects to the remote host, safely appends the local user's public key to the remote user's `authorized_keys` file, and ensures file permissions are correct.

