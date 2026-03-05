# Ansible Level 04 Day 03: Managing Jinja2 Templates using Ansible

This document outlines the solution for Ansible Level 04 Day 03. The objective was to update an existing Ansible role (`httpd`) by incorporating a Jinja2 template to dynamically generate an `index.html` file and executing this role specifically on App Server 2.

## Table of Contents
- [Ansible Level 04 Day 03: Managing Jinja2 Templates using Ansible](#ansible-level-04-day-03-managing-jinja2-templates-using-ansible)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Update the Playbook](#1-update-the-playbook)
    - [2. Create the Jinja2 Template](#2-create-the-jinja2-template)
    - [3. Update the Role Tasks](#3-update-the-role-tasks)
    - [4. Execute and Validate](#4-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [Jinja2 Templates](#jinja2-templates)
    - [The `template` Module](#the-template-module)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Deploy a dynamic `index.html` file to App Server 2 using an Ansible role and a Jinja2 template.

**Requirements:**
1.  **Target Host:** App Server 2 (`stapp02`).
2.  **Playbook:** Update `~/ansible/playbook.yml` to run the `httpd` role on the target host.
3.  **Template Location:** `~/ansible/role/httpd/templates/index.html.j2`.
4.  **Template Content:** `This file was created using Ansible on {{ inventory_hostname }}`.
5.  **Task Updates:** Add a task to `~/ansible/role/httpd/tasks/main.yml` to copy the template to `/var/www/html/index.html`.
6.  **File Attributes:** * Permissions: `0755`.
    * Owner/Group: The respective sudo user of the server (`steve` for `stapp02`, which can be dynamically referenced using `{{ ansible_user }}`).

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Update the Playbook
<a name="1-update-the-playbook"></a>
We first need to configure the main playbook to execute the existing `httpd` role specifically on App Server 2 (`stapp02`). Privilege escalation (`become: yes`) is necessary for web server configuration.

**Command:**
```bash
vi ~/ansible/playbook.yml
```

**Content:**
```yaml
---
- name: Deploy HTTPD Role
  hosts: stapp02
  become: yes
  roles:
    - role: httpd
```
*(Ensure that the role path matches your directory structure. Sometimes roles are located in a folder like `roles/httpd` or just `httpd`. Adjust the `- role: httpd` line accordingly if the path is explicitly `role/httpd`.)*

### 2. Create the Jinja2 Template
<a name="2-create-the-jinja2-template"></a>
Navigate to the templates directory inside the `httpd` role and create the Jinja2 (`.j2`) file. We utilize the `inventory_hostname` built-in variable to avoid hardcoding server names.

**Command:**
```bash
mkdir -p ~/ansible/role/httpd/templates/
vi ~/ansible/role/httpd/templates/index.html.j2
```

**Content:**
```jinja2
This file was created using Ansible on {{ inventory_hostname }}
```

### 3. Update the Role Tasks
<a name="3-update-the-role-tasks"></a>
Now, add the deployment logic to the role's main tasks file. The `template` module reads the `.j2` file, replaces the variables, and writes the output to the destination server.

**Command:**
```bash
vi ~/ansible/role/httpd/tasks/main.yml
```

**Content (Append to existing tasks):**
```yaml
# ... (existing tasks like installing httpd and starting the service) ...

- name: Deploy dynamic index.html using Jinja2 template
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
    owner: "{{ ansible_user }}"
    group: "{{ ansible_user }}"
    mode: '0755'
```
*Note: Using `{{ ansible_user }}` ensures the owner is dynamically set to the connection user (which is `steve` for `stapp02`), fulfilling the ownership requirement safely without hardcoding.*

### 4. Execute and Validate
<a name="4-execute-and-validate"></a>
Run the playbook from the directory containing the inventory file to ensure no extra arguments are needed.

**Command:**
```bash
cd ~/ansible
ansible-playbook -i inventory playbook.yml
```

**Expected Output:**
```text
PLAY [Deploy HTTPD Role] ************************************************************

TASK [Gathering Facts] **************************************************************
ok: [stapp02]

TASK [httpd : Install httpd] ********************************************************
ok: [stapp02]

TASK [httpd : Start httpd service] **************************************************
ok: [stapp02]

TASK [httpd : Deploy dynamic index.html using Jinja2 template] **********************
changed: [stapp02]

PLAY RECAP **************************************************************************
stapp02                    : ok=4    changed=1    unreachable=0    failed=0    skipped=0
```

**Manual Verification (Optional):**
You can confirm the file's content and permissions on the remote host using an ad-hoc command:
```bash
ansible stapp02 -i inventory -m command -a "cat /var/www/html/index.html" --become
# Output: This file was created using Ansible on stapp02

ansible stapp02 -i inventory -m command -a "ls -l /var/www/html/index.html" --become
# Output should show -rwxr-xr-x (0755) and ownership steve:steve
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### Jinja2 Templates
<a name="jinja2-templates"></a>
Jinja2 is a templating language for Python that Ansible leverages heavily. It allows you to create dynamic configuration files that adapt to the environment they are deployed in. When Ansible encounters `{{ variable_name }}`, it evaluates it against gathered facts and inventory data before pushing the file.

### The `template` Module
<a name="the-template-module"></a>
The `template` module is the engine that processes `.j2` files.
1.  It reads the `src` file from the control node (jump host).
2.  It parses all Jinja2 expressions (`{{ ... }}`, `{% ... %}`).
3.  It transfers the resulting rendered text to the `dest` path on the managed node.
4.  Unlike the `copy` module (which copies files exactly as they are), the `template` module is strictly meant for files requiring dynamic data injection.
  
