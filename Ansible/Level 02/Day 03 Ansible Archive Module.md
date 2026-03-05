# Ansible Level 02 Day 03: Ansible Archive Module

This document outlines the solution for Ansible Level 02 Day 03. The objective was to use Ansible to compress a specific directory on remote application servers into a `tar.gz` archive, place it in a new location, and assign specific ownership based on the server.

## Table of Contents
- [Ansible Level 02 Day 03: Ansible Archive Module](#ansible-level-02-day-03-ansible-archive-module)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Verify the Environment](#1-verify-the-environment)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execute and Validate](#3-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `archive` Module](#the-archive-module)
    - [Dynamic Variables (`{{ ansible_user }}`)](#dynamic-variables--ansible_user-)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Archive data on all application servers with specific dynamic ownership.

* **Playbook Location:** `/home/thor/ansible/playbook.yml`
* **Inventory Location:** `/home/thor/ansible/inventory` (Already exists)
* **Source Directory:** `/usr/src/dba/`
* **Destination Archive:** `/opt/dba/official.tar.gz`
* **Format:** `tar.gz`
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
Since the inventory file is already provided, it is best practice to quickly review it to ensure it contains the standard connection variables that align with our dynamic ownership requirement.

**Command:**
```bash
cat /home/thor/ansible/inventory
```
*You should see that `stapp01` uses `ansible_user=tony`, `stapp02` uses `ansible_user=steve`, etc. We will leverage this `ansible_user` variable in our playbook.*

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
Create the YAML playbook to utilize the `archive` module. Because we are reading from `/usr/src/` and writing to `/opt/`, we must use `become: yes` to execute with root privileges. 

We will use the `{{ ansible_user }}` variable to dynamically satisfy the ownership requirements without writing three separate tasks.

**Command:**
```bash
vi /home/thor/ansible/playbook.yml
```

**Content:**
```yaml
---
- name: Archive data on app servers
  hosts: all
  become: yes
  tasks:
    - name: Create archive of /usr/src/dba/
      archive:
        path: /usr/src/dba/
        dest: /opt/dba/official.tar.gz
        format: gz
        owner: "{{ ansible_user }}"
        group: "{{ ansible_user }}"
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
PLAY [Archive data on app servers] ****************************************************

TASK [Gathering Facts] ****************************************************************
ok: [stapp01]
ok: [stapp02]
ok: [stapp03]

TASK [Create archive of /usr/src/dba/] ************************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

PLAY RECAP ****************************************************************************
stapp01                    : ok=2    changed=1    unreachable=0    failed=0    ...
stapp02                    : ok=2    changed=1    unreachable=0    failed=0    ...
stapp03                    : ok=2    changed=1    unreachable=0    failed=0    ...
```

**Manual Verification (Optional):**
You can verify the file was created and has the correct ownership using an ad-hoc command:
```bash
ansible all -i inventory -m command -a "ls -l /opt/dba/official.tar.gz" --become
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `archive` Module
The `archive` module creates a compressed archive of one or multiple files/directories on the target machine. It does not transfer the files back to the controller; it leaves the generated archive on the remote node.
* **`path`**: The source directory or file to compress.
* **`dest`**: The absolute path where the archive will be saved.
* **`format`**: Specifies the compression type. Setting this to `gz` creates a `tar.gz` (gzip compressed tarball) file, which matches the required `official.tar.gz` extension.

### Dynamic Variables (`{{ ansible_user }}`)
By defining `owner: "{{ ansible_user }}"`, we instruct Ansible to evaluate the connection user defined for the current host in the inventory file.
* When running on `stapp01`, Ansible connects as `tony`. It evaluates `{{ ansible_user }}` to `tony` and assigns ownership to `tony`.
* When running on `stapp02`, it evaluates to `steve`.
This prevents us from having to write a clunky playbook with three separate tasks using `when` conditionals.
  
