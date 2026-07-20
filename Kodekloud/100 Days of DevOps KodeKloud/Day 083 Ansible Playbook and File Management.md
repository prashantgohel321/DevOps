# DevOps Day 83: Ansible Playbooks & File Management

This document provides a comprehensive guide to completing the Ansible task for DevOps Day 83. It covers troubleshooting an existing inventory configuration and creating a new playbook to manage files on a remote application server.

## Table of Contents
- [DevOps Day 83: Ansible Playbooks \& File Management](#devops-day-83-ansible-playbooks--file-management)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Update the Inventory File](#1-update-the-inventory-file)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Validate and Execute](#3-validate-and-execute)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `file` Module](#the-file-module)
    - [Inventory Variables](#inventory-variables)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** The Nautilus DevOps team needs to complete an unfinished Ansible setup on the jump host. You must fix the inventory file and create a playbook to generate a file on **App Server 1**.

**Requirements:**
1.  **Inventory Adjustment:** Update `/home/thor/ansible/inventory` to include App Server 1 (`stapp01`) with the correct connection credentials.
2.  **Playbook Creation:** Create `/home/thor/ansible/playbook.yml`.
3.  **Task:** The playbook must create an empty file named `/tmp/file.txt` on App Server 1.
4.  **Validation:** Run `ansible-playbook -i inventory playbook.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Update the Inventory File
<a name="1-update-the-inventory-file"></a>
The existing inventory file is incomplete. We need to define the host `stapp01` and provide the SSH user and password.

* **Host:** `stapp01`
* **User:** `tony`
* **Password:** `Ir0nM@n`

**Command:**
```bash
cd /home/thor/ansible/
vi inventory
```

**Content:**
```ini
stapp01 ansible_host=stapp01 ansible_user=tony ansible_ssh_pass=Ir0nM@n ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```
*Note: Adding `ansible_ssh_common_args='-o StrictHostKeyChecking=no'` is a pro-tip. It prevents the playbook from hanging on the "Are you sure you want to connect?" prompt.*

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
We need a YAML file that defines the play.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: Configure App Server 1
  hosts: stapp01
  become: yes  # Optional: Use if /tmp requires elevated privileges (usually not needed for /tmp)
  tasks:
    - name: Create an empty file at /tmp/file.txt
      file:
        path: /tmp/file.txt
        state: touch
```

**Breakdown:**
* **`hosts: stapp01`**: Tells Ansible to run these tasks only on the server labelled `stapp01` in our inventory.
* **`file` module**: The dedicated module for managing file properties.
* **`state: touch`**: Similar to the Linux `touch` command—it creates the file if it doesn't exist, or updates the timestamp if it does.

### 3. Validate and Execute
<a name="3-validate-and-execute"></a>
Run the playbook using the inventory you created.

**Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Expected Output:**
```text
PLAY [Configure App Server 1] *******************************************************

TASK [Gathering Facts] **************************************************************
ok: [stapp01]

TASK [Create an empty file at /tmp/file.txt] ****************************************
changed: [stapp01]

PLAY RECAP **************************************************************************
stapp01                    : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `file` Module
<a name="the-file-module"></a>
The `file` module is your Swiss Army knife for filesystem operations. It can create files, directories, symlinks, and modify permissions.

* **Create a directory:** `state: directory`
* **Create a file:** `state: touch`
* **Remove a file:** `state: absent`
* **Change permissions:** `mode: '0755'`

### Inventory Variables
<a name="inventory-variables"></a>
In the inventory file, we used inline variables to define how Ansible connects:

| Variable | Description |
| :--- | :--- |
| `ansible_host` | The actual IP or FQDN of the server. |
| `ansible_user` | The username SSH uses to login. |
| `ansible_ssh_pass` | The password for the user. |
| `ansible_ssh_common_args` | Additional arguments passed to the SSH command line (useful for bypassing host key checking). |

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: "Host Key Verification Failed"**
* **Cause:** This is the first time connecting to `stapp01`, and SSH is waiting for you to type "yes" to accept the fingerprint.
* **Fix:** Ensure you included `ansible_ssh_common_args='-o StrictHostKeyChecking=no'` in your inventory file. Alternatively, run `ssh tony@stapp01` manually once and accept the key.

**Issue: "Permission Denied"**
* **Cause:** Incorrect password or username.
* **Fix:** Double check that `ansible_user=tony` and `ansible_ssh_pass=Ir0nM@n`. Note that `Ir0nM@n` has special characters; ensure no extra spaces were pasted.

**Issue: "Authentication failed" using `ansible_ssh_password`**
* **Note:** The standard variable is `ansible_ssh_pass`. While `ansible_ssh_password` works in many contexts/plugins, `ansible_ssh_pass` is the traditional default for the connection variable. If one fails, try the other.
   