# Ansible Level 03 Day 04: Ansible Lineinfile Module

This document outlines the solution for Ansible Level 03 Day 04. The objective was to create a comprehensive Ansible playbook to deploy an `httpd` web server, create an initial web page, and then modify that page's content dynamically using the `lineinfile` module.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Verify the Environment](#1-verify-the-environment)
    * [2. Create the Playbook](#2-create-the-playbook)
    * [3. Execute and Validate](#3-execute-and-validate)
3.  [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    * [The `lineinfile` Module](#the-lineinfile-module)
    * [The `insertbefore` Parameter](#the-insertbefore-parameter)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Install and configure `httpd` on all app servers, deploy an `index.html` with initial text, and insert a new welcome message at the top of the file.

**Requirements:**
1.  **Playbook:** Create `/home/thor/ansible/playbook.yml`.
2.  **Web Server:** Install `httpd` and ensure the service is running.
3.  **Initial Content:** Create `/var/www/html/index.html` containing "This is a Nautilus sample file, created using Ansible!".
4.  **Modify Content:** Insert "Welcome to xFusionCorp Industries!" at the **top** of the file using `lineinfile`.
5.  **Permissions:** File owner/group: `apache`, Mode: `0655`.
6.  **Constraint:** Must run cleanly using `ansible-playbook -i inventory playbook.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify the Environment
<a name="1-verify-the-environment"></a>
Before creating the playbook, verify the pre-existing inventory file to ensure the target hosts are ready.

**Command:**
```bash
cd /home/thor/ansible
cat inventory
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
Create a multi-task YAML playbook to handle the package installation, service management, file creation, and file modification. We need `become: yes` because we are installing packages and writing to `/var/www/html`.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: Deploy and Configure Web Server
  hosts: all
  become: yes
  tasks:
    - name: Install httpd package
      yum:
        name: httpd
        state: present
  
    - name: Start and enable httpd service
      service:
        name: httpd
        state: started
        enabled: yes

    - name: Create index.html with initial content
      copy:
        dest: /var/www/html/index.html
        content: "This is a Nautilus sample file, created using Ansible!\n"
        force: yes

    - name: Add welcome message to the top of index.html
      lineinfile:
        path: /var/www/html/index.html
        line: "Welcome to xFusionCorp Industries!"
        insertbefore: BOF
        state: present
  
    - name: Set ownership and permission for index.html
      file: 
        path: /var/www/html/index.html
        owner: apache
        group: apache
        mode: '0655'
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
Run the playbook from the `/home/thor/ansible/` directory.

**Execution Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Expected Output:**
```text
PLAY [Deploy and Configure Web Server] **********************************************

TASK [Gathering Facts] **************************************************************
ok: [stapp01]
ok: [stapp02]
ok: [stapp03]

TASK [Install httpd package] ********************************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

TASK [Start and enable httpd service] ***********************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

TASK [Create index.html with initial content] ***************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

TASK [Add welcome message to the top of index.html] *********************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

TASK [Set ownership and permission for index.html] **********************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

PLAY RECAP **************************************************************************
stapp01                    : ok=6    changed=5    unreachable=0    failed=0    ...
stapp02                    : ok=6    changed=5    unreachable=0    failed=0    ...
stapp03                    : ok=6    changed=5    unreachable=0    failed=0    ...
```

**Manual Verification (Optional):**
To independently verify the content and permissions on the remote servers, use an ad-hoc command:
```bash
ansible all -i inventory -m command -a "cat /var/www/html/index.html"
ansible all -i inventory -m command -a "ls -l /var/www/html/index.html"
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `lineinfile` Module
<a name="the-lineinfile-module"></a>
This module ensures a particular line is in a file, or replaces an existing line using a regular expression. It's highly effective for editing configuration files or appending specific data.
* **`path`**: The file to modify.
* **`line`**: The exact line content to insert or ensure exists.
* **`state: present`**: Ensures the line is added if missing.

### The `insertbefore` Parameter
<a name="the-insertbefore-parameter"></a>
The task requirement specified adding the line **at the top** of the file.
* **`insertbefore: BOF`**: `BOF` is a special alias standing for **Beginning Of File**. It directs Ansible to insert the `line` before the very first line of the file. If omitted (or if `insertafter: EOF` is used), the line defaults to being appended to the end of the file.

**Execution Order matters:**
The `copy` task must precede the `lineinfile` task to ensure the file exists and has the base content before Ansible attempts to inject the new line at the top. Furthermore, the `yum` task must run first so the `/var/www/html` directory structure exists.
   
