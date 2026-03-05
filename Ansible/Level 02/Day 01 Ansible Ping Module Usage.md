# Ansible Level 02 Day 01: Ansible Ping Module Usage

This document outlines the solution for Ansible Level 02 Day 01. The objective is to configure a password-less SSH connection between the Ansible controller (Jump Host) and a managed node (App Server 1) and verify the connection using the Ansible `ping` module.

## Table of Contents
- [Ansible Level 02 Day 01: Ansible Ping Module Usage](#ansible-level-02-day-01-ansible-ping-module-usage)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Generate SSH Key Pair](#1-generate-ssh-key-pair)
    - [2. Copy Public Key to App Server 1](#2-copy-public-key-to-app-server-1)
    - [3. Execute Ansible Ping](#3-execute-ansible-ping)
  - [Deep Dive: Ansible Ping Module](#deep-dive-ansible-ping-module)
    - [Not a Network Ping](#not-a-network-ping)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Establish password-less SSH and test Ansible connectivity.
* **Controller:** Jump Host (User: `thor`)
* **Managed Node:** App Server 1 (`stapp01`, User: `tony`)
* **Inventory File:** `/home/thor/ansible/inventory`
* **Action:** Run Ansible `ping` module against App Server 1 to ensure connectivity.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Generate SSH Key Pair
<a name="1-generate-ssh-key-pair"></a>
First, generate an SSH key pair on the Jump Host for the `thor` user. This key will be used to authenticate with the remote app server without supplying a password.

**Command:**
```bash
ssh-keygen -t rsa
```
* **Note:** Press `Enter` to accept the default file location (`/home/thor/.ssh/id_rsa`). Crucially, press `Enter` twice when prompted for a passphrase to leave it empty. Setting a passphrase will cause Ansible to hang, defeating the purpose of automation.

### 2. Copy Public Key to App Server 1
<a name="2-copy-public-key-to-app-server-1"></a>
Next, copy the generated public key to the target server (`stapp01`). The default user for App Server 1 is `tony`.

**Command:**
```bash
ssh-copy-id tony@stapp01
```
* **Prompt:** Type `yes` when asked if you want to continue connecting.
* **Password:** Enter `Ir0nM@n` when prompted for `tony@stapp01`'s password.

*(Optional)* Verify the password-less connection works manually:
```bash
ssh tony@stapp01
# You should be logged in without being asked for a password. Type 'exit' to return to the jump host.
```

### 3. Execute Ansible Ping
<a name="3-execute-ansible-ping"></a>
With the password-less connection successfully established, use the provided inventory file to run the Ansible `ping` module against `stapp01`.

**Navigate to the directory:**
```bash
cd /home/thor/ansible
```

**Run the Ping Command:**
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

But I got:
```json
stapp01 | UNREACHABLE! => {
    "changed": false,
    "msg": "Invalid/incorrect password: Permission denied, please try again.",
    "unreachable": true
}
```

So then i checked inventory file
```bash
stapp01 ansible_host=172.16.238.10 ansible_ssh_pass=Ir0nM@n
stapp02 ansible_host=172.16.238.11 ansible_ssh_pass=Am3ric@
stapp03 ansible_host=172.16.238.12 ansible_ssh_pass=BigGr33n

# here user is missing so i added user to inventory file
stapp01 ansible_host=172.16.238.10 ansible_user=tony
stapp02 ansible_host=172.16.238.11 ansible_user=tony
stapp03 ansible_host=172.16.238.12 ansible_user=tony
```

Then i tried to ping again and it worked
```json
stapp01 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

**Why does this work?** Because Ansible needs to know which user to log in as when connecting to the remote host. By default, if you don't specify `ansible_user`, Ansible will attempt to use the current user (in this case, `thor`) to connect to `stapp01`. Since `thor` does not have access to `stapp01`, the connection fails with a permission error.


---

## Deep Dive: Ansible Ping Module
<a name="deep-dive-ansible-ping-module"></a>

### Not a Network Ping
The Ansible `ping` module is fundamentally different from the standard ICMP `ping` command used in networking. 
* **ICMP Ping:** Checks if a machine is reachable on the network level.
* **Ansible Ping:** Logs into the target machine via SSH, verifies valid login credentials (like the SSH key we just set up), and ensures a usable Python interpreter is available on the remote host to execute Ansible modules.

If Ansible returns `"ping": "pong"`, it confirms that the node is 100% ready to receive and execute complex Ansible playbooks.
   
