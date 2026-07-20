# Ansible Level 04 Day 01: Ansible Facts Gathering

This document outlines the solution for Ansible Level 04 Day 01. The objective was to configure a simple Apache web server across all application servers and populate the default `index.html` file with dynamically generated content using Ansible Facts.

## Table of Contents
- [Ansible Level 04 Day 01: Ansible Facts Gathering](#ansible-level-04-day-01-ansible-facts-gathering)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Verify the Environment](#1-verify-the-environment)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execute and Validate](#3-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [Ansible Facts Gathering](#ansible-facts-gathering)
    - [Remote File Copying](#remote-file-copying)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Install an `httpd` web server and create a dynamically generated `index.html` file that displays the managed node's architecture.

**Requirements:**
1.  **Playbook Location:** `/home/thor/playbooks/index.yml`
2.  **Inventory Location:** `/home/thor/playbooks/inventory` (Already exists)
3.  **Target Hosts:** All app servers
4.  **Tasks Required:**
    * Create a file `/root/facts.txt` using the `blockinfile` module.
    * The block must contain: `Ansible managed node architecture is <architecture>` (using the gathered fact variable).
    * Install the `httpd` server.
    * Copy `/root/facts.txt` to `/var/www/html/index.html`.
    * Start the `httpd` service.
5.  **Constraint:** Do not use separate roles. Include all tasks sequentially within `index.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify the Environment
<a name="1-verify-the-environment"></a>
First, confirm that the inventory file exists and is correctly located in the `playbooks` directory.

**Command:**
```bash
cd /home/thor/playbooks
cat inventory
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
Create the single `index.yml` playbook. Since we are creating files in `/root`, installing packages, and managing system services, we must use `become: yes` to execute with root privileges. We must also ensure `gather_facts: yes` is set so the `ansible_architecture` variable is populated.

**Command:**
```bash
vi index.yml
```

**Content:**
```yaml
---
- name: Setup httpd and gather system facts
  hosts: all
  become: yes
  gather_facts: yes
  tasks:
    - name: Create facts.txt with architecture information
      blockinfile:
        path: /root/facts.txt
        create: yes
        block: |
          Ansible managed node architecture is {{ ansible_architecture }}

    - name: Install httpd server
      yum:
        name: httpd
        state: present

    - name: Copy facts.txt to index.html
      copy:
        src: /root/facts.txt
        dest: /var/www/html/index.html
        remote_src: yes

    - name: Start and enable httpd service
      service:
        name: httpd
        state: started
        enabled: yes
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
Run the playbook from the directory containing the inventory file.

**Execution Command:**
```bash
ansible-playbook -i inventory index.yml
```

**Expected Output:**
```text
PLAY [Setup httpd and gather system facts] *******************************************

TASK [Gathering Facts] ***************************************************************
ok: [stapp01]
ok: [stapp02]
ok: [stapp03]

TASK [Create facts.txt with architecture information] ********************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

TASK [Install httpd server] **********************************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

TASK [Copy facts.txt to index.html] **************************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

TASK [Start and enable httpd service] ************************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

PLAY RECAP ***************************************************************************
stapp01                    : ok=5    changed=4    unreachable=0    failed=0    ...
stapp02                    : ok=5    changed=4    unreachable=0    failed=0    ...
stapp03                    : ok=5    changed=4    unreachable=0    failed=0    ...
```

**Manual Verification (Optional):**
To independently verify the content has correctly rendered the `x86_64` (or similar) architecture string, use an ad-hoc command:
```bash
ansible all -i inventory -m command -a "cat /var/www/html/index.html" --become
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### Ansible Facts Gathering
<a name="ansible-facts-gathering"></a>
Ansible Facts are data gathered about the target nodes before executing the main tasks. This is represented by the implicit `TASK [Gathering Facts]` step.
* **`gather_facts: yes`**: While this is the default behavior in Ansible, explicitly stating it ensures the playbook is readable and self-documenting.
* **`{{ ansible_architecture }}`**: This is a specific fact collected by the `setup` module. When Ansible runs on the target node, it evaluates its architecture (e.g., `x86_64`, `aarch64`) and replaces the Jinja2 variable with the real value.

*(Pro tip: To see all available facts for a host, you can run `ansible stapp01 -i inventory -m setup`)*

### Remote File Copying
<a name="remote-file-copying"></a>
In the `copy` task, we used `remote_src: yes`.
* **Without `remote_src` (Default)**: Ansible expects the `src` file to exist on the *Control Node* (the Jump Host) and copies it across the network to the Managed Node.
* **With `remote_src: yes`**: Ansible knows the `src` file *already exists on the Managed Node* (because we just created it in `/root` during the previous step). It executes a local copy command directly on the target server, moving the file from `/root/facts.txt` to `/var/www/html/index.html`.
   
