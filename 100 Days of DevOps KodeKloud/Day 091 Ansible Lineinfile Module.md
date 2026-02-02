# DevOps Day 91: Ansible Lineinfile Module & Web Server Automation

This document outlines the solution for DevOps Day 91. The objective was to create a comprehensive Ansible playbook to deploy an `httpd` web server, create an initial web page, and then modify that page's content dynamically using the `lineinfile` module.

## Table of Contents
- [DevOps Day 91: Ansible Lineinfile Module \& Web Server Automation](#devops-day-91-ansible-lineinfile-module--web-server-automation)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Verify Inventory](#1-verify-inventory)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execute and Validate](#3-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `lineinfile` Module](#the-lineinfile-module)
    - [The `insertbefore` Parameter](#the-insertbefore-parameter)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Install and configure `httpd` on all app servers, deploy an `index.html` with initial text, and insert a new welcome message at the top of the file.

**Requirements:**
1.  **Playbook:** Create `/home/thor/ansible/playbook.yml`.
2.  **Web Server:** Install `httpd`, start the service, and enable it on boot.
3.  **Initial Content:** Create `/var/www/html/index.html` containing "This is a Nautilus sample file, created using Ansible!".
4.  **Modify Content:** Insert "Welcome to xFusionCorp Industries!" at the **top** of the file using `lineinfile`.
5.  **Permissions:** File owner/group: `apache`, Mode: `0644`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify Inventory
<a name="1-verify-inventory"></a>
First, I verified the inventory file to ensure we could connect to all target servers.

**Command:**
```bash
cd /home/thor/ansible
ls -l
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
I created a multi-task playbook to handle the package installation, service management, file creation, and file modification.

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
  
    - name: Start and Enable httpd service
      service:
        name: httpd
        state: started
        enabled: yes

    - name: Create index.html with initial content
      copy:
        dest: /var/www/html/index.html
        content: "This is a Nautilus sample file, created using Ansible!"
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
        mode: '0644'
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
I ran the playbook against the inventory.

**Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Output Analysis:**
```text
TASK [Add welcome message to the top of index.html] ***************************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]
```
* **Changed:** Confirms that Ansible successfully found the file and inserted the new line at the beginning.

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `lineinfile` Module
<a name="the-lineinfile-module"></a>
This module ensures a particular line is in a file, or replaces an existing line using a regular expression. It's powerful for editing configuration files.
* **`path`**: The file to modify.
* **`line`**: The exact line content to insert/ensure exists.
* **`state: present`**: Ensures the line is added if missing.

### The `insertbefore` Parameter
<a name="the-insertbefore-parameter"></a>
The task requirement was to add the line **at the top** of the file.
* **`insertbefore: BOF`**: This is a special alias. `BOF` stands for **Beginning Of File**. It tells Ansible to insert the `line` before the very first line of the file.
* Without this parameter (or using `insertafter: EOF`), the line would be appended to the end.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: "Destination directory does not exist"**
* **Cause:** If `httpd` isn't installed first, `/var/www/html` won't exist.
* **Fix:** Ensure the `yum` task runs before any `copy` or `lineinfile` tasks.

**Issue: Line appended instead of prepended**
* **Cause:** Forgetting `insertbefore: BOF`.
* **Fix:** Add the parameter to the `lineinfile` task.

**Issue: "Permission denied"**
* **Cause:** Modifying files in `/var/www/html` requires root privileges.
* **Fix:** Ensure `become: yes` is set at the play level.
   