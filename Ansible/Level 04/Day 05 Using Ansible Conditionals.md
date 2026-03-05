# Ansible Level 04 Day 05: Using Ansible Conditionals

This document outlines the solution for Ansible Level 04 Day 05. The objective was to create a single Ansible playbook that runs on all hosts but performs different file copy operations depending on the specific server's node name by leveraging the `when` conditional statement.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Verify the Environment](#1-verify-the-environment)
    * [2. Create the Playbook](#2-create-the-playbook)
    * [3. Execute and Validate](#3-execute-and-validate)
3.  [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    * [The `when` Conditional](#the-when-conditional)
    * [Ansible Facts (`ansible_nodename`)](#ansible-facts-ansible_nodename)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Distribute specific files to specific App Servers using a single playbook targeting `all` hosts.

**Requirements:**
1.  **Playbook:** Create `/home/thor/ansible/playbook.yml`.
2.  **Target:** The play must use `- hosts: all`.
3.  **Logic (using `when` condition and `ansible_nodename`):**
    * If node is App Server 1: Copy `/usr/src/finance/blog.txt` to `/opt/finance/blog.txt`. Owner: `tony`, Permissions: `0744`.
    * If node is App Server 2: Copy `/usr/src/finance/story.txt` to `/opt/finance/story.txt`. Owner: `steve`, Permissions: `0744`.
    * If node is App Server 3: Copy `/usr/src/finance/media.txt` to `/opt/finance/media.txt`. Owner: `banner`, Permissions: `0744`.
4.  **Constraint:** Must run cleanly using `ansible-playbook -i inventory playbook.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify the Environment
<a name="1-verify-the-environment"></a>
Before creating the playbook, verify the pre-existing inventory file to ensure we can connect to all target servers. 

**Command:**
```bash
cd /home/thor/ansible
cat inventory
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
Create the playbook using the `copy` module combined with the `when` conditional. We must use `become: yes` because writing to `/opt/finance/` and changing file ownership requires elevated root privileges.

*Note: In the Nautilus Datacenter environment, the `ansible_nodename` fact typically returns the fully qualified domain name (FQDN) like `stapp01.stratos.xfusioncorp.com`.*

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: Copy files using conditionals
  hosts: all
  become: yes
  tasks:
    - name: Show the nodename for debugging (Optional)
      debug:
        msg: "Nodename is: {{ ansible_nodename }}"

    - name: Copy blog.txt to App Server 1
      copy:
        src: /usr/src/finance/blog.txt
        dest: /opt/finance/blog.txt
        owner: tony
        group: tony
        mode: '0744'
      when: ansible_nodename == 'stapp01.stratos.xfusioncorp.com' or ansible_nodename == 'stapp01'

    - name: Copy story.txt to App Server 2
      copy:
        src: /usr/src/finance/story.txt
        dest: /opt/finance/story.txt
        owner: steve
        group: steve
        mode: '0744'
      when: ansible_nodename == 'stapp02.stratos.xfusioncorp.com' or ansible_nodename == 'stapp02'

    - name: Copy media.txt to App Server 3
      copy:
        src: /usr/src/finance/media.txt
        dest: /opt/finance/media.txt
        owner: banner
        group: banner
        mode: '0744'
      when: ansible_nodename == 'stapp03.stratos.xfusioncorp.com' or ansible_nodename == 'stapp03'
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
Run the playbook against the inventory.

**Execution Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Expected Output:**
The output will clearly show the conditional logic in action. You will see tasks being executed on the matching host and skipped on the others:
```text
PLAY [Copy files using conditionals] ************************************************

TASK [Gathering Facts] **************************************************************
ok: [stapp01]
ok: [stapp02]
ok: [stapp03]

TASK [Copy blog.txt to App Server 1] ************************************************
changed: [stapp01]
skipping: [stapp02]
skipping: [stapp03]

TASK [Copy story.txt to App Server 2] ***********************************************
skipping: [stapp01]
changed: [stapp02]
skipping: [stapp03]

TASK [Copy media.txt to App Server 3] ***********************************************
skipping: [stapp01]
skipping: [stapp02]
changed: [stapp03]
...
```

**Manual Verification (Optional):**
To independently verify the content and permissions on the remote servers, use ad-hoc commands:
```bash
ansible stapp01 -i inventory -m command -a "ls -l /opt/finance/blog.txt" --become
ansible stapp02 -i inventory -m command -a "ls -l /opt/finance/story.txt" --become
ansible stapp03 -i inventory -m command -a "ls -l /opt/finance/media.txt" --become
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `when` Conditional
<a name="the-when-conditional"></a>
The `when` statement is Ansible's version of an `if` statement. It evaluates a Jinja2 expression before executing a task. If the expression is true, the task runs. If false, the task is skipped.
* **Syntax:** `when: variable == "value"`
* **Context:** You do not need `{{ }}` brackets inside a `when` clause because it is already evaluated as an implicit Jinja2 context.

### Ansible Facts (`ansible_nodename`)
<a name="ansible-facts-ansible_nodename"></a>
When Ansible runs (specifically during the implicit `Gathering Facts` task at the start of a play), it collects a massive dictionary of data about the remote system.
* **`ansible_hostname`**: Usually just the short hostname (e.g., `stapp01`).
* **`ansible_nodename`** or **`ansible_fqdn`**: Often the fully qualified domain name (FQDN) assigned to the system (e.g., `stapp01.stratos.xfusioncorp.com`).
* **Why use it?** It allows us to define a single play targeting `all` servers, but selectively execute tasks on specific machines without writing multiple separate plays in the playbook.
  
