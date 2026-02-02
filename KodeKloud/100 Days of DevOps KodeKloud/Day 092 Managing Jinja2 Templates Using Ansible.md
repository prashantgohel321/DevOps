# DevOps Day 92: Managing Jinja2 Templates Using Ansible

This document outlines the solution for DevOps Day 92. The objective was to enhance an existing Ansible role for `httpd` by adding a dynamic Jinja2 template for the `index.html` file. This demonstrates how Ansible can customize configuration files based on the specific server it is deploying to.

## Table of Contents
- [DevOps Day 92: Managing Jinja2 Templates Using Ansible](#devops-day-92-managing-jinja2-templates-using-ansible)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the Template](#1-create-the-template)
    - [2. Update the Role Tasks](#2-update-the-role-tasks)
    - [3. Configure the Playbook](#3-configure-the-playbook)
    - [4. Execute and Validate](#4-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [Jinja2 Templates](#jinja2-templates)
    - [The `template` Module](#the-template-module)
    - [Ansible Roles](#ansible-roles)
  - [Internal Execution Flow](#internal-execution-flow)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Deploy an `httpd` role to App Server 1 (`stapp01`) that includes a dynamically generated `index.html` file using a Jinja2 template.

**Requirements:**
1.  **Playbook:** Update `~/ansible/playbook.yml` to target `stapp01` and use the `httpd` role.
2.  **Template:** Create `index.html.j2` inside the role's templates directory. It must use the `{{ inventory_hostname }}` variable.
3.  **Task:** Add a task to `main.yml` to deploy this template to `/var/www/html/index.html`.
4.  **Permissions:** Set file permissions to `0777` and ownership to the respective user (e.g., `tony` for `stapp01`).

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Template
<a name="1-create-the-template"></a>
The core requirement is to create a file that changes its content based on where it is deployed.

**Command:**
```bash
cd ~/ansible/role/httpd/templates/
vi index.html.j2
```

**Content:**
```jinja2
This file was created using Ansible on {{ inventory_hostname }}
```
* **`.j2` Extension:** This signifies a Jinja2 template file. Ansible processes this file before sending it to the remote server.
* **`{{ inventory_hostname }}`:** This is an Ansible "magic variable". When the playbook runs on `stapp01`, Ansible automatically replaces this placeholder with the string "stapp01".

### 2. Update the Role Tasks
<a name="2-update-the-role-tasks"></a>
Next, I updated the role's main task file to include the template deployment step.

**Command:**
```bash
cd ~/ansible/role/httpd/tasks/
vi main.yml
```

**Content:**
```yaml
---
# tasks file for role/httpd

- name: install the latest version of HTTPD
  yum:
    name: httpd
    state: latest

- name: Start service httpd
  service:
    name: httpd
    state: started

- name: Copy index.html template
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
    mode: '0777'
    owner: "{{ ansible_user }}"
    group: "{{ ansible_user }}"
```
* **`template` module:** This module reads the local `.j2` file, processes the variables inside it, and writes the resulting static file to the remote `dest`.
* **`owner: "{{ ansible_user }}"`**: This ensures the file is owned by the user we connected as (e.g., `tony`), fulfilling the dynamic ownership requirement.

### 3. Configure the Playbook
<a name="3-configure-the-playbook"></a>
I updated the main playbook to call the role for the correct host.

**Command:**
```bash
cd ~/ansible/
vi playbook.yml
```

**Content:**
```yaml
---
- hosts: stapp01
  become: yes
  become_user: root
  roles:
    - role/httpd
```

### 4. Execute and Validate
<a name="4-execute-and-validate"></a>
I ran the playbook and verified the result.

**Execution Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Verification:**
```bash
ansible -i inventory stapp01 -a "cat /var/www/html/index.html"
```
**Output:**
`This file was created using Ansible on stapp01`

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### Jinja2 Templates
<a name="jinja2-templates"></a>
Jinja2 is a modern and designer-friendly templating language for Python. In Ansible, it allows you to:
* **Dynamic Content:** Insert variable values (like IPs, hostnames, usernames).
* **Logic:** Use `{% if %}` statements or `{% for %}` loops to generate complex configuration files (e.g., adding a config block only if a certain variable is true).

### The `template` Module
<a name="the-template-module"></a>
Unlike the `copy` module, which transfers a file exactly as-is, the `template` module processes the file on the Ansible control node first.
1.  Ansible reads `src` (local).
2.  The Jinja2 engine replaces all `{{ variables }}` with their actual values for the current host.
3.  The rendered file is transferred to `dest` (remote).

### Ansible Roles
<a name="ansible-roles"></a>
Roles are the primary way to break a playbook into multiple files. This simplifies writing complex playbooks and makes them easier to reuse. A role structure looks like:
* `tasks/main.yml`: The main list of tasks to execute.
* `templates/`: Where `.j2` files are stored.
* `handlers/`: Handlers like "restart service".
* `vars/`: Variables specific to the role.

---

## Internal Execution Flow
<a name="internal-execution-flow"></a>

When you ran `ansible-playbook -i inventory playbook.yml`, the following process occurred internally:

1.  **Parsing:** Ansible read `playbook.yml`, identified the target host `stapp01`, and saw it needed to run the `role/httpd`.
2.  **Inventory Lookup:** It looked up `stapp01` in the `inventory` file to find the IP address, SSH user (`tony`), and password (`Ir0nM@n`).
3.  **Fact Gathering:** It connected to `stapp01` via SSH and ran the `setup` module to gather facts (IP addresses, OS version, hostname). This populated the `inventory_hostname` variable.
4.  **Task Execution (Yum/Service):** It executed the `yum` and `service` tasks using `sudo` privileges (`become: yes`).
5.  **Templating Engine:**
    * Ansible paused at the `template` task.
    * On the **Jump Host (Local)**, it loaded `index.html.j2`.
    * It found `{{ inventory_hostname }}` and replaced it with the value `"stapp01"`.
    * It found `{{ ansible_user }}` and replaced it with `"tony"`.
6.  **File Transfer:** Ansible securely transferred the *rendered* content (now just plain text) to a temporary file on `stapp01`.
7.  **Finalize:** It moved the temporary file to `/var/www/html/index.html` and set the permissions to `0777` and owner to `tony`.
   