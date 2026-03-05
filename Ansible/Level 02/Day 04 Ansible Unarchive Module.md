# Ansible Level 02 Day 04: Ansible Unarchive Module

This document outlines the solution for Ansible Level 02 Day 04. The objective was to use Ansible to automatically transfer a zip archive from the control node (jump host) to multiple application servers, extract it into a specific directory, and set dynamic ownership and permissions on the extracted files.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Verify the Environment](#1-verify-the-environment)
    * [2. Create the Playbook](#2-create-the-playbook)
    * [3. Execute and Validate](#3-execute-and-validate)
3.  [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Extract a locally stored zip archive to all application servers with specific permissions and dynamic ownership.

* **Playbook Location:** `/home/thor/ansible/playbook.yml`
* **Inventory Location:** `/home/thor/ansible/inventory` (Already exists)
* **Source Archive:** `/usr/src/security/nautilus.zip` (On Jump Host)
* **Destination Directory:** `/opt/security/` (On App Servers)
* **Permissions:** `0755` for the extracted data.
* **Ownership Requirements:**
    * App Server 1 (`stapp01`): `tony`
    * App Server 2 (`stapp02`): `steve`
    * App Server 3 (`stapp03`): `banner`
* **Constraint:** Must run cleanly using `ansible-playbook -i inventory playbook.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify the Environment
<a name="1-verify-the-environment"></a>
Since the inventory file is already provided, it is best practice to quickly review it to ensure it contains the connection variables that align with our dynamic ownership requirement.

**Command:**
```bash
cat /home/thor/ansible/inventory
```
*You should confirm that `stapp01` uses `ansible_user=tony`, `stapp02` uses `ansible_user=steve`, etc. We will leverage this `ansible_user` variable in our playbook.*

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
Create the YAML playbook to utilize the `unarchive` module. Because we are writing to `/opt/security/` and changing file ownership, we must use `become: yes` to execute the task with root privileges. 

We will use the `{{ ansible_user }}` magic variable to dynamically satisfy the ownership requirements based on the target host.

**Command:**
```bash
vi /home/thor/ansible/playbook.yml
```

**Content:**
```yaml
---
- name: Extract archive to all app servers
  hosts: all
  become: yes
  tasks:
    - name: Unarchive nautilus.zip into /opt/security/
      unarchive:
        src: /usr/src/security/nautilus.zip
        dest: /opt/security/
        owner: "{{ ansible_user }}"
        group: "{{ ansible_user }}"
        mode: '0755'
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
Run the playbook using the specific command required for validation.

**Command:**
```bash
cd /home/thor/ansible/
ansible-playbook -i inventory playbook.yml
```

**Expected Output:**
```text
PLAY [Extract archive to all app servers] **********************************************

TASK [Gathering Facts] ****************************************************************
ok: [stapp01]
ok: [stapp02]
ok: [stapp03]

TASK [Unarchive nautilus.zip into /opt/security/] *************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

PLAY RECAP ****************************************************************************
stapp01                    : ok=2    changed=1    unreachable=0    failed=0    ...
stapp02                    : ok=2    changed=1    unreachable=0    failed=0    ...
stapp03                    : ok=2    changed=1    unreachable=0    failed=0    ...
```

**Manual Verification (Optional):**
You can verify the files were extracted and have the correct ownership using an ad-hoc command:
```bash
ansible all -i inventory -m command -a "ls -l /opt/security/" --become
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `unarchive` Module
The `unarchive` module unpacks an archive. By default, it will copy the source file from the local system (the jump host) to the target before unpacking it.
* **`src`**: The path to the archive file. Because we did not set `remote_src: yes`, Ansible knows this file is located on the controller node (jump host).
* **`dest`**: The absolute path where the archive should be unpacked on the remote node.
* **`owner` & `group`**: Sets the ownership of the files *after* they are extracted.
* **`mode`**: Sets the permissions of the extracted files/directories.

### Dynamic Variables (`{{ ansible_user }}`)
By defining `owner: "{{ ansible_user }}"`, we instruct Ansible to evaluate the connection user defined for the current host in the inventory file.
* When running on `stapp01`, Ansible connects as `tony`. It evaluates `{{ ansible_user }}` to `tony` and assigns ownership of the extracted files to `tony`.
* When running on `stapp02`, it evaluates to `steve`.
This prevents us from having to write a clunky playbook with three separate tasks using `when` conditionals.

### Dependencies
The `unarchive` module requires that the target nodes have the appropriate extraction tools installed. For `.zip` files, the target Linux system must have the `unzip` package installed. In this lab environment, it is typically pre-installed. If it were missing, the playbook would throw an error, and you would need to add a preceding `yum` task to install `unzip`.
  
