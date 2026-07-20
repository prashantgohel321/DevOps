# Ansible Level 02 Day 02: Ansible Install Package

This document outlines the solution for Ansible Level 02 Day 02. The objective was to configure an inventory of application servers and automate the installation of the `zip` package across all of them using Ansible's `yum` module.

## Table of Contents
- [Ansible Level 02 Day 02: Ansible Install Package](#ansible-level-02-day-02-ansible-install-package)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the Inventory File](#1-create-the-inventory-file)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execute and Validate](#3-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `yum` Module](#the-yum-module)
    - [Privilege Escalation (`become: yes`)](#privilege-escalation-become-yes)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Install the `zip` package on all application servers using Ansible.

* **Inventory Location:** `/home/thor/playbook/inventory`
* **Playbook Location:** `/home/thor/playbook/playbook.yml`
* **Target Nodes:** All app servers (`stapp01`, `stapp02`, `stapp03`)
* **Module:** `yum`
* **Execution Constraint:** Must run successfully via `ansible-playbook -i inventory playbook.yml` without any extra CLI arguments.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Inventory File
<a name="1-create-the-inventory-file"></a>
We must configure the inventory to include all three application servers and their connection credentials to satisfy the strict execution command constraint.

**Command:**
```bash
mkdir -p /home/thor/playbook
cd /home/thor/playbook
vi inventory
```

**Content:**
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
Create the YAML playbook to define the package installation task. Since installing packages requires root access, we must include `become: yes` so Ansible runs the command with `sudo` privileges.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: Install zip package on application servers
  hosts: all
  become: yes
  tasks:
    - name: Ensure zip is installed
      yum:
        name: zip
        state: present
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
Run the playbook to provision the packages.

**Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Expected Output:**
```text
PLAY [Install zip package on application servers] ***********************************

TASK [Gathering Facts] **************************************************************
ok: [stapp01]
ok: [stapp02]
ok: [stapp03]

TASK [Ensure zip is installed] ******************************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

PLAY RECAP **************************************************************************
stapp01                    : ok=2    changed=1    unreachable=0    failed=0    ...
stapp02                    : ok=2    changed=1    unreachable=0    failed=0    ...
stapp03                    : ok=2    changed=1    unreachable=0    failed=0    ...
```

**Manual Verification (Optional):**
You can verify the package was installed by running an ad-hoc command across the inventory:
```bash
ansible all -i inventory -a "zip -v"
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `yum` Module
Ansible uses the `yum` module to interact with the Yellowdog Updater Modified package manager on RedHat-based systems (like CentOS used in this lab).
* **`name: zip`**: Specifies the package we want to manage.
* **`state: present`**: This tells Ansible to ensure the package is installed. If `zip` is already installed, Ansible will recognize this and do nothing (reporting `ok` instead of `changed`). If we wanted the absolute newest version, we would use `state: latest`.

### Privilege Escalation (`become: yes`)
By default, Ansible connects as the user specified in the inventory (e.g., `tony`, `steve`). Regular users do not have permissions to install software system-wide via `yum`. Adding `become: yes` instructs Ansible to use `sudo` to elevate its privileges to `root` before running the task. In this specific environment, these users have passwordless `sudo` rights, allowing the playbook to run without prompting for a sudo password.
  
