# DevOps Day 85: Create Files on App Servers using Ansible

This document outlines the solution for DevOps Day 85, where the objective was to use Ansible to create a specific file with distinct ownership permissions on multiple application servers.

## Table of Contents
- [DevOps Day 85: Create Files on App Servers using Ansible](#devops-day-85-create-files-on-app-servers-using-ansible)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the Inventory File](#1-create-the-inventory-file)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execution and Validation](#3-execution-and-validation)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `file` Module](#the-file-module)
    - [Dynamic Ownership with Variables](#dynamic-ownership-with-variables)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** The Nautilus DevOps team needs to create a blank file `/opt/appdata.txt` on all three application servers (`stapp01`, `stapp02`, `stapp03`).

**Requirements:**
1.  **Inventory Creation:** Create `/home/thor/playbook/inventory` listing all app servers.
2.  **Playbook Creation:** Create `/home/thor/playbook/playbook.yml`.
3.  **File Creation:** Create `/opt/appdata.txt`.
4.  **Permissions:** Set file permissions to `0655`.
5.  **Ownership:**
    * `stapp01`: Owner/Group `tony`
    * `stapp02`: Owner/Group `steve`
    * `stapp03`: Owner/Group `banner`
6.  **Validation:** Execute with `ansible-playbook -i inventory playbook.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Inventory File
<a name="1-create-the-inventory-file"></a>
The key to solving the "different owner per server" requirement efficiently is to use the `ansible_user` variable in our inventory. Since we already define `ansible_user` to connect (tony, steve, banner), we can reuse this variable in the playbook!

**Command:**
```bash
mkdir -p ~/playbook
cd ~/playbook
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

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
We use the `file` module. To set the owner dynamically, we use the `{{ ansible_user }}` variable. This means when Ansible runs on `stapp01`, it uses `tony`. When on `stapp02`, it uses `steve`.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: create file with specific ownership
  hosts: all
  become: true  # Required to write to /opt
  tasks:
    - name: create a blank file /opt/appdata.txt
      file:
        path: /opt/appdata.txt
        state: touch
        mode: '0655'
        owner: "{{ ansible_user }}"
        group: "{{ ansible_user }}"
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
PLAY [create file with specific ownership] ******************************************

TASK [Gathering Facts] **************************************************************
ok: [stapp02]
ok: [stapp03]
ok: [stapp01]

TASK [create a blank file /opt/appdata.txt] *****************************************
changed: [stapp02]
changed: [stapp03]
changed: [stapp01]

PLAY RECAP **************************************************************************
stapp01 : ok=2    changed=1    unreachable=0    failed=0 ...
stapp02 : ok=2    changed=1    unreachable=0    failed=0 ...
stapp03 : ok=2    changed=1    unreachable=0    failed=0 ...
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `file` Module
<a name="the-file-module"></a>
This module manages file properties.
* `state: touch`: Creates an empty file or updates timestamps.
* `mode`: Sets permissions. Note that `0655` is unusual (Read/Write owner, Read/Execute group/others), but we must follow the task requirements exactly.

### Dynamic Ownership with Variables
<a name="dynamic-ownership-with-variables"></a>
Instead of writing three separate tasks (one for tony, one for steve, etc.), we used the power of Ansible variables.
* **`{{ ansible_user }}`**: This is a "magic variable" or connection variable defined in the inventory.
* By setting `owner: "{{ ansible_user }}"`, the playbook automatically adapts to whichever server it is currently running on.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: "Permission Denied"**
* **Cause:** Writing to `/opt` requires root privileges.
* **Fix:** Ensure `become: true` is present at the play level or task level.

**Issue: "Invalid User"**
* **Cause:** If `ansible_user` is not defined in the inventory, the playbook will fail.
* **Fix:** Check your `inventory` file to ensure `ansible_user=...` is correctly set for every host.

**Issue: "Syntax Error" in YAML**
* **Cause:** Indentation issues.
* **Fix:** Ensure `file:` is indented under `tasks:`, and properties like `path:` are indented under `file:`. YAML forbids tabs; use spaces.
  