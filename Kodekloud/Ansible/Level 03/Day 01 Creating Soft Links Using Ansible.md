# Ansible Level 03 Day 01: Creating Soft Links Using Ansible

This document outlines the solution for Ansible Level 03 Day 01. The objective was to use the Ansible `file` module to create specific empty files with tailored ownership on different application servers, and to establish a symbolic (soft) link linking two directories.

## Table of Contents
- [Ansible Level 03 Day 01: Creating Soft Links Using Ansible](#ansible-level-03-day-01-creating-soft-links-using-ansible)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the Playbook](#1-create-the-playbook)
    - [2. Execute and Validate](#2-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [The `file` Module (State: touch)](#the-file-module-state-touch)
    - [The `file` Module (State: link)](#the-file-module-state-link)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Create specific files and soft links across the application servers.

* **Playbook Location:** `/home/thor/ansible/playbook.yml`
* **Inventory Location:** `/home/thor/ansible/inventory` (Already exists)
* **Requirements per Server:**
    * **App Server 1 (`stapp01`):** Create `/opt/security/blog.txt` (owner/group: `tony`). Symlink `/opt/security` -> `/var/www/html`.
    * **App Server 2 (`stapp02`):** Create `/opt/security/story.txt` (owner/group: `steve`). Symlink `/opt/security` -> `/var/www/html`.
    * **App Server 3 (`stapp03`):** Create `/opt/security/media.txt` (owner/group: `banner`). Symlink `/opt/security` -> `/var/www/html`.
* **Constraint:** Must run cleanly using `ansible-playbook -i inventory playbook.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Playbook
<a name="1-create-the-playbook"></a>
We will structure the playbook with three separate plays, each targeting a specific host. This makes the code highly readable and strictly enforces the distinct file and ownership requirements for each server. 

Writing to `/opt` and `/var/www/` requires root privileges, so we must include `become: yes`. The `force: yes` attribute on the link task ensures the symlink is created successfully even if the destination directory already exists or has conflicts.

**Command:**
```bash
cd /home/thor/ansible
vi playbook.yml
```

**Content:**
```yaml
---
- name: Configure App Server 1
  hosts: stapp01
  become: yes
  tasks:
    - name: Create empty file blog.txt
      file:
        path: /opt/security/blog.txt
        state: touch
        owner: tony
        group: tony

    - name: Create symbolic link
      file:
        src: /opt/security
        dest: /var/www/html
        state: link
        force: yes

- name: Configure App Server 2
  hosts: stapp02
  become: yes
  tasks:
    - name: Create empty file story.txt
      file:
        path: /opt/security/story.txt
        state: touch
        owner: steve
        group: steve

    - name: Create symbolic link
      file:
        src: /opt/security
        dest: /var/www/html
        state: link
        force: yes

- name: Configure App Server 3
  hosts: stapp03
  become: yes
  tasks:
    - name: Create empty file media.txt
      file:
        path: /opt/security/media.txt
        state: touch
        owner: banner
        group: banner

    - name: Create symbolic link
      file:
        src: /opt/security
        dest: /var/www/html
        state: link
        force: yes
```

### 2. Execute and Validate
<a name="2-execute-and-validate"></a>
Run the playbook using the required command.

**Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Expected Output:**
```text
PLAY [Configure App Server 1] *******************************************************
...
changed: [stapp01] (File Created)
changed: [stapp01] (Symlink Created)

PLAY [Configure App Server 2] *******************************************************
...
changed: [stapp02] (File Created)
changed: [stapp02] (Symlink Created)

PLAY [Configure App Server 3] *******************************************************
...
changed: [stapp03] (File Created)
changed: [stapp03] (Symlink Created)
```

**Manual Verification (Optional):**
You can verify the symlink creation on one of the servers using an ad-hoc command:
```bash
ansible stapp01 -i inventory -m command -a "ls -ld /var/www/html" --become
# Output should show: lrwxrwxrwx ... /var/www/html -> /opt/security
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `file` Module (State: touch)
<a name="the-file-module-state-touch"></a>
Just like the Linux `touch` command, setting `state: touch` in the Ansible `file` module will create an empty file if it does not exist. It also allows you to simultaneously set the `owner` and `group` attributes, ensuring the new file is immediately provisioned with the correct permissions.

### The `file` Module (State: link)
<a name="the-file-module-state-link"></a>
Symbolic links (soft links) are crucial for redirecting paths without duplicating data.
* **`state: link`**: Tells Ansible to create a symlink.
* **`src`**: The absolute path of the directory/file you want to link *to* (the actual data location, e.g., `/opt/security`).
* **`dest`**: The path where the shortcut will be placed (e.g., `/var/www/html`).
* **`force: yes`**: (Optional but recommended in this scenario) If `/var/www/html` already exists as a regular directory or file, standard symlink creation will fail. `force: yes` tells Ansible to overwrite it with the requested symlink.
  
