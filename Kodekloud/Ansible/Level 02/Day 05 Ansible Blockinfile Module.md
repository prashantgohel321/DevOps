# Ansible Level 02 Day 05: Ansible Blockinfile Module

This document outlines the solution for Ansible Level 02 Day 05. The objective was to use Ansible to install the `httpd` web server on all application servers, ensure its service is running, and deploy a sample web page using the `blockinfile` module.

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

**Objective:** Install a web server and configure an `index.html` file using `blockinfile`.

* **Playbook Location:** `/home/thor/ansible/playbook.yml`
* **Inventory Location:** `/home/thor/ansible/inventory` (Already exists)
* **Target Hosts:** All app servers (`hosts: all`)
* **Tasks Required:**
    1.  Install `httpd` package.
    2.  Start and enable `httpd` service.
    3.  Create `/var/www/html/index.html` and add specific multi-line content.
* **File Requirements:**
    * **Owner/Group:** `apache`
    * **Permissions:** `0777`
* **Constraint:** Must run cleanly using `ansible-playbook -i inventory playbook.yml` and must **not** use custom markers for the `blockinfile` module.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify the Environment
<a name="1-verify-the-environment"></a>
Since the inventory file is already provided, quickly review it to ensure it contains the connection variables for the target servers.

**Command:**
```bash
cat /home/thor/ansible/inventory
```
*Ensure it is properly formatted so we don't need to pass extra connection arguments during playbook execution.*

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
Create the YAML playbook to execute the required tasks. Because we are installing packages, managing services, and modifying files in `/var/www/html/`, we must use `become: yes` to execute with root privileges.

**Command:**
```bash
vi /home/thor/ansible/playbook.yml
```

**Content:**
```yaml
---
- name: Set up httpd web server and sample page
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

    - name: Add sample content to index.html
      blockinfile:
        path: /var/www/html/index.html
        create: yes
        block: |
          Welcome to XfusionCorp!
          This is  Nautilus sample file, created using Ansible!
          Please do not modify this file manually!
        owner: apache
        group: apache
        mode: '0777'
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
PLAY [Set up httpd web server and sample page] *****************************************

TASK [Gathering Facts] ****************************************************************
ok: [stapp01]
ok: [stapp02]
ok: [stapp03]

TASK [Install httpd package] **********************************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

TASK [Start and enable httpd service] *************************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

TASK [Add sample content to index.html] ***********************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

PLAY RECAP ****************************************************************************
stapp01                    : ok=4    changed=3    unreachable=0    failed=0    ...
stapp02                    : ok=4    changed=3    unreachable=0    failed=0    ...
stapp03                    : ok=4    changed=3    unreachable=0    failed=0    ...
```

**Manual Verification (Optional):**
You can verify the file was created correctly using an ad-hoc command:
```bash
ansible all -i inventory -m command -a "cat /var/www/html/index.html" --become
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `blockinfile` Module
The `blockinfile` module is designed to insert, update, or remove a multi-line block of text within a file. It is extremely useful for configuring configuration blocks (like virtual hosts or multi-line settings).
* **`create: yes`**: This tells Ansible to create the file if it does not already exist. Without this, the task would fail if `index.html` wasn't already present.
* **`block: |`**: The pipe (`|`) character in YAML denotes a literal block scalar. It preserves the newlines and exact formatting of the text that follows it.
* **Default Markers**: By default, Ansible wraps the inserted block in comment markers (e.g., `# BEGIN ANSIBLE MANAGED BLOCK` and `# END ANSIBLE MANAGED BLOCK`). The task constraints specifically required us **not** to use custom markers (which are normally defined using the `marker` parameter), so we simply left the parameter out, allowing Ansible to use its default behavior.

### Execution Order
The order of tasks in the playbook is critical:
1.  **Install `httpd`**: This step ensures that the `apache` user and group are created on the system, and that the `/var/www/html` directory structure is provisioned.
2.  **Manage Service**: Starts the web server.
3.  **Create File**: If we tried to create the file before installing `httpd`, the task would fail because the `/var/www/html` path might not exist, and the `apache` user/group definitely wouldn't exist to assign ownership.
    
