# DevOps Day 84: Copy Data to App Servers using Ansible

This document outlines the solution for DevOps Day 84, where the objective was to distribute a specific file from the jump host to all application servers in the Stratos Datacenter using Ansible automation.

## Table of Contents
- [DevOps Day 84: Copy Data to App Servers using Ansible](#devops-day-84-copy-data-to-app-servers-using-ansible)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the Inventory File](#1-create-the-inventory-file)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execution and Validation](#3-execution-and-validation)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [Inventory Groups](#inventory-groups)
    - [The `copy` Module](#the-copy-module)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** The Nautilus DevOps team requires a file (`index.html`) located at `/usr/src/data/` on the jump host to be copied to the `/opt/data/` directory on all three application servers (`stapp01`, `stapp02`, `stapp03`).

**Requirements:**
1.  **Inventory Creation:** Create `/home/thor/ansible/inventory` listing all app servers.
2.  **Playbook Creation:** Create `/home/thor/ansible/playbook.yml` to perform the copy operation.
3.  **Source:** `/usr/src/data/index.html` (Local on Jump Host).
4.  **Destination:** `/opt/data/index.html` (Remote on App Servers).
5.  **Validation:** Execute with `ansible-playbook -i inventory playbook.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Inventory File
<a name="1-create-the-inventory-file"></a>
We need to define a group of servers (which I named `[app]`) containing all three application nodes. We also need to define the specific connection credentials for each user (`tony`, `steve`, `banner`).

**Command:**
```bash
cd /home/thor/ansible/
vi inventory
```

**Content:**
```ini
[app]
stapp01 ansible_user=tony ansible_ssh_pass=Ir0nM@n
stapp02 ansible_user=steve ansible_ssh_pass=Am3ric@
stapp03 ansible_user=banner ansible_ssh_pass=BigGr33n

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```
*Note: The `[all:vars]` section is a best practice in these lab environments to avoid SSH "host key verification" failures.*

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
We need a YAML file to describe the task. We will use the `copy` module.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: copy data to application server
  hosts: app
  become: yes  # Required because /opt/data usually requires root/sudo permissions to write
  tasks:
    - name: copy index.html to /opt/data
      copy:
        src: /usr/src/data/index.html
        dest: /opt/data/
        mode: '0644'
```

### 3. Execution and Validation
<a name="3-execution-and-validation"></a>
Run the playbook against the inventory.

**Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Output Analysis:**
```text
PLAY [copy data to application server] **********************************************

TASK [Gathering Facts] **************************************************************
ok: [stapp02]
ok: [stapp01]
ok: [stapp03]

TASK [copy index.html to /opt/data] *************************************************
changed: [stapp03]
changed: [stapp02]
changed: [stapp01]

PLAY RECAP **************************************************************************
stapp01 : ok=2    changed=1    unreachable=0    failed=0 ...
stapp02 : ok=2    changed=1    unreachable=0    failed=0 ...
stapp03 : ok=2    changed=1    unreachable=0    failed=0 ...
```
* **`ok=2`**: Means both "Gathering Facts" and "Copy" succeeded.
* **`changed=1`**: Means the file was successfully copied (it wasn't there before, or it was different).

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### Inventory Groups
<a name="inventory-groups"></a>
Instead of listing every server under `[all]`, we created a group called `[app]`. This allows us to target all three servers simultaneously in the playbook by simply setting `hosts: app`.

### The `copy` Module
<a name="the-copy-module"></a>
The `copy` module copies a file from the local or remote machine to a location on the remote machine.
* **`src`**: The path to the file on the control node (jump host).
* **`dest`**: The destination path on the remote host (app servers).
* **`mode`**: (Optional but recommended) Sets the file permissions (e.g., `0644` for read/write owner, read others).

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: "Permission Denied" on Destination**
* **Cause:** The destination directory `/opt/data` is often owned by root. The user (e.g., `tony`) cannot write to it directly.
* **Fix:** Ensure you include `become: yes` in your playbook. This tells Ansible to use `sudo` to execute the task.

**Issue: "Authentication Failed"**
* **Cause:** Incorrect password in the inventory file.
* **Fix:** Double-check the passwords for each user:
    * `tony`: `Ir0nM@n`
    * `steve`: `Am3ric@`
    * `banner`: `BigGr33n`
    * *Note: Ensure no trailing spaces are pasted into the inventory file.*

**Issue: "Destination directory does not exist"**
* **Cause:** The folder `/opt/data` might not exist on the app servers.
* **Fix:** While the `copy` module can create the file, it usually expects the parent directory to exist. If it fails, add a task *before* the copy task using the `file` module with `state: directory` to ensure `/opt/data` exists.
   