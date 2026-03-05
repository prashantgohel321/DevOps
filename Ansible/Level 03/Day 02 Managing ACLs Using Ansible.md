# Ansible Level 03 Day 02: Managing ACLs using Ansible

This document outlines the solution for Ansible Level 03 Day 02. The objective was to create specific files on different application servers with `root` ownership, and then configure Access Control Lists (ACLs) to grant granular permissions to specific application users and groups.

## Table of Contents
- [Ansible Level 03 Day 02: Managing ACLs using Ansible](#ansible-level-03-day-02-managing-acls-using-ansible)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Verify Inventory](#1-verify-inventory)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execute and Validate](#3-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `acl` Module](#the-acl-module)
    - [Targeting Specific Hosts](#targeting-specific-hosts)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Create files under `/opt/data/` on three app servers and set specific ACLs without altering the `root` base ownership.

**Requirements:**
1.  **Playbook:** Create `/home/thor/ansible/playbook.yml`.
2.  **App Server 1 (`stapp01`):**
    * Create `/opt/data/blog.txt`. Owner: `root`.
    * ACL: Grant `read (r)` permission to **group** `tony`.
3.  **App Server 2 (`stapp02`):**
    * Create `/opt/data/story.txt`. Owner: `root`.
    * ACL: Grant `read + write (rw)` permission to **user** `steve`.
4.  **App Server 3 (`stapp03`):**
    * Create `/opt/data/media.txt`. Owner: `root`.
    * ACL: Grant `read + write (rw)` permission to **group** `banner`.
5.  **Constraint:** Must run cleanly using `ansible-playbook -i inventory playbook.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify Inventory
<a name="1-verify-inventory"></a>
First, ensure that the inventory file exists and connection details are correct.

**Command:**
```bash
cd /home/thor/ansible
cat inventory
```
*(Verify it lists stapp01, stapp02, and stapp03 with proper connection variables).*

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
Structure the playbook with three distinct plays, each targeting a specific host (`stapp01`, `stapp02`, `stapp03`) to handle their unique file path, ownership, and ACL requirements. 

Writing to `/opt/data/` and setting ACLs requires root privileges, so we must use `become: yes`.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: Configure App Server 1
  hosts: stapp01
  become: yes
  tasks:
    - name: Create empty file blog.txt
      file: 
        path: /opt/data/blog.txt
        state: touch
        owner: root
        group: root
 
    - name: Set ACL for group tony
      acl:
        path: /opt/data/blog.txt
        entity: tony
        etype: group
        permissions: r
        state: present

- name: Configure App Server 2
  hosts: stapp02
  become: yes
  tasks:
    - name: Create empty file story.txt
      file:
        path: /opt/data/story.txt
        state: touch
        owner: root
        group: root

    - name: Set ACL for user steve
      acl:
        path: /opt/data/story.txt
        entity: steve
        etype: user
        permissions: rw
        state: present

- name: Configure App Server 3
  hosts: stapp03
  become: yes
  tasks:
    - name: Create empty file media.txt
      file:
        path: /opt/data/media.txt
        state: touch
        owner: root
        group: root

    - name: Set ACL for group banner
      acl:
        path: /opt/data/media.txt
        entity: banner
        etype: group
        permissions: rw
        state: present
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
Execute the playbook and then verify the ACLs on the remote servers.

**Execution Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Output Analysis:**
```text
PLAY [Configure App Server 1] *******************************************************
changed: [stapp01] (File Created)
changed: [stapp01] (ACL Set)

PLAY [Configure App Server 2] *******************************************************
changed: [stapp02] (File Created)
changed: [stapp02] (ACL Set)

PLAY [Configure App Server 3] *******************************************************
changed: [stapp03] (File Created)
changed: [stapp03] (ACL Set)
```

**Manual Verification (Optional):**
To ensure the ACLs were correctly applied, use the `getfacl` command on the remote servers via ad-hoc Ansible commands. Because the files exist on separate servers, verify them individually:
```bash
ansible stapp01 -i inventory -a "getfacl /opt/data/blog.txt" --become
ansible stapp02 -i inventory -a "getfacl /opt/data/story.txt" --become
ansible stapp03 -i inventory -a "getfacl /opt/data/media.txt" --become
```
*Look for outputs like `group:tony:r--`, `user:steve:rw-`, and `group:banner:rw-` respectively.*

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `acl` Module
<a name="the-acl-module"></a>
Standard Linux permissions (`chmod`) only allow setting permissions for one owner, one group, and "others". ACLs (Access Control Lists) allow fine-grained control, granting permissions to *specific* extra users or groups without changing the base ownership.
* **`entity`**: The name of the user or group receiving the permission (e.g., `tony`, `steve`).
* **`etype`**: The type of entity (`user` or `group`).
* **`permissions`**: The permission string (e.g., `r`, `w`, `x`, `rw`, `rwx`).
* **`state: present`**: Ensures the specified ACL rule exists and is enforced.

### Targeting Specific Hosts
<a name="targeting-specific-hosts"></a>
Unlike tasks where every server receives the exact same configuration (using `hosts: all`), this task required entirely different files, entities, and permission combinations per server. We achieved this cleanly by writing **three separate plays** in one playbook file:
1.  `- name: Configure App Server 1` -> `hosts: stapp01`
2.  `- name: Configure App Server 2` -> `hosts: stapp02`
3.  `- name: Configure App Server 3` -> `hosts: stapp03`
   
