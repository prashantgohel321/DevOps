# Linux Level 2, Task 2: Updating the Message of the Day (MOTD)

Today's task was a classic system administration duty focused on compliance and communication: updating the "Message of the Day" (MOTD) on a fleet of servers. The goal was to ensure that a standard, approved banner was displayed to every user upon logging in.

This exercise was another perfect opportunity to contrast the repetitive manual approach with a powerful, automated solution using Ansible. The Ansible path was particularly insightful as it failed on the first try with an SSH host key error, teaching me a critical lesson about preparing the environment for automation. This document is my detailed, first-person guide to both the manual and the successful automated solutions.

## Table of Contents
- [Linux Level 2, Task 2: Updating the Message of the Day (MOTD)](#linux-level-2-task-2-updating-the-message-of-the-day-motd)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [Solution 1: The Manual Approach (Server by Server)](#solution-1-the-manual-approach-server-by-server)
      - [The Simple (but flawed) `scp` Method](#the-simple-but-flawed-scp-method)
      - [The Robust Manual Method](#the-robust-manual-method)
    - [Solution 2: The Automated Approach (with Ansible)](#solution-2-the-automated-approach-with-ansible)
      - [1. The Troubleshooting Journey: "Host Key Checking" Failure](#1-the-troubleshooting-journey-host-key-checking-failure)
      - [2. The Solution](#2-the-solution)
      - [3. The Inventory (`inventory.ini`)](#3-the-inventory-inventoryini)
      - [4. The Playbook (`playbook.yml`)](#4-the-playbook-playbookyml)
      - [5. The Execution (with the fix)](#5-the-execution-with-the-fix)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The "Host Key Checking" Failure in Ansible](#deep-dive-the-host-key-checking-failure-in-ansible)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the Commands and Modules I Used](#exploring-the-commands-and-modules-i-used)
      - [**Manual Commands**](#manual-commands)
      - [**Ansible**](#ansible)

---

### The Task
<a name="the-task"></a>
My objective was to update the MOTD on all three Nautilus app servers and the DB server. The requirements were:
1.  The approved banner content was located in the file `/home/thor/nautilus_banner` on the jump host.
2.  This content had to be placed in the `/etc/motd` file on all app servers (`stapp01`, `stapp02`, `stapp03`) and the DB server (`stdb01`).

---

### Solution 1: The Manual Approach (Server by Server)
<a name="solution-1-the-manual-approach-server-by-server"></a>
This method involves using commands from the jump host to update each server individually. A simple `scp` is often the first thought, but it can fail due to permissions.

#### The Simple (but flawed) `scp` Method
My first instinct might be to run `scp` for each server:
```bash
# This will likely fail!
sudo scp /home/thor/nautilus_banner tony@stapp01:/etc/motd
```
This fails because the `tony` user on the remote server does not have permission to write to the `/etc/` directory.

#### The Robust Manual Method
A much better manual technique is to use `ssh` to run a command on the remote server that can elevate its own privileges.
```bash
cat /home/thor/nautilus_banner | ssh tony@stapp01 "sudo tee /etc/motd"
```
This one-liner reads the local file, pipes its content over SSH, and uses `sudo tee` on the remote end to write the content to the protected `/etc/motd` file. I would have to run this command four times, once for each server.

---

### Solution 2: The Automated Approach (with Ansible)
<a name="solution-2-the-automated-approach-with-ansible"></a>
This is the professional, scalable solution. I performed all my work from the jump host.

#### 1. The Troubleshooting Journey: "Host Key Checking" Failure
My first attempt to run the playbook failed with a clear error on all hosts:
`fatal: [stapp01]: FAILED! => {"msg": "Using a SSH password instead of a key is not possible because Host Key checking is enabled..."}`
This told me that Ansible was stopping because it received the standard "Are you sure you want to continue connecting (yes/no)?" prompt from SSH for a new host, and it couldn't answer.

#### 2. The Solution
The fix was to tell Ansible to temporarily disable this check. I did this by setting an environment variable before running my command.

#### 3. The Inventory (`inventory.ini`)
First, I created an "address book" for Ansible.
```ini
[all_servers]
stapp01 ansible_host=172.16.238.10 ansible_user=tony ansible_ssh_pass=Ir0nM@n ansible_become_pass=Ir0nM@n
stapp02 ansible_host=172.16.238.11 ansible_user=steve ansible_ssh_pass=Am3ric@ ansible_become_pass=Am3ric@
stapp03 ansible_host=172.16.238.12 ansible_user=banner ansible_ssh_pass=BigGr33n ansible_become_pass=BigGr33n
stdb01 ansible_host=172.16.239.10 ansible_user=peter ansible_ssh_pass=Sp!dy ansible_become_pass=Sp!dy
```

#### 4. The Playbook (`playbook.yml`)
Next, I wrote a "to-do list" in YAML using Ansible's `copy` module.
```yaml
---
- name: Update MOTD on all servers
  hosts: all_servers
  become: yes
  tasks:
    - name: Copy the approved banner to /etc/motd
      ansible.builtin.copy:
        src: /home/thor/nautilus_banner
        dest: /etc/motd
        owner: root
        group: root
        mode: '0644'
```

#### 5. The Execution (with the fix)
Finally, from the jump host, I ran the playbook command with the environment variable set.
```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbook.yml
```
This time, Ansible connected to all four servers and copied the file, ensuring the destination file had the correct ownership and permissions. The entire task was completed in seconds.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **`/etc/motd` (Message of the Day)**: This is a standard file on Linux systems. Its content is automatically displayed to a user immediately after they successfully log in via a terminal. It's a crucial tool for system administrators to communicate important information, such as compliance warnings, scheduled maintenance, or welcome banners.
-   **Consistency is Key**: For compliance and branding, it's critical that all servers in an environment display the same, approved message. This task was about enforcing that consistency across a fleet of servers.
-   **Ansible**: It's a powerful automation engine that allows me to manage the configuration of many servers from a single control node (the jump host). It's "agentless" (uses SSH) and "idempotent" (can be run multiple times safely), making it the perfect tool for a task like this.

---

### Deep Dive: The "Host Key Checking" Failure in Ansible
<a name="deep-dive-the-host-key-checking-failure-in-ansible"></a>
The `Host Key checking is enabled` error I encountered is a classic "first-time setup" problem for any SSH-based automation.

-   **What is Host Key Checking?** It's a fundamental SSH security feature that protects you from "man-in-the-middle" attacks. The first time you connect to a new server, the server presents its public "host key." Your SSH client asks you to verify this key's fingerprint and, if you say "yes," it saves the key in your `~/.ssh/known_hosts` file. On all future connections, your client will check if the server presents the same key. If the key is different, it will give a loud warning, as it could mean you're connecting to an imposter server.
-   **Why Does it Fail Automation?** This process requires an interactive "yes/no" answer from a human. Automation tools like Ansible run non-interactively and cannot answer this prompt, so the SSH connection fails.
-   **The `ANSIBLE_HOST_KEY_CHECKING=False` Solution:** This environment variable tells Ansible to temporarily set `StrictHostKeyChecking=no` for its SSH connections. This instructs the SSH client to automatically trust and add new host keys without prompting. While this is very convenient for a lab environment, in a high-security production environment, the better practice is to pre-populate the `known_hosts` file with the servers' keys before running automation.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Permissions on Remote Server (Manual):** As I saw, the simple `scp` approach fails because the remote user doesn't have permission to write to `/etc/motd`.
-   **Forgetting a Server (Manual):** It's easy to lose track and accidentally miss configuring one of the servers. Ansible solves this by working from a definitive list.
-   **Ansible Host Key Checking:** Forgetting to disable host key checking for the first run will cause the playbook to fail on all new servers.

---

### Exploring the Commands and Modules I Used
<a name="exploring-the-commands-and-modules-i-used"></a>
#### **Manual Commands**
-   `cat [file] | ssh [user]@[host] "sudo tee [dest_file]"`: A powerful one-liner to read a local file and use `sudo` to write its contents to a protected file on a remote server. `tee` reads from the input pipe and writes to the file.
-   `ssh [user]@[host] "cat [file]"`: An efficient way to view the contents of a remote file without opening a full interactive session.

#### **Ansible**
-   `ANSIBLE_HOST_KEY_CHECKING=False`: An environment variable that disables SSH host key checking for the duration of the command.
-   `ansible-playbook -i [inventory] [playbook]`: The main command to run an Ansible playbook.
-   `ansible.builtin.copy`: The official Ansible module for copying files from the local control node to remote hosts. It's much smarter than `scp` because I can also define the `owner`, `group`, and `mode` (permissions) of the destination file, ensuring it's configured correctly and securely.
   