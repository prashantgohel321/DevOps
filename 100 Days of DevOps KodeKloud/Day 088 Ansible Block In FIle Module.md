# DevOps Day 88: Ansible Blockinfile Module

This document outlines the solution for DevOps Day 88. The objective was to use Ansible to install a web server (`httpd`) and deploy a sample `index.html` file using the `blockinfile` module, ensuring specific content, ownership, and permissions.

## Table of Contents
- [DevOps Day 88: Ansible Blockinfile Module](#devops-day-88-ansible-blockinfile-module)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Verify Inventory](#1-verify-inventory)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execute and Validate](#3-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `blockinfile` Module](#the-blockinfile-module)
    - [Service Management](#service-management)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Install `httpd` on all app servers and create `/var/www/html/index.html` with specific multi-line content using Ansible.

**Requirements:**
1.  **Playbook:** Create `/home/thor/ansible/playbook.yml`.
2.  **Package:** Install `httpd` and ensure the service is running/enabled.
3.  **Content:** Use `blockinfile` to add the welcome message to `index.html`.
4.  **Permissions:** File owner/group: `apache`, Mode: `0744`.
5.  **Constraints:** Do not use custom markers.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify Inventory
<a name="1-verify-inventory"></a>
Before writing the playbook, I ensured the inventory file existed and was correct.

**Command:**
```bash
cd /home/thor/ansible
ls -l
# Expected output: inventory file exists
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
I created the playbook to handle three main tasks: installing the package, starting the service, and managing the file content.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: setup and configure httpd server
  hosts: all
  become: true
  tasks:
    - name: install httpd package
      yum: 
        name: httpd
        state: present

    - name: start and enable httpd service
      service:
        name: httpd
        state: started
        enabled: yes

    - name: add content to index.html using blockinfile
      blockinfile:
        path: /var/www/html/index.html
        create: yes
        block: |
          Welcome to XfusionCorp!
          This is Nautilus sample file, created using Ansible!
          Please do not modify this file manually!
        owner: apache
        group: apache
        mode: '0744'
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
I ran the playbook using the standard command.

**Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Output Analysis:**
```text
TASK [install httpd package] ********************************************************
ok: [stapp03]
ok: [stapp01]
changed: [stapp02]

TASK [add content to index.html using blockinfile] **********************************
changed: [stapp02]
ok: [stapp03]
ok: [stapp01]
```
* **Changed:** Indicates Ansible performed an action (installed package, added content).
* **Ok:** Indicates the state was already correct (idempotency).

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `blockinfile` Module
<a name="the-blockinfile-module"></a>
This module inserts, updates, or removes a block of multi-line text surrounded by marker lines.
* **`create: yes`**: If the file doesn't exist, create it. This effectively creates our `index.html`.
* **`block: |`**: The `|` character allows us to define a multi-line string in YAML, preserving newlines.
* **Markers:** By default, Ansible wraps the content in `# BEGIN ANSIBLE MANAGED BLOCK` and `# END ANSIBLE MANAGED BLOCK`. This makes it easy for Ansible to find and update this specific section later without overwriting the rest of the file.

### Service Management
<a name="service-management"></a>
The `service` module ensures the web server is actually running.
* `state: started`: Starts the service immediately.
* `enabled: yes`: Ensures the service starts automatically if the server reboots.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: "Shared connection closed" (rc 137)**
* **Context:** In the provided logs, `stapp02` initially failed with this error.
* **Cause:** This is often a transient SSH connection issue or resource limit (OOM kill) on the remote host during package installation.
* **Fix:** Re-running the playbook usually resolves it, as seen in the successful second run. Ansible is idempotent, so it picks up right where it left off.

**Issue: "Destination directory /var/www/html does not exist"**
* **Cause:** The `httpd` package creates this directory. If the install task fails or runs out of order, the directory won't exist for the `blockinfile` task.
* **Fix:** Ensure the `yum` task runs *before* the `blockinfile` task.
   