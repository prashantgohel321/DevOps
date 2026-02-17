# DevOps Day 87: Ansible Install Package & Troubleshooting

This document outlines the solution for DevOps Day 87. The goal was to use Ansible to install the `samba` package on all application servers. During the process, a connection error (`rc: 137`) occurred on `stapp01`, which required troubleshooting the inventory configuration.

## Table of Contents
- [DevOps Day 87: Ansible Install Package \& Troubleshooting](#devops-day-87-ansible-install-package--troubleshooting)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the Inventory File](#1-create-the-inventory-file)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Initial Execution \& Error](#3-initial-execution--error)
    - [4. Troubleshooting \& Fix](#4-troubleshooting--fix)
    - [5. Final Validation](#5-final-validation)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `yum` Module](#the-yum-module)
    - [Connection Troubleshooting](#connection-troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** The Nautilus DevOps team needs to install the `samba` package on all App Servers (`stapp01`, `stapp02`, `stapp03`) using Ansible.

**Requirements:**
1.  **Inventory:** Create `/home/thor/playbook/inventory` with all app servers.
2.  **Playbook:** Create `/home/thor/playbook/playbook.yml` to install `samba`.
3.  **Module:** Use the Ansible `yum` module.
4.  **Validation:** Run `ansible-playbook -i inventory playbook.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Inventory File
<a name="1-create-the-inventory-file"></a>
We define a group `[app]` containing all servers and set the connection variables.

**Command:**
```bash
mkdir -p ~/playbook
cd ~/playbook
vi inventory
```

**Initial Content:**
```ini
[app]
stapp01 ansible_host=stapp01 ansible_user=tony ansible_ssh_pass=Ir0nM@n
stapp02 ansible_host=stapp02 ansible_user=steve ansible_ssh_pass=Am3ric@
stapp03 ansible_host=stapp03 ansible_user=banner ansible_ssh_pass=BigGr33n

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
We use the `yum` module to install the package. `become: true` is essential because installing packages requires root privileges.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: install packages on app servers
  hosts: all
  become: true
  tasks: 
    - name: install samba using yum
      yum:
        name: samba
        state: present
```

### 3. Initial Execution & Error
<a name="3-initial-execution--error"></a>
When running the playbook initially, `stapp01` failed.

**Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Error:**
```text
fatal: [stapp01]: FAILED! => {"changed": false, "module_stderr": "Shared connection to stapp01 closed.\r\n", ... "rc": 137}
```
**Analysis:** Return code 137 often indicates a memory issue or an abrupt termination of the process on the remote host. However, in Ansible contexts, connection failures like "Shared connection closed" usually point to **SSH authentication issues** or SSH timeout configurations.

### 4. Troubleshooting & Fix
<a name="4-troubleshooting--fix"></a>
Upon reviewing the inventory, we switched to using `ansible_ssh_password` (which is synonymous with `ansible_ssh_pass` but sometimes handled differently depending on the plugin versions or environment configuration). We also ensured the password for `stapp01` (`Ir0nM@n`) was correct and had no hidden characters.

**Corrected Inventory Content:**
```ini
[app]
stapp01  ansible_host=stapp01 ansible_user=tony ansible_ssh_password=Ir0nM@n
stapp02  ansible_host=stapp02 ansible_user=steve ansible_ssh_password=Am3ric@
stapp03  ansible_host=stapp03 ansible_user=banner ansible_ssh_password=BigGr33n

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### 5. Final Validation
<a name="5-final-validation"></a>
Re-running the playbook with the corrected inventory resulted in success.

**Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Result:**
```text
TASK [install samba using yum] ******************************************************
ok: [stapp03]
ok: [stapp02]
changed: [stapp01]
```
* `changed: [stapp01]` indicates Samba was successfully installed.
* `ok: [stapp02]` and `[stapp03]` indicates Samba was already installed (from the previous partial run).

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `yum` Module
<a name="the-yum-module"></a>
The `yum` module manages packages on RHEL/CentOS systems.
* **`name`**: The name of the package (e.g., `samba`, `httpd`).
* **`state`**:
    * `present`: Ensures it is installed (default).
    * `latest`: Updates to the newest version.
    * `absent`: Uninstalls the package.

### Connection Troubleshooting
<a name="connection-troubleshooting"></a>
When Ansible fails with "Shared connection closed", check:
1.  **Passwords:** Are they correct? Do they contain special characters that need escaping?
2.  **SSH Keys:** If using keys, are they in `authorized_keys`?
3.  **Privilege Escalation:** Does the user have sudo rights? (The `become: true` requires sudo access).
4.  **Resource Limits:** On very small VMs, installing heavy packages might OOM (Out of Memory) kill the process, though rare for basic packages like Samba.
   