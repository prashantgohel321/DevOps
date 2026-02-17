# DevOps Day 90: Managing ACLs using Ansible

This document outlines the solution for DevOps Day 90. The objective was to create specific files on different application servers and configure Access Control Lists (ACLs) to grant granular permissions to specific users and groups using Ansible.

## Table of Contents
- [DevOps Day 90: Managing ACLs using Ansible](#devops-day-90-managing-acls-using-ansible)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Verify Inventory](#1-verify-inventory)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execute and Validate](#3-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `acl` Module](#the-acl-module)
    - [Targeting Specific Hosts](#targeting-specific-hosts)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Create files under `/opt/sysops/` on three app servers and set specific ACLs.

**Requirements:**
1.  **Playbook:** Create `/home/thor/ansible/playbook.yml`.
2.  **App Server 1 (`stapp01`):**
    * Create `blog.txt`. Owner: `root`.
    * ACL: Grant `read (r)` permission to group `tony`.
3.  **App Server 2 (`stapp02`):**
    * Create `story.txt`. Owner: `root`.
    * ACL: Grant `read + write (rw)` permission to user `steve`.
4.  **App Server 3 (`stapp03`):**
    * Create `media.txt`. Owner: `root`.
    * ACL: Grant `read + write (rw)` permission to group `banner`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify Inventory
<a name="1-verify-inventory"></a>
First, I verified the inventory file to ensure connection details were correct.

**Command:**
```bash
cd /home/thor/ansible
cat inventory
```

**Content:**
```ini
stapp01 ansible_host=172.16.238.10 ansible_ssh_pass=Ir0nM@n ansible_user=tony
stapp02 ansible_host=172.16.238.11 ansible_ssh_pass=Am3ric@ ansible_user=steve
stapp03 ansible_host=172.16.238.12 ansible_ssh_pass=BigGr33n ansible_user=banner
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
I structured the playbook with three distinct plays, each targeting a specific host (`stapp01`, `stapp02`, `stapp03`) to handle their unique requirements.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: Configure App Server 1
  hosts: stapp01
  become: true
  tasks:
    - name: Create empty file blog.txt
      file: 
        path: /opt/sysops/blog.txt
        state: touch
        owner: root
        group: root
        mode: '0644'
 
    - name: Set ACL for group tony
      acl:
        path: /opt/sysops/blog.txt
        entity: tony
        etype: group
        permissions: r
        state: present

- name: Configure App Server 2
  hosts: stapp02
  become: true
  tasks:
    - name: Create empty file story.txt
      file:
        path: /opt/sysops/story.txt
        state: touch
        owner: root
        group: root
        mode: '0644'

    - name: Set ACL for user steve
      acl:
        path: /opt/sysops/story.txt
        entity: steve
        etype: user
        permissions: rw
        state: present

- name: Configure App Server 3
  hosts: stapp03
  become: true
  tasks:
    - name: Create empty file media.txt
      file:
        path: /opt/sysops/media.txt
        state: touch
        owner: root
        group: root
        mode: '0644'

    - name: Set ACL for group banner
      acl:
        path: /opt/sysops/media.txt
        entity: banner
        etype: group
        permissions: rw
        state: present
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
I executed the playbook and then verified the ACLs on the remote servers.

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

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `acl` Module
<a name="the-acl-module"></a>
Standard Linux permissions (`chmod`) only allow setting permissions for one owner, one group, and "others". ACLs (Access Control Lists) allow fine-grained control, giving permissions to *specific* extra users or groups.
* **`entity`**: The name of the user or group (e.g., `tony`, `steve`).
* **`etype`**: The type of entity (`user` or `group`).
* **`permissions`**: The permission string (e.g., `r`, `rw`, `rwx`).
* **`state: present`**: Ensures the ACL rule exists.

### Targeting Specific Hosts
<a name="targeting-specific-hosts"></a>
Unlike previous tasks where we used `hosts: all`, this task required different actions on different servers. I achieved this by writing **three separate plays** in one playbook file:
1.  `- name: Configure App Server 1` -> `hosts: stapp01`
2.  `- name: Configure App Server 2` -> `hosts: stapp02`
3.  `- name: Configure App Server 3` -> `hosts: stapp03`

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: `getfacl: No such file or directory`**
* **Cause:** As seen in the provided logs (`stapp03 | FAILED`), running a verification command on *all* servers for a file that only exists on *one* server will cause errors on the other two.
* **Fix:** Verify files individually per server:
    ```bash
    ansible stapp01 -i inventory -a "getfacl /opt/sysops/blog.txt" --become
    ansible stapp02 -i inventory -a "getfacl /opt/sysops/story.txt" --become
    ```

**Issue: "Operation not supported"**
* **Cause:** The filesystem on the remote host might not have ACLs enabled.
* **Fix:** (Usually handled by sysadmin) Remount the partition with the `acl` option. In this lab environment, it's usually pre-configured.
   