# Linux Level 2, Task 3: Creating a Secure Collaborative Directory

Today's task was a fantastic, real-world exercise in Linux file permissions. My objective was to create a "collaborative directory" where any file created inside it would automatically be owned by a specific group, not by the user who created it. This is a common requirement for teams that need to share and edit files without constantly having to `chown` or `chgrp` them.

This was a great lesson that went beyond the basic `rwx` permissions. I learned about **special permissions**, specifically the **`setgid` (Set Group ID) bit**, which is the magic that makes a collaborative directory work. This document is my detailed, first-person guide to both the manual method and the superior, automated Ansible solution.

## Table of Contents
- [Linux Level 2, Task 3: Creating a Secure Collaborative Directory](#linux-level-2-task-3-creating-a-secure-collaborative-directory)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [Solution 1: The Manual Approach (The `chmod 2770` Method)](#solution-1-the-manual-approach-the-chmod-2770-method)
      - [The Workflow](#the-workflow)
    - [Solution 2: The Automated Approach (with Ansible)](#solution-2-the-automated-approach-with-ansible)
      - [1. The Inventory (`inventory.ini`)](#1-the-inventory-inventoryini)
      - [2. The Playbook (`playbook.yml`)](#2-the-playbook-playbookyml)
      - [3. The Execution](#3-the-execution)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: The Magic of the `setgid` Bit (`chmod g+s` or `2770`)](#deep-dive-the-magic-of-the-setgid-bit-chmod-gs-or-2770)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the Commands and Modules I Used](#exploring-the-commands-and-modules-i-used)
      - [**Manual Commands**](#manual-commands)
      - [**Ansible Modules**](#ansible-modules)

---

### The Task
<a name="the-task"></a>
My objective was to create a secure, shared directory on **App Server 3**. The specific requirements were:
1.  Create the directory at `/sysadmin/data`.
2.  The directory must be group-owned by the `sysadmin` group.
3.  Any new files created in this directory must also be group-owned by `sysadmin`.
4.  Permissions must be `rwx` (read/write/execute) for the owner user and the owner group.
5.  "Others" (everyone else) must have **no permissions** (`---`).

---

### Solution 1: The Manual Approach (The `chmod 2770` Method)
<a name="solution-1-the-manual-approach-the-chmod-2770-method"></a>
This method involves logging into the server and running a specific sequence of commands to create the directory and set its unique permissions.

#### The Workflow
1.  **Connect to the Server:** I started by connecting to App Server 3.
    ```bash
    ssh banner@stapp03
    ```

2.  **Create the Directory:** I used `mkdir -p` to create the directory.
    ```bash
    sudo mkdir -p /sysadmin/data
    ```

3.  **Ensure Group Exists:** (Good practice) I ran `sudo groupadd sysadmin`. If the group already existed, this just gave a harmless error.

4.  **Set Ownership:** I set the user owner to `root` (default for `sudo`) and the group owner to `sysadmin`.
    ```bash
    sudo chown root:sysadmin /sysadmin/data
    ```

5.  **Set Permissions (The Critical Step):** This is where the magic happens. To satisfy all requirements, I needed to set the permissions using the 4-digit octal notation.
    ```bash
    sudo chmod 2770 /sysadmin/data
    ```

6.  **Verification:** I used `ls -ld` to confirm the settings.
    ```bash
    ls -ld /sysadmin/data
    # Output: drwxrws---. 2 root sysadmin 4096 Oct 18 10:00 /sysadmin/data
    ```
    This output was the definitive proof of success. The `s` in `rws` indicated the `setgid` bit was active, and the `---` at the end showed "others" had no access.

---

### Solution 2: The Automated Approach (with Ansible)
<a name="solution-2-the-automated-approach-with-ansible"></a>
This is the professional, repeatable solution. I would perform all my work from the jump host.

#### 1. The Inventory (`inventory.ini`)
First, I would define my target server in an inventory file.
```ini
[app_servers]
stapp03 ansible_host=172.16.238.12 ansible_user=banner ansible_ssh_pass=BigGr33n ansible_become_pass=BigGr33n
```

#### 2. The Playbook (`playbook.yml`)
Next, I'd write a "to-do list" in YAML. Ansible's `file` module is perfect because it can handle all the requirements in one task.
```yaml
---
- name: Create Secure Collaborative Directory
  hosts: app_servers
  become: yes
  tasks:
    - name: Ensure sysadmin group exists
      ansible.builtin.group:
        name: sysadmin
        state: present

    - name: Create /sysadmin/data with correct permissions
      ansible.builtin.file:
        path: /sysadmin/data
        state: directory
        owner: root
        group: sysadmin
        mode: '2770'
```

#### 3. The Execution
Finally, from the jump host, I would run a single command.
```bash
ansible-playbook -i inventory.ini playbook.yml
```
Ansible would connect to the server and ensure the directory existed with the exact owner, group, and permissions, creating it if necessary.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **File Permissions (`rwx`):** These are the basic permissions: **r**ead, **w**rite, and e**x**ecute. The task required `rwx` for both the owner (`root`) and the group (`sysadmin`).
-   **The "Others" Requirement:** The task required that "others" have no access. This is a critical security step to ensure that users who are *not* the owner and *not* in the `sysadmin` group cannot see, modify, or enter the directory.
-   **The `setgid` Bit:** This was the key to the entire task. By default in Linux, when a user creates a new file, that file's group owner is set to the user's *own primary group*. In a shared directory, this is a problem. The `setgid` bit changes this behavior.

---

### Deep Dive: The Magic of the `setgid` Bit (`chmod g+s` or `2770`)
<a name="deep-dive-the-magic-of-the-setgid-bit-chmod-gs"></a>
This task was a perfect lesson in the `setgid` (Set Group ID) permission.

[Image of file group ownership inheritance with setgid]

-   **What it is:** The `setgid` bit is a special permission that can be set on a directory.
-   **What it does:** When the `setgid` bit is set on a directory, it enforces two special rules:
    1.  **Group Inheritance (The Main One):** Any new file or subdirectory created inside this directory will **automatically have its group owner set to the group owner of the parent directory**. In my case, any file `tony` creates inside `/sysadmin/data` will be owned by `tony:sysadmin`, not `tony:tony`.
    2.  **Subdirectory Inheritance:** Any new subdirectory created inside will also inherit the `setgid` bit, so this rule applies to the entire directory tree automatically.
-   **How I Set It:** I used the 4-digit octal mode `chmod 2770`.
    -   **`2`**: This first digit sets the special permissions. `2` specifically means "set group ID" (`setgid`).
    -   **`7`**: The standard permission for the **owner** (`rwx`).
    -   **`7`**: The standard permission for the **group** (`rwx`).
    -   **`0`**: The standard permission for **others** (`---`).
-   **How I Saw It:** In the `ls -ld` output (`drwxrws---`), the `s` in the group permission spot (where `x` would normally be) is how Linux shows that the `setgid` bit is active.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting `setgid`:** The most common mistake would be to just run `sudo chmod 770`. This would set the correct `rwx` permissions but would **not** enforce the group ownership for new files, failing the core requirement of a *collaborative* directory.
-   **Confusing `2770` vs. `g+s`:** I could have achieved the same result in two steps: `sudo chmod 770 /sysadmin/data` (to set base permissions) and then `sudo chmod g+s /sysadmin/data` (to add the `setgid` bit). The `2770` syntax is just a faster, single-command way to do both.
-   **Incorrect Ownership:** Forgetting to run `sudo chown root:sysadmin` would leave the directory owned by `root:root`, which would also fail the task.

---

### Exploring the Commands and Modules I Used
<a name="exploring-the-commands-and-modules-i-used"></a>
#### **Manual Commands**
-   `sudo mkdir -p /sysadmin/data`: Creates the directory and any necessary parents.
-   `sudo groupadd sysadmin`: Creates the `sysadmin` group.
-   `sudo chown root:sysadmin /sysadmin/data`: **Ch**anges the **own**er of the directory to the user `root` and the group `sysadmin`.
-   `sudo chmod 2770 /sysadmin/data`: The main command. It **ch**anges the permission **mod**e of the directory to `2` (setgid) + `7` (owner `rwx`) + `7` (group `rwx`) + `0` (other `---`).
-   `ls -ld /sysadmin/data`: My verification command. It **l**i**s**ts the directory (`-d`) in **l**ong format so I can see its permissions, owner, and group.

#### **Ansible Modules**
-   `ansible-playbook -i ...`: The command to run my automation.
-   `ansible.builtin.group`: The Ansible module that ensures a group (`sysadmin`) is in the `present` state.
-   `ansible.builtin.file`: The Ansible module for managing files and directories. It's incredibly powerful. I used it to set the `path`, `state`, `owner`, `group`, and `mode` (permissions) all in one idempotent task.
  