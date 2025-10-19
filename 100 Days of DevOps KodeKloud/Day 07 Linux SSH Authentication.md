<center><h1>DevOps Day 7<br>Automation with Password-less SSH</h1></center>
<br>

The task involved setting up an infrastructure for automation by configuring password-less SSH access from a central `jump host` to all app servers. This was crucial to prevent automated scripts from failing when connecting to remote servers. The task introduced public key authentication, a secure, script-friendly alternative to traditional password-based logins.

## Table of Contents
- [Table of Contents](#table-of-contents)
  - [The Task](#the-task)
  - [My Step-by-Step Solution](#my-step-by-step-solution)
    - [Step 1: Generate an SSH Key Pair](#step-1-generate-an-ssh-key-pair)
    - [Step 2: Copy the Public Key to Each App Server](#step-2-copy-the-public-key-to-each-app-server)
    - [Step 3: Verification](#step-3-verification)
  - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
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
- The entire process was performed as the `thor` user on the `jump_host`.

#### Step 1: Generate an SSH Key Pair
- First, I needed to create a unique identity for the `thor` user. This is done by generating a pair of cryptographic keys: one private, one public.
```bash
# Run from the jump_host as user thor
ssh-keygen -t rsa
```
I pressed `Enter` three times to accept the default file location (`~/.ssh/id_rsa`), to set no passphrase (which is essential for automation), and to confirm.

#### Step 2: Copy the Public Key to Each App Server
- Next, I distributed my public key to each of the target servers. The `ssh-copy-id` command is built specifically for this and is the most reliable method. It automatically appends the key to the `~/.ssh/authorized_keys` file on the remote server and sets the correct file permissions.

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
- The final and most important step was to test the password-less connection to each server.
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
-   **Password-less is still secure**: Instead of a password that could be guessed or stolen, this method uses long, complex cryptographic keys.
-   **Public Key Authentication**: Works like a lock and key:
    -   **Private Key (`~/.ssh/id_rsa`)**: Your secret key, kept on the machine you connect from (never shared).
    -   **Public Key (`~/.ssh/id_rsa.pub`)**: The lock, copied to any machine you want to access.
-   **Automation Needs**: Scripts must run without human input. Passwords would stop a script on each server, but public key authentication lets scripts connect automatically.

---

### Deep Dive: How Public Key Authentication Works
<a name="deep-dive-how-public-key-authentication-works"></a>
It’s a secure challenge-response process — no passwords are sent over the network.
1. **Connection Request** → My `jump_host` contacts `stapp01`, saying: “I’m user tony and want to log in with a public key.”
2. **The Challenge** → `stapp01` finds my public key in `~/.ssh/authorized_keys`, creates a random one-time message, encrypts it with my public key, and sends it back.
3. **The Response** → Only my private key (on the `jump_host`) can decrypt this message. My machine decrypts it.
4. **Proof of Identity** → My `jump_host` sends the decrypted message back to `stapp01`.
5. **Access Granted** → `stapp01` confirms the message was decrypted correctly, proving I own the private key. Access is granted without ever using a password.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Setting a Passphrase:** Adding a passphrase is secure for personal use, but breaks automation. Scripts can’t enter a passphrase, so service accounts must leave it empty.
-   **Incorrect Permissions:** SSH is strict. If the `.ssh` folder or `authorized_keys` file has wrong permissions, the keys won’t work. Using `ssh-copy-id` fixes this automatically.
-   **Copying the Wrong Key:** Never copy your private key (`id_rsa`). Only the public key (`id_rsa.pub`) should be shared.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>
-   `ssh-keygen -t rsa`: Creates a new SSH key pair. `-t rsa` sets the encryption type to RSA, a widely supported standard.
-   `ssh-copy-id [user]@[host]`: It connects to the remote host, adds your public key to the remote user’s `authorized_keys` file, and sets the correct permissions automatically.