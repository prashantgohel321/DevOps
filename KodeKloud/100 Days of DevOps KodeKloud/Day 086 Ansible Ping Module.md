# DevOps Day 86: Ansible Ping Module Usage (Password-less SSH)

This document provides a comprehensive solution for DevOps Day 86. The goal was to establish a secure, password-less SSH connection between the Ansible controller (Jump Host) and the managed nodes (App Servers), and then verify this connection using the Ansible `ping` module.

## Table of Contents
- [DevOps Day 86: Ansible Ping Module Usage (Password-less SSH)](#devops-day-86-ansible-ping-module-usage-password-less-ssh)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Generate SSH Keys](#1-generate-ssh-keys)
    - [2. Distribute Public Keys](#2-distribute-public-keys)
    - [3. Update the Inventory File](#3-update-the-inventory-file)
    - [4. Validate with Ansible Ping](#4-validate-with-ansible-ping)
  - [Deep Dive: Concepts Used](#deep-dive-concepts-used)
    - [Password-less SSH](#password-less-ssh)
    - [Ansible Ping Module](#ansible-ping-module)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** The Nautilus DevOps team needs to enable password-less SSH authentication for the user `thor` on the Jump Host to connect to `App Server 1` (and others).

**Requirements:**
1.  **Generate Keys:** Create an RSA SSH key pair for the user `thor` on the Jump Host.
2.  **Copy Keys:** Install the public key onto the target App Servers (`stapp01`, `stapp02`, `stapp03`).
3.  **Update Inventory:** Modify `/home/thor/ansible/inventory` to remove hardcoded passwords.
4.  **Test:** Verify connectivity to App Server 1 using `ansible -m ping`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Generate SSH Keys
<a name="1-generate-ssh-keys"></a>
First, we generate a secure RSA key pair on the controller (Jump Host).

**Command:**
```bash
ssh-keygen -t rsa -b 4096
```
* **Prompt:** Press Enter to accept the default file location (`/home/thor/.ssh/id_rsa`).
* **Passphrase:** Press Enter twice to leave it empty (for truly automated, password-less login).

### 2. Distribute Public Keys
<a name="2-distribute-public-keys"></a>
Next, we copy the newly created public key (`id_rsa.pub`) to the `authorized_keys` file on each app server.

**Commands:**
```bash
# For App Server 1 (Tony)
ssh-copy-id tony@stapp01
# Password: Ir0nM@n

# For App Server 2 (Steve)
ssh-copy-id steve@stapp02
# Password: Am3ric@

# For App Server 3 (Banner)
ssh-copy-id banner@stapp03
# Password: BigGr33n
```
*Note: You will be prompted for the user's password one last time during this step.*

### 3. Update the Inventory File
<a name="3-update-the-inventory-file"></a>
Since we now have key-based authentication, we **must remove** the `ansible_ssh_pass` (or `ansible_ssh_password`) variable from the inventory. It is no longer needed and keeping it is a security risk.

**Command:**
```bash
vi /home/thor/ansible/inventory
```

**New Content:**
```ini
[app]
stapp01 ansible_host=stapp01 ansible_user=tony ansible_ssh_common_args='-o StrictHostKeyChecking=no'
stapp02 ansible_host=stapp02 ansible_user=steve ansible_ssh_common_args='-o StrictHostKeyChecking=no'
stapp03 ansible_host=stapp03 ansible_user=banner ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```
* Removed: `ansible_ssh_pass=...`
* Kept: `ansible_user=...` (Ansible still needs to know *who* to login as)

### 4. Validate with Ansible Ping
<a name="4-validate-with-ansible-ping"></a>
Finally, verify that Ansible can connect without asking for a password.

**Command:**
```bash
ansible stapp01 -i inventory -m ping
```

**Expected Output:**
```json
stapp01 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```
* **SUCCESS**: Connection established.
* **pong**: The standard response from the ping module.

---

## Deep Dive: Concepts Used
<a name="deep-dive-concepts-used"></a>

### Password-less SSH
<a name="password-less-ssh"></a>
This mechanism uses **asymmetric cryptography**.
1.  **Private Key (`id_rsa`):** Kept secret on the Jump Host. It's like your actual physical key.
2.  **Public Key (`id_rsa.pub`):** Copied to the server. It's like the lock.
When Ansible connects, the server uses the "lock" (public key) to create a challenge that only the "key" (private key) can solve. If solved, access is granted without a password.

### Ansible Ping Module
<a name="ansible-ping-module"></a>
The `ping` module is **not** an ICMP ping (like the network command `ping google.com`).
* **What it does:** It attempts to SSH into the remote server, verify valid login credentials, and check if a usable Python interpreter is available.
* **Why use it?** It is the definitive test for "Is Ansible ready to run playbooks on this host?"

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: "Permission denied (publickey,password)"**
* **Cause:** The public key was not correctly copied to the server, or permissions on `~/.ssh` are wrong.
* **Fix:** Run `ssh -v tony@stapp01` to debug. Retry `ssh-copy-id`. Ensure you removed `ansible_ssh_pass` from the inventory if it was incorrect.

**Issue: Still prompted for password**
* **Cause:** You might have set a passphrase when creating the key in step 1.
* **Fix:** Generate a new key without a passphrase, or use `ssh-agent` to cache the passphrase for the session.

**Issue: "Host key verification failed"**
* **Cause:** The known_hosts file doesn't recognize the server fingerprint.
* **Fix:** Ensure `ansible_ssh_common_args='-o StrictHostKeyChecking=no'` is in your inventory or `ansible.cfg`.
   