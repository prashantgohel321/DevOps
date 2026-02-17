# DevOps Day 93: Using Ansible Conditionals

This document outlines the solution for DevOps Day 93. The objective was to create a single Ansible playbook that runs on all hosts but performs different file copy operations depending on the specific server node name using the `when` conditional statement.

## Table of Contents
- [DevOps Day 93: Using Ansible Conditionals](#devops-day-93-using-ansible-conditionals)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Verify Inventory](#1-verify-inventory)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execute and Validate](#3-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `when` Conditional](#the-when-conditional)
    - [Ansible Facts (`ansible_nodename`)](#ansible-facts-ansible_nodename)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Distribute specific files to specific App Servers using a single playbook targeting `all` hosts.

**Requirements:**
1.  **Playbook:** Create `/home/thor/ansible/playbook.yml`.
2.  **Target:** `hosts: all`.
3.  **Logic:**
    * If node is `stapp01`: Copy `blog.txt` to `/opt/devops/`. Owner: `tony`.
    * If node is `stapp02`: Copy `story.txt` to `/opt/devops/`. Owner: `steve`.
    * If node is `stapp03`: Copy `media.txt` to `/opt/devops/`. Owner: `banner`.
4.  **Permissions:** All files must have mode `0655`.
5.  **Condition:** Use `ansible_nodename` or `ansible_hostname` variables.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify Inventory
<a name="1-verify-inventory"></a>
First, I verified the inventory file to ensure we could connect to all target servers.

**Command:**
```bash
cd /home/thor/ansible
cat inventory
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
I created the playbook using the `copy` module combined with the `when` conditional. This allows me to write one play for `hosts: all`, but selectively execute tasks.

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

    - name: Show the nodename for debugging
      debug:
        msg: "Nodename is: {{ ansible_nodename }}"

    - name: Copy blog.txt to app server 1
      copy:
        src: /usr/src/devops/blog.txt
        dest: /opt/devops/blog.txt
        owner: tony
        group: tony
        mode: '0655'
      when: ansible_nodename == "stapp01.stratos.xfusioncorp.com"

    - name: Copy story.txt to app server 2
      copy:
        src: /usr/src/devops/story.txt
        dest: /opt/devops/story.txt
        owner: steve
        group: steve
        mode: '0655'
      when: ansible_nodename == "stapp02.stratos.xfusioncorp.com"    

    - name: Copy media.txt to app server 3
      copy:
        src: /usr/src/devops/media.txt
        dest: /opt/devops/media.txt
        owner: banner
        group: banner
        mode: '0655'
      when: ansible_nodename == "stapp03.stratos.xfusioncorp.com"
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
I ran the playbook against the inventory.

**Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Output Analysis:**
The output clearly shows the conditional logic in action:
* **stapp01:** Executed "Copy blog.txt", skipped "Copy story.txt", skipped "Copy media.txt".
* **stapp02:** Skipped "Copy blog.txt", executed "Copy story.txt", skipped "Copy media.txt".
* **stapp03:** Skipped "Copy blog.txt", skipped "Copy story.txt", executed "Copy media.txt".

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `when` Conditional
<a name="the-when-conditional"></a>
The `when` statement is Ansible's version of an `if` statement. It evaluates a Jinja2 expression. If the expression is true, the task runs. If false, the task is skipped.
* **Syntax:** `when: variable == "value"`
* **Context:** You do not need `{{ }}` brackets inside a `when` clause because it is already an implicit Jinja2 context.

### Ansible Facts (`ansible_nodename`)
<a name="ansible-facts-ansible_nodename"></a>
When Ansible runs (specifically the `Gathering Facts` task), it collects data about the remote system.
* **`ansible_hostname`**: Usually just the short hostname (e.g., `stapp01`).
* **`ansible_nodename`** or **`ansible_fqdn`**: Often the full Fully Qualified Domain Name (e.g., `stapp01.stratos.xfusioncorp.com`).
* **Debugging:** The `debug` task I added was crucial. It revealed that `ansible_nodename` returned the full domain name, not just `stapp01`. This allowed me to fix my `when` condition to match the exact string.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: Tasks skipped on all hosts**
* **Cause:** The conditional check didn't match. For example, checking `when: ansible_nodename == "stapp01"` when the actual value was `stapp01.stratos.xfusioncorp.com`.
* **Fix:** Use the `debug` module to print the variable (`msg: "{{ ansible_nodename }}"`) and copy the exact value into your `when` statement.

**Issue: "Permission denied"**
* **Cause:** Writing to `/opt/devops` requires root privileges.
* **Fix:** Ensure `become: yes` is present at the play level.
  